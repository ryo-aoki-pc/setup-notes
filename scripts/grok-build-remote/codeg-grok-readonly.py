#!/usr/bin/python3
"""Enforce read-only Grok delegation for the official Claude plugin."""
import os
import pwd
import stat
import sys
from pathlib import Path

GROK_DIR = Path(pwd.getpwuid(os.getuid()).pw_dir) / '.grok'
GROK = str(GROK_DIR / 'bin/grok')
args = sys.argv[1:]
if args in (['version'], ['--version'], ['models']):
    os.execv(GROK, [GROK, *args])

self_test = args == ['--self-test']
if not self_test:
    if not any(flag in args for flag in ('-p', '--single')):
        sys.exit('This launcher supports read-only headless plugin tasks only.')
    try:
        sandbox = args[args.index('--sandbox') + 1]
    except (ValueError, IndexError):
        sandbox = None
    if sandbox != 'read-only':
        sys.exit('A read-only sandbox is required; writable delegation is disabled.')
    if any(flag in args for flag in ('--restore-code', '--worktree', '-w')) or any(
        flag.startswith('--worktree=') or (flag.startswith('-w') and len(flag) > 2)
        for flag in args
    ):
        sys.exit('Worktree creation and code restoration are disabled in this launcher.')
    if any(flag == '--leader-socket' or flag.startswith('--leader-socket=') for flag in args):
        sys.exit('A caller-supplied leader socket is disabled in this launcher.')
    # The outer bwrap boundary is mandatory. Avoid a second, unavailable sandbox.
    args[args.index('--sandbox') + 1] = 'off'

runtime_dirs = [GROK_DIR / 'sessions', GROK_DIR / 'logs']
for path in runtime_dirs:
    if path.is_symlink() or not path.is_dir():
        sys.exit('Expected an existing, non-symlink Grok runtime directory.')

command = [
    '/usr/bin/bwrap', '--die-with-parent', '--new-session',
    '--unshare-user', '--unshare-pid', '--disable-userns',
    '--assert-userns-disabled', '--cap-drop', 'ALL',
    '--ro-bind', '/', '/', '--proc', '/proc', '--dev', '/dev',
    '--tmpfs', '/tmp', '--tmpfs', '/run',
]
for path in runtime_dirs:
    command.extend(['--bind', str(path), str(path)])
# Do not connect to an existing Grok leader outside this mount/PID namespace.
for socket in GROK_DIR.glob('leader*.sock'):
    if stat.S_ISSOCK(socket.lstat().st_mode):
        command.extend(['--ro-bind', '/dev/null', str(socket)])
command.append('--')
if self_test:
    test_code = '''import errno,json,os,sys
target=sys.argv[1]+'/.readonly-sandbox-probe-'+str(os.getpid())
try:
 fd=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
 os.close(fd);os.unlink(target);readonly=False
except OSError as error:
 readonly=error.errno in (errno.EROFS,errno.EACCES)
runtime=sys.argv[2]+'/.readonly-runtime-probe-'+str(os.getpid())
fd=os.open(runtime,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600);os.close(fd);os.unlink(runtime)
print(json.dumps({'filesystem_read_only':readonly,'session_storage_writable':True}))
raise SystemExit(0 if readonly else 1)
'''
    command.extend([
        '/usr/bin/python3', '-c', test_code,
        str(GROK_DIR.parent / '.local/share/codeg'), str(GROK_DIR / 'sessions'),
    ])
else:
    command.extend([GROK, '--no-auto-update', '--leader-socket', '/tmp/codeg-readonly-leader.sock', *args])
environment = dict(os.environ)
environment['GROK_MEMORY'] = '0'
environment['GROK_DISABLE_AUTOUPDATER'] = '1'
environment['GROK_LEADER_SOCKET'] = '/tmp/codeg-readonly-leader.sock'
os.execvpe(command[0], command, environment)
