#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-runtime-test.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home" DOTFILES_SETUP_RUN_ROOT="$fixture/runs" DOTFILES_RUNTIME_LOCK_ROOT="$fixture/locks"
mkdir -p "$HOME"
# Model missing managed runtimes. Setup must use the system Ruby directly.
mkdir -p "$fixture/bin"
for tool in perl ruby; do
  printf '#!/bin/bash\nexit 127\n' > "$fixture/bin/$tool"
  chmod +x "$fixture/bin/$tool"
done
export PATH="$fixture/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export RUNTIME_SOURCE="$repo_root/bin/lib/setup-runtime.sh"
cat > "$fixture/exercise" <<'SCRIPT'
#!/bin/bash
set -eu
source "$RUNTIME_SOURCE"
runtime_init fixture "${1:-normal}"
runtime_acquire_global_lock
runtime_stage_begin foundations setup preflight
if [[ "${1:-normal}" == dry-run ]]; then
  runtime_stage_begin installation foundations preflight
  runtime_stage_end installation planned 0
  runtime_event probe preflight setup completed 0 'fixture-only probe'
else
  for number in 1 2 3 4; do
    runtime_run_job "worker-$number" recoverable retry bash -c 'printf "hello ghp_SYNTHETICcredential123 token=synthetic-password\n{\"token\":\"synthetic-json\"}\n"'
  done
  runtime_wait_jobs
  runtime_execute_stage failing foundations preflight capture bash -c 'exit 7' && exit 99
fi
runtime_print_summary
SCRIPT
chmod +x "$fixture/exercise"
/bin/bash "$fixture/exercise" normal > "$fixture/normal.stdout"
/bin/bash "$fixture/exercise" dry-run > "$fixture/dry.stdout"
grep -q '\[worker-1\] hello \[REDACTED\]' "$fixture/normal.stdout"
grep -q 'worker-1: completed' "$fixture/normal.stdout"
grep -q 'failing: failed' "$fixture/normal.stdout"
! grep -Eq 'SYNTHETICcredential|synthetic-password|synthetic-json' "$fixture/normal.stdout"
python3 - "$fixture/runs" <<'PY'
import glob,json,os,stat,sys
runs=glob.glob(sys.argv[1]+'/*'); assert len(runs)==2
for run in runs:
    assert stat.S_IMODE(os.stat(run).st_mode)==0o700
    data=[json.loads(x) for x in open(run+'/events.jsonl')]
    assert data and any(e['event']=='run_start' for e in data)
    for path in glob.glob(run+'/**/*',recursive=True):
        if os.path.isfile(path):
            assert stat.S_IMODE(os.stat(path).st_mode)&0o077==0, path
            contents=open(path).read()
            assert 'SYNTHETICcredential' not in contents and 'synthetic-password' not in contents and 'synthetic-json' not in contents,path
    if data[0]['mode']=='normal':
        failures=[e for e in data if e['outcome']=='failed']; assert failures
        assert any('setup-runtime.sh:' in e['stack'] for e in failures)
        assert any(e['parent_stage_id']=='foundations' and e['prerequisites']=='preflight' for e in data)
        workers=[e for e in data if e['event']=='result' and e['detail'].startswith('worker-')]
        assert len(workers)==4
        assert all(e['stage_id'].startswith(e['detail'].split(':')[0]) for e in workers)
    else:
        assert any(e['outcome']=='planned' for e in data)
        assert any(e['event']=='probe' for e in data)
        assert not any(e['stack'] for e in data)
