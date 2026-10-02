#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import os, pathlib, shutil, signal, subprocess, sys, tempfile, time
repo=pathlib.Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix='dotfiles-harness-install-') as d:
    root=pathlib.Path(d); fixture=root/'repo'; tools=root/'tools'; home=root/'home'; vendors=root/'vendors'
    for path in (fixture/'bin/lib',tools,home,vendors): path.mkdir(parents=True)
    for name in ('ensure-harnesses-standalone',): shutil.copy(repo/'bin'/name,fixture/'bin'/name)
    for name in ('setup-runtime.sh','harnesses.sh'): shutil.copy(repo/'bin/lib'/name,fixture/'bin/lib'/name)
    def script(path,text):
        path.parent.mkdir(parents=True,exist_ok=True); path.write_text('#!/bin/bash\n'+text); path.chmod(0o755)
    for name in ('codex','cursor-agent'):
        script(fixture/'bin'/('ensure-'+name+'-standalone'),'printf "foundation %s\\n" "$*" >> "$CALLS"\n')
    calls=root/'calls'
    env=dict(HOME=str(home),PATH=str(tools)+':/usr/bin:/bin:/usr/sbin:/sbin',CALLS=str(calls),VENDORS=str(vendors),
             DOTFILES_SETUP_RUN_ROOT=str(root/'runs'),DOTFILES_RUNTIME_LOCK_ROOT=str(root/'locks'))
    script(tools/'node','exit 0\n'); script(tools/'npm','exit 0\n')
    script(tools/'mise','printf "FORBIDDEN mise %s\\n" "$*" >> "$CALLS"\nexit 99\n')
    script(tools/'curl','''
while [[ $# -gt 0 ]]; do
  case "$1" in https://*) url="$1";; -o) shift; destination="$1";; esac
  shift
done
case "$url" in
  *claude.ai*) name=claude;; *pi.dev*) name=pi;; *t3.codes*) name=t3;; *opencode.ai/v2/install) name=opencode;; *) exit 99;;
esac
printf 'download %s\\n' "$url" >> "$CALLS"
[[ "$name" != "${FAIL_DOWNLOAD:-}" ]] || exit 22
cp "$VENDORS/$name" "$destination"
''')
    script(tools/'brew','printf "FORBIDDEN brew %s\\n" "$*" >> "$CALLS"\nexit 99\n')
    install_common='''
[[ "$name" != "${FAIL_INSTALL:-}" ]] || exit 7
if [[ "$name" == "${BLOCK_INSTALL:-}" ]]; then
  sleep 60 &
  echo "$!" > "$HOME/install-child.pid"
  wait
fi
mkdir -p "$(dirname "$target")"
cat > "$target" <<'BINARY'
#!/bin/bash
if [[ "$*" == --version ]]; then echo 1.0.0-nightly.20261002.1; exit 0; fi
exit 99
BINARY
chmod +x "$target"
if [[ -n "${link:-}" ]]; then mkdir -p "$(dirname "$link")"; ln -sfn "$target" "$link"; fi
printf 'install %s\\n' "$name" >> "$CALLS"
'''
    script(vendors/'claude','name=claude; target="$HOME/.local/share/claude/versions/1/claude"; link="$HOME/.local/bin/claude"\n'+install_common)
    script(vendors/'t3','''
[[ "${T3CODE_CHANNEL:-}" == nightly && -z "${T3CODE_VERSION:-}" ]] || exit 99
name=t3; target="$HOME/.t3/runtime/versions/1/t3"; link="$HOME/.local/bin/t3"
'''+install_common)
    script(vendors/'opencode','''
[[ "$*" == --no-modify-path ]] || exit 99
name=opencode; target="$HOME/.opencode/bin/opencode"
'''+install_common)
    script(vendors/'pi','''
# A vendor installer must not have a controlling terminal.
! command -v pi >/dev/null 2>&1 || exit 99
if ( : <>/dev/tty ) 2>/dev/null; then exit 99; fi
[[ "${PI_LEGACY_INSTALL:-}" == 0 ]] || exit 99
name=pi; target="$HOME/.pi/agent/bin/pi"
'''+install_common+'''
mkdir -p "$HOME/.pi/agent/install"
printf '{}' > "$HOME/.pi/agent/install/managed-install.json"
''')
    def run(*args,extra=None):
        return subprocess.run([str(fixture/'bin/ensure-harnesses-standalone'),*args],env=dict(env,**(extra or {})),capture_output=True,text=True,timeout=30)
    result=run('--dry-run'); assert result.returncode==0,(result.stdout,result.stderr)
    assert 'T3CODE_CHANNEL=nightly' in result.stdout and 'https://opencode.ai/v2/install' in result.stdout
    assert not any(x.startswith(('download','install','mise','brew')) for x in calls.read_text().splitlines())
    calls.unlink()
    # A conflicting visible command is backed up before a verified replacement.
    old=home/'.local/bin/claude'; script(old,'echo old-command\n')
    settings=home/'.claude/settings.json'; settings.parent.mkdir(); settings.write_text('{"keep":true}')
    result=run(extra={'T3CODE_CHANNEL':'stable','T3CODE_VERSION':'1.0.0'}); assert result.returncode==0,(result.stdout,result.stderr)
    lines=calls.read_text().splitlines()
    assert all('install '+x in lines for x in ('claude','pi','t3','opencode')),lines
    assert list((home/'.dotfiles-backups').rglob('claude'))
    assert settings.read_text()=='{"keep":true}'
    calls.unlink()
    result=run(); assert result.returncode==0,(result.stdout,result.stderr)
    assert calls.exists(),(result.stdout,result.stderr)
    assert not any(x.startswith(('download','install')) for x in calls.read_text().splitlines())
    assert 'FORBIDDEN' not in calls.read_text(),calls.read_text()
    # Download failure must preserve the previous command, with no execution.
    assert not (home/'.opencode/.dotfiles-v2-installer').exists()
    # An unhealthy executable needs repair; no migration receipt is required.
    script(home/'.opencode/bin/opencode','exit 1\n')
    old_opencode=(home/'.opencode/bin/opencode').read_text(); calls.unlink()
    result=run(extra={'FAIL_DOWNLOAD':'opencode'}); assert result.returncode!=0
    assert (home/'.opencode/bin/opencode').read_text()==old_opencode
    assert 'install opencode' not in calls.read_text()
    # Installer failure restores the replaced launcher and releases locks.
    calls.unlink()
    result=run(extra={'FAIL_INSTALL':'opencode'}); assert result.returncode!=0
    assert (home/'.opencode/bin/opencode').read_text()==old_opencode
    assert not list((root/'locks').glob('*.lock'))
    # Interrupted replacement must restore the command and stop its children.
    process=subprocess.Popen([str(fixture/'bin/ensure-harnesses-standalone')],env=dict(env,BLOCK_INSTALL='opencode'),stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True)
    deadline=time.monotonic()+20
    while not (home/'install-child.pid').exists() and time.monotonic()<deadline: time.sleep(0.05)
    assert (home/'install-child.pid').exists()
    process.send_signal(signal.SIGTERM)
    _,errors=process.communicate(timeout=15)
    assert process.returncode==143,(process.returncode,errors)
    assert (home/'.opencode/bin/opencode').read_text()==old_opencode
    assert not list((root/'locks').glob('*.lock'))
    child=int((home/'install-child.pid').read_text())
    state=subprocess.run(['/bin/ps','-p',str(child),'-o','stat='],capture_output=True,text=True).stdout.strip()
    assert not state or state.startswith('Z'),state
    # Hung version probes must stop their child process and return a timeout.
    script(home/'hang', 'sleep 60 &\necho "$!" > "$HOME/probe-child.pid"\nwait\n')
    result=subprocess.run(['/bin/bash','-c','. "$SOURCE"; harness_probe "$HOME/hang"'],env=dict(env,SOURCE=str(fixture/'bin/lib/harnesses.sh'),DOTFILES_TOOL_CHECK_TIMEOUT_SECONDS='1'),capture_output=True,text=True,timeout=5)
    assert result.returncode==124,(result.returncode,result.stderr)
    child=int((home/'probe-child.pid').read_text())
    state=subprocess.run(['/bin/ps','-p',str(child),'-o','stat='],capture_output=True,text=True).stdout.strip()
    assert not state or state.startswith('Z'),state
    # A fresh foundation phase excludes Pi, which needs the later Node inventory.
    fresh=root/'fresh'; fresh.mkdir(); calls.unlink()
    result=run('--foundation-only',extra={'HOME':str(fresh)}); assert result.returncode==0,(result.stdout,result.stderr)
    assert 'install pi' not in calls.read_text()
    # Healthy Codex installs do not run migration diagnostics or package cleanup.
    shutil.copy(repo/'bin/ensure-codex-standalone',fixture/'bin/ensure-codex-standalone')
    codex=fresh/'.codex/packages/standalone/current/bin/codex'
    script(codex,'''
if [[ "$*" == --version ]]; then echo codex-cli 1.0.0; exit 0; fi
printf 'FORBIDDEN codex %s\\n' "$*" >> "$CALLS"
exit 99
''')
    visible=fresh/'.local/bin/codex'; visible.parent.mkdir(parents=True,exist_ok=True); visible.symlink_to(codex)
    calls.unlink()
    result=subprocess.run([str(fixture/'bin/ensure-codex-standalone')],env=dict(env,HOME=str(fresh),CODEX_HOME=str(fresh/'.codex'),CODEX_INSTALL_DIR=str(visible.parent)),capture_output=True,text=True,timeout=15)
    assert result.returncode==0,(result.stdout,result.stderr)
    assert not calls.exists(),calls.read_text() if calls.exists() else ''
print('PASS: vendor URLs, nightly enforcement, Pi Node/TTY isolation, OpenCode v2, idempotence without package-manager cleanup, backups, download/installer failure and cancellation recovery, foundation boundary')
PY
