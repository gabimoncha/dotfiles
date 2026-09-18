#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import json, os, pathlib, shutil, subprocess, sys, tempfile
repo=pathlib.Path(sys.argv[1])
logs=repo/'.local/setup-runs'/('acceptance-'+__import__('datetime').datetime.now().strftime('%Y%m%dT%H%M%S'))
logs.mkdir(parents=True, mode=0o700)
with tempfile.TemporaryDirectory(prefix='dotfiles-plan-') as directory:
    root=pathlib.Path(directory); fixture=root/'repo'; fixture.mkdir()
    shutil.copytree(repo/'bin',fixture/'bin')
    actions=['app_settings','screenshots','permission_handoff','verify_apps','sudo','keepalive','touch_id','preflight','clt','homebrew','mise','install_gh','api','ssh','verify_auth','links','final_links','brew_environment','brewfiles','brew_inventory','mise_inventory','manifest_apps','app_store','editor_extensions','submodules','capabilities','shell','standalone_agents','mobile_tools','xcode','mobile_finish','skills_runtime','skills','defaults','finder','restores']
    text='''#!/usr/bin/env bash
fixture_action() {
  printf '%s start\\n' "$1" >> "$FIXTURE_EVENTS"
  case "$1" in homebrew|mise) sleep 0.5 ;; esac
  if [[ "${FIXTURE_DEFER:-}" == "$1" ]]; then return 20; fi
  if [[ "${FIXTURE_FAIL:-}" == "$1" ]]; then
    printf 'token=synthetic-private-value ghp_syntheticprivatevalue\\n'
    printf '%s failed\\n' "$1" >> "$FIXTURE_EVENTS"
    return 7
  fi
  printf '%s end\\n' "$1" >> "$FIXTURE_EVENTS"
}
'''
    text+='\n'.join('setup_'+name+'() { fixture_action '+name+'; }' for name in actions)+'\n'
    (fixture/'bin/lib/setup-actions.sh').write_text(text)
    def run(label,fail='',dry=False,serial=False,skip=False,defer='',prepare=False):
        home=root/label;home.mkdir(); events=home/'actions'
        env={'HOME':str(home),'PATH':'/usr/bin:/bin:/usr/sbin:/sbin','TMPDIR':str(home),
             'FIXTURE_EVENTS':str(events),'FIXTURE_FAIL':fail,'FIXTURE_DEFER':defer,'DOTFILES_SETUP_RUN_ROOT':str(logs/label),
             'DOTFILES_RUNTIME_LOCK_ROOT':str(home/'locks')}
        command=[str(fixture/'bin/setup')]+([] if prepare else ['--continue'])+(['--dry-run'] if dry else [])+(['--serial'] if serial else [])+(['--skip-mobile-dev'] if skip else [])
        result=subprocess.run(command,cwd=fixture,env=env,text=True,capture_output=True,timeout=90)
        (logs/(label+'.console.txt')).write_text(result.stdout+result.stderr)
        runs=list((logs/label).iterdir());assert len(runs)==1,(label,result.stderr)
        run=runs[0]
        records=[json.loads(line) for line in (run/'events.jsonl').read_text().splitlines()]
        all_logs=''.join(p.read_text() for p in run.rglob('*') if p.is_file())
        assert 'synthetic-private-value' not in all_logs and 'ghp_syntheticprivatevalue' not in all_logs
        assert (run/'summary.txt').stat().st_mode & 0o077 == 0
        executed=events.read_text().splitlines() if events.exists() else []
        return result,records,executed
    result,records,events=run('prepare',prepare=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    assert events.index('homebrew start') < events.index('mise end')
    assert events.index('mise start') < events.index('homebrew end')
    assert events.index('homebrew end') < events.index('standalone_agents start')
    assert events.index('standalone_agents end') < events.index('permission_handoff start')
    assert not any(name+' start' in events for name in ('links','api','ssh','brew_inventory','mise_inventory','xcode','restores','defaults'))
    assert 'permission_handoff end' in events
    result,records,events=run('prepare-failed',fail='mise',prepare=True)
    assert result.returncode!=0
    assert 'permission_handoff start' not in events and 'brew_inventory start' not in events
    assert 'homebrew end' in events
    result,records,events=run('prepare-dry',dry=True,prepare=True)
    assert result.returncode==0
    assert events==['preflight start','preflight end'],events
    assert any(r['stage_id']=='permission_handoff' and r['outcome']=='planned' for r in records)
    assert not any(r['stage_id']=='homebrew_inventory' for r in records)
    result,records,events=run('normal')
    assert result.returncode==0,(result.stdout,result.stderr)
    assert events.index('homebrew start') < events.index('mise end')
    assert events.index('mise start') < events.index('homebrew end')
    assert events.index('api end') < events.index('mise_inventory start')
    assert events.index('homebrew end') < events.index('mise_inventory start')
    assert events.index('xcode end') < events.index('mobile_finish start')
    assert events.index('brew_inventory end') < events.index('xcode start')
    assert events.index('mise_inventory end') < events.index('xcode start')
    final_links_start=events.index('final_links start')
    assert events.index('mise_inventory end') < final_links_start
    assert events.index('standalone_agents end') < final_links_start
    starts={r['stage_id'] for r in records if r['event'] in ('stage_start','run_start')}
    for r in records:
        assert not r['parent_stage_id'] or r['parent_stage_id'] in starts,r
    assert any(r['stage_id']=='mise_inventory' and 'verify_mise_access' in r['prerequisites'] for r in records)
    for failure in ['homebrew','mise','api','ssh','mise_inventory']:
        result,records,events=run('failed-'+failure,failure)
        assert result.returncode!=0,(failure,result.stdout,result.stderr)
        if failure in ('mise','api'):
            assert 'mise_inventory start' not in events and 'brew_inventory end' in events
        if failure=='homebrew':
            assert 'api end' in events and 'mise_inventory start' not in events
        if failure=='ssh': assert 'mise_inventory end' in events
        if failure=='mise_inventory': assert 'capabilities end' in events and 'restores end' in events
        assert any(r['outcome']=='failed' and r['stack'] for r in records)
    result,records,events=run('required-deferred',defer='skills')
    assert result.returncode!=0
    assert any(r['stage_id']=='skills' and r['outcome']=='deferred' for r in records)
    result,records,events=run('dry-run',dry=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    assert events==['preflight start','preflight end'],events
    assert any(r['outcome']=='planned' and r['stage_id']=='homebrew' for r in records)
    assert all(not r['stack'] for r in records if r['outcome']=='planned')
    result,records,events=run('serial',serial=True,skip=True)
    assert result.returncode==0,(result.stdout,result.stderr)
    assert events.index('homebrew end')<events.index('mise start')
    assert 'xcode start' not in events and 'mobile_tools start' not in events
    print('PASS: shared planner normal/dry/serial, overlap, failure dependencies, SSH independence, partial recovery, sanitized traces')
    print('Diagnostic fixtures:',logs)
PY
