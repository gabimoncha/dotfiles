#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import json, os, pathlib, subprocess, sys, tempfile
repo=pathlib.Path(sys.argv[1])
with tempfile.TemporaryDirectory() as d:
    root=pathlib.Path(d); tools=root/'bin'; tools.mkdir()
    prefs=root/'prefs.json'; calls=root/'calls'
    fake=tools/'defaults'
    fake.write_text('#!'+sys.executable+'''\nimport json,os,sys
p=os.environ['TEST_PREFS']; a=sys.argv[1:]; data=json.load(open(p))
if a[0]=='read':
    if a[2] not in data: sys.exit(1)
    print(data[a[2]])
else:
    open(os.environ['TEST_CALLS'],'a').write(a[2]+'\\n')
    if os.environ.get('DROP_WRITES')!='1': data[a[2]]=a[4]
    json.dump(data,open(p,'w'))
'''); fake.chmod(0o755)
    killer=tools/'killall';killer.write_text('#!/bin/sh\necho refresh >> "$TEST_CALLS"\n');killer.chmod(0o755)
    env=dict(os.environ,HOME=d,PATH=str(tools)+':/usr/bin:/bin',TEST_PREFS=str(prefs),TEST_CALLS=str(calls))
    def run(*args):
        return subprocess.run([str(repo/'bin/configure-screenshots'),*args],env=env,text=True,capture_output=True)
    prefs.write_text(json.dumps({'location':d+'/Screenshots','location-screenrecording':d+'/Videos'}))
    assert run('--dry-run').returncode==0 and not calls.exists() and not (root/'Screenshots').exists()
    assert run().returncode==0
    data=json.loads(prefs.read_text())
    assert data['location-screenshot']==d+'/Screenshots'
    assert data['target']==data['target-screenshot']=='file'
    assert data['location-screenrecording']==d+'/Videos'
    previous=calls.read_text()
    assert run().returncode==0 and calls.read_text()==previous
    for key in ('location','location-screenshot','location-last'): data[key]='~/Screenshots'
    prefs.write_text(json.dumps(data))
    assert run().returncode==0 and calls.read_text()==previous
    data['location-screenshot']=d+'/Desktop'; prefs.write_text(json.dumps(data))
    assert run().returncode==0
    assert json.loads(prefs.read_text())['location-screenshot']==d+'/Screenshots'
    data['location-screenshot']=d+'/Desktop'; prefs.write_text(json.dumps(data))
    env['DROP_WRITES']='1'
    assert run().returncode!=0
print('PASS screenshot migration, drift repair, tilde paths, idempotency, dry-run, and failed-write detection')
PY
