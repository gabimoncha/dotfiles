#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import json, os, pathlib, shutil, signal, subprocess, sys, tempfile, time
repo=pathlib.Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix='dotfiles-harness-test-') as d:
    root=pathlib.Path(d); home=root/'home'; tools=root/'tools'; tools.mkdir(); home.mkdir()
    calls=root/'calls'; locks=root/'locks'; runs=root/'runs'
    env=dict(HOME=str(home), PATH=str(tools)+':/usr/bin:/bin:/usr/sbin:/sbin',
             CALLS=str(calls), DOTFILES_SETUP_RUN_ROOT=str(runs), DOTFILES_RUNTIME_LOCK_ROOT=str(locks))
    def script(path, text):
        path.parent.mkdir(parents=True,exist_ok=True); path.write_text('#!/bin/bash\n'+text); path.chmod(0o755)
    vendor='''name="${0##*/}"
if [[ "$*" == --version ]]; then echo 1.0.0-nightly.20261002.1; exit 0; fi
printf '%s start %s\\n' "$name" "$*" >> "$CALLS"
if [[ "${CANCEL:-0}" == 1 ]]; then
  sleep 60 &
  echo "$!" > "$HOME/$name.pid"
  wait
else
  if [[ "${BARRIER:-0}" == 1 ]]; then
    until [[ "$(grep -Ec "^(codex|claude|pi|t3|opencode|agent) start" "$CALLS")" == 6 ]]; do sleep 0.05; done
  fi
  sleep 0.3
fi
printf '%s end\\n' "$name" >> "$CALLS"
[[ "$name" != "${FAIL:-}" ]]
'''
    paths={'codex':home/'.codex/packages/standalone/current/bin/codex',
           'claude':home/'.local/share/claude/versions/1/claude',
           'pi':home/'.pi/agent/bin/pi','t3':home/'.t3/runtime/versions/1/t3',
           'opencode':home/'.opencode/bin/opencode','agent':home/'.local/share/cursor-agent/versions/1/agent'}
    for name,path in paths.items():
        script(path,vendor)
        if name not in ('pi','opencode'):
            link=home/'.local/bin'/name; link.parent.mkdir(parents=True,exist_ok=True); link.symlink_to(path)
    (home/'.pi/agent/install').mkdir(); (home/'.pi/agent/install/managed-install.json').write_text('{}')
    script(tools/'brew','''
if [[ "$1" == list ]]; then
  case "$3" in t3-code@nightly) exit 0;; *) exit 99;; esac
fi
if [[ "$1" == info ]]; then
  [[ "$*" == "info --json=v2 --cask "* ]] || exit 99
  token="$4"
  [[ "$token" != "${FAIL_CASK_INFO:-}" ]] || exit 7
  disabled=false
  [[ "$token" != "${DISABLED_CASK:-}" ]] || disabled=true
  [[ "$token" != "${BAD_CASK_METADATA:-}" ]] || token=unexpected-cask
  printf '{"casks":[{"full_token":"%s","disabled":%s,"disable_reason":"fails_gatekeeper_check"}]}\\n' "$token" "$disabled"
  exit 0
fi
printf 'brew start %s\\n' "$*" >> "$CALLS"
sleep 0.3
printf 'brew end %s\\n' "$*" >> "$CALLS"
''')
    def run(*args, extra=None):
        return subprocess.run([str(repo/'bin/harness'),*args],env=dict(env,**(extra or {})),text=True,capture_output=True,timeout=45)
    result=run('update',extra={'BARRIER':'1'}); assert result.returncode==0,(result.stdout,result.stderr)
    lines=calls.read_text().splitlines()
    expected=['codex start update','claude start upgrade','pi start update --all',
              't3 start update --channel nightly','opencode start upgrade','agent start update',
              'brew start upgrade --cask t3-code@nightly']
    assert all(x in lines for x in expected),lines
    # Prove overlap from events, not timing thresholds.
    assert max(lines.index(x) for x in expected[:6]) < min(i for i,x in enumerate(lines) if x.endswith(' end'))
    brew=[x for x in lines if x.startswith('brew ')]
    assert [x.split()[1] for x in brew]==['start','end'],brew
    assert not list(locks.glob('*.lock'))
    calls.unlink()
    result=run('update',extra={'FAIL':'claude'}); assert result.returncode!=0
    assert 'claude: failed' in result.stdout and 'opencode: completed' in result.stdout
    assert all(x in calls.read_text() for x in expected)
    # A disabled cask must fail even though Homebrew upgrade would exit zero.
    # Failed metadata or a name collision must also stop that cask update.
    for flag in ('DISABLED_CASK','FAIL_CASK_INFO','BAD_CASK_METADATA'):
        calls.unlink()
        result=run('update',extra={flag:'t3-code@nightly'})
        assert result.returncode!=0,(flag,result.stdout,result.stderr)
        assert 't3-desktop: failed' in result.stdout and 'opencode: completed' in result.stdout
        assert expected[6] not in calls.read_text()
    calls.unlink()
    assert run('update','--dry-run').returncode==0 and not calls.exists()
    paths['pi'].unlink()
    result=run('update','--installed-only'); assert result.returncode==0 and 'Skipping pi' in result.stdout
    result=run('update'); assert result.returncode!=0 and 'managed installation is not present' in result.stdout
    script(paths['pi'],vendor)
    # A legacy mise command must never receive a vendor update.
    legacy=home/'.local/share/mise/installs/claude/1/claude'
    script(legacy,'printf "FORBIDDEN\\n" >> "$CALLS"\n')
    link=home/'.local/bin/claude'; link.unlink(); link.symlink_to(legacy)
    calls.unlink()
    result=run('update','--installed-only'); assert result.returncode==0 and 'Skipping claude' in result.stdout
    assert 'FORBIDDEN' not in calls.read_text()
    link.unlink(); link.symlink_to(paths['claude'])
    # Run cancellation with real process inspection; all descendants must stop.
    process=subprocess.Popen([str(repo/'bin/harness'),'update'],env=dict(env,CANCEL='1'),stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True)
    deadline=time.monotonic()+20
    while len(list(home.glob('*.pid')))<6 and time.monotonic()<deadline: time.sleep(0.05)
    assert len(list(home.glob('*.pid')))==6
    process.send_signal(signal.SIGTERM)
    _,errors=process.communicate(timeout=15)
    assert process.returncode==143,(process.returncode,errors)
    for path in home.glob('*.pid'):
        pid=int(path.read_text())
        state=subprocess.run(['/bin/ps','-p',str(pid),'-o','stat='],capture_output=True,text=True).stdout.strip()
        assert not state or state.startswith('Z'),(pid,state)
    assert not list(locks.glob('*.lock'))
    # Check native hook and shell helper with fake mise and harness commands.
    import tomllib
    config=tomllib.loads((repo/'home/.config/mise/config.toml').read_text())
    assert not {'claude','pi','opencode'} & config['tools'].keys()
    hook=config['hooks']['postinstall']
    script(home/'bin/harness','printf "harness %s\\n" "$*" >> "$CALLS"\nexit "${HARNESS_FAIL:-0}"\n')
    script(tools/'mise','''printf 'mise %s\\n' "$*" >> "$CALLS"
[[ "${MISE_FAIL:-0}" == 0 ]] || exit "$MISE_FAIL"
[[ "${DOTFILES_HARNESS_SKIP_HOOK:-0}" == 1 ]] || /bin/sh -c "$HOOK"
''')
    hook_env=dict(env,HOOK=hook)
    calls.unlink()
    subprocess.run(['/bin/sh','-c',hook],env=hook_env,check=True)
    assert calls.read_text().splitlines()==['harness update --installed-only']
    shell='source "$HARNESS_SOURCE"; mise "$@"'
    for args in [('install',),('up',),('up','--local'),('install','node@24')]:
        calls.unlink()
        result=subprocess.run(['/bin/zsh','-dfc',shell,'--',*args],env=dict(hook_env,HARNESS_SOURCE=str(repo/'home/.config/zsh/harness.zsh')),capture_output=True,text=True)
        assert result.returncode==0,result.stderr
        assert calls.read_text().splitlines()==['mise '+' '.join(args),'harness update --installed-only']
    for args in [('up','--dry-run'),('up','-n'),('install','--help'),('--version',)]:
        calls.unlink()
        result=subprocess.run(['/bin/zsh','-dfc',shell,'--',*args],env=dict(hook_env,DOTFILES_HARNESS_SKIP_HOOK='1',HARNESS_SOURCE=str(repo/'home/.config/zsh/harness.zsh')),capture_output=True,text=True)
        assert result.returncode==0
        assert calls.read_text().splitlines()==['mise '+' '.join(args)]
    for failure,code in [('MISE_FAIL','7'),('HARNESS_FAIL','9')]:
        result=subprocess.run(['/bin/zsh','-dfc',shell,'--','up'],env=dict(hook_env,**{failure:code},HARNESS_SOURCE=str(repo/'home/.config/zsh/harness.zsh')),capture_output=True,text=True)
        assert result.returncode==int(code)
print('PASS: parallel harness updates, Homebrew cask update, disabled cask and metadata failures, failure aggregation, missing installs, dry run, cancellation, mise hook and no-op shell commands')
PY