print('PASS normal/dry traces, concurrent events, redaction, permissions, failure stacks')
PY
# Output must be visible before the producer finishes, including serial mode.
cat > "$fixture/live" <<'SCRIPT'
#!/bin/bash
set -eu
source "$RUNTIME_SOURCE"
runtime_init live
runtime_run_job progress recoverable retry bash -c 'echo "download token=synthetic-live"; while [[ ! -f "$HOME/release" ]]; do sleep 0.1; done; echo finished'
runtime_wait_jobs
SCRIPT
python3 - "$fixture/live" "$fixture" <<'PYTEST'
import os,subprocess,sys,time
script,root=sys.argv[1:]
for serial in ('0','1'):
    release=os.environ['HOME']+'/release'
    if os.path.exists(release): os.unlink(release)
    path=root+'/live-'+serial+'.stdout'
    with open(path,'w') as out:
        process=subprocess.Popen(['/bin/bash',script],stdout=out,stderr=subprocess.STDOUT,
                                 env=dict(os.environ,DOTFILES_SETUP_SERIAL=serial))
        try:
            until=time.time()+10
            while '[progress] download token=[REDACTED]' not in open(path).read() and time.time()<until:
                time.sleep(.05)
            assert '[progress] download token=[REDACTED]' in open(path).read(), 'output buffered until completion'
            assert process.poll() is None, 'producer exited before release'
            assert 'synthetic-live' not in open(path).read()
        finally:
            open(release,'w').close()
            process.wait(timeout=15)
        assert process.returncode==0
        assert '[progress] finished' in open(path).read()
print('PASS live sanitized progress before producer exit in parallel and serial modes')
PYTEST
# A fresh subprocess, rather than an asynchronously launched shell, must receive
# SIGINT: POSIX asynchronous shells inherit SIGINT ignored from their parent.
cat > "$fixture/cancel" <<'SCRIPT'
#!/bin/bash
set -eu
source "$RUNTIME_SOURCE"
runtime_init cancel
runtime_acquire_global_lock
if [[ "$1" == sensitive ]]; then
  runtime_execute_stage auth github mise sensitive bash -c 'printf "partial output\n"; trap "" TERM; sleep 300 & echo "$!" > "$HOME/grandchild"; wait'
else
runtime_run_job tree recoverable retry bash -c 'printf "partial output\n"; trap "" TERM; sleep 300 & echo "$!" > "$HOME/grandchild"; wait'
runtime_wait_jobs
fi
SCRIPT
python3 - "$fixture/cancel" "$fixture" <<'PY'
import os,signal,subprocess,sys,time,glob,json
script,root=sys.argv[1:]
for sig,mode in ((signal.SIGINT,'background'),(signal.SIGTERM,'background'),(signal.SIGINT,'sensitive'),(signal.SIGTERM,'sensitive')):
    grandchild=os.environ['HOME']+'/grandchild'
    if os.path.exists(grandchild): os.unlink(grandchild)
    unrelated=subprocess.Popen(['sleep','300'])
    out=open(root+'/cancel-'+str(sig)+'.stdout','w')
    process=subprocess.Popen(['/bin/bash',script,mode],stdout=out,stderr=subprocess.STDOUT,start_new_session=True)
    try:
        until=time.time()+10
        while not os.path.exists(grandchild) and time.time()<until: time.sleep(.05)
        assert os.path.exists(grandchild),'grandchild did not start'
        descendant=int(open(grandchild).read())
        process.send_signal(sig)
        assert process.wait(timeout=15)==128+sig
        assert unrelated.poll() is None,'unrelated process terminated'
        until=time.time()+5
        alive=True
        while time.time()<until:
            try: os.kill(descendant,0)
            except ProcessLookupError: alive=False; break
            time.sleep(.05)
        assert not alive,'grandchild survived cancellation'
        assert not glob.glob(os.environ['DOTFILES_RUNTIME_LOCK_ROOT']+'/*.lock'),'stale lock'
        run=max(glob.glob(os.environ['DOTFILES_SETUP_RUN_ROOT']+'/*'),key=os.path.getmtime)
        events=[json.loads(x) for x in open(run+'/events.jsonl')]
        assert any(e['event']=='cancellation' and e['exit_status']==128+sig for e in events)
        assert os.path.exists(run+'/summary.txt')
        output=''.join(open(p).read() for p in glob.glob(run+'/*.log'))
        assert ('partial output' in output) == (mode=='background'), (mode,output)
    finally:
        try: os.killpg(process.pid,signal.SIGKILL)
        except ProcessLookupError: pass
        if process.poll() is None: process.wait()
        unrelated.terminate();unrelated.wait();out.close()
print('PASS SIGINT/SIGTERM descendant cleanup, unrelated process survival, locks, persistent logs')
PY
