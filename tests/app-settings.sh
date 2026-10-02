#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import os, pathlib, subprocess, sys, tempfile
repo=pathlib.Path(sys.argv[1])
with tempfile.TemporaryDirectory() as d:
    root=pathlib.Path(d); apps=root/'Applications'; apps.mkdir(); tools=root/'bin'; tools.mkdir()
    log=root/'calls'
    for name in ('osascript','defaults','killall'):
        p=tools/name
        p.write_text('#!/bin/bash\nprintf "%s\\n" "$0 $*" >> "$TEST_CALLS"\ncat >/dev/null\n')
        p.chmod(0o755)
    env=dict(os.environ, HOME=d, PATH=str(tools)+':/usr/bin:/bin', TEST_CALLS=str(log), DOTFILES_APPLICATIONS_DIR=str(apps))
    def run(name,*args):
        return subprocess.run([str(repo/'bin'/name),*args],env=env,input='',text=True,capture_output=True)
    assert run('configure-app-settings','--dry-run').returncode==0
    assert not log.exists()
    preview=run('configure-app-settings','--dry-run')
    assert 'Full Disk Access' not in preview.stdout and 'Microphone' not in preview.stdout
    assert 'Would ensure login item:' in preview.stdout
    result=run('configure-app-settings')
    assert result.returncode==1 and 'app missing' in result.stdout and not log.exists()
    for app in (repo/'apps/login-items.txt').read_text().splitlines(): (apps/(app+'.app')).mkdir()
    assert run('configure-app-settings').returncode==0
    assert len(log.read_text().splitlines())==14
    log.unlink()
    assert run('configure-screenshots','--dry-run').returncode==0 and not log.exists()
print('App settings fixtures passed')
PY
