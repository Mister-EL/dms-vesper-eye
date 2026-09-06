import importlib.util
import json
import os
from pathlib import Path
import select
import socket
import subprocess
import tempfile
import threading
import time
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'helpers/cursor_poller.py'

class CursorBridgeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ve-ipc-')
        self.path = Path(self.temp.name) / 'hypr/test/.socket.sock'
        self.path.parent.mkdir(parents=True)
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.bind(str(self.path)); self.sock.listen(); self.sock.settimeout(.1)
        self.awake = True; self.xy = {'x': 20, 'y': 30}; self.calls = []; self.stop = False
        def serve():
            while not self.stop:
                try:
                    c, _ = self.sock.accept()
                except socket.timeout:
                    continue
                except OSError:
                    return
                with c:
                    cmd = c.recv(256).decode(); self.calls.append(cmd)
                    response = [{'name': 'TEST', 'dpmsStatus': self.awake}] if cmd == 'j/monitors' else self.xy
                    try:
                        c.sendall(json.dumps(response).encode())
                    except BrokenPipeError:
                        pass  # Client terminated between request and response.
        self.thread = threading.Thread(target=serve, daemon=True); self.thread.start()
        self.env = dict(os.environ, XDG_RUNTIME_DIR=self.temp.name, HYPRLAND_INSTANCE_SIGNATURE='test')
        self.proc = None
    def tearDown(self):
        if self.proc:
            self.proc.terminate(); self.proc.wait(timeout=3)
            self.proc.stdout.close(); self.proc.stderr.close()
        self.stop = True; self.sock.close(); self.thread.join(timeout=1); self.temp.cleanup()
    def start(self, *extra):
        self.proc = subprocess.Popen(['python3',str(HELPER),'--screen','TEST',*extra],env=self.env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    def line(self):
        ready,_,_=select.select([self.proc.stdout],[],[],3)
        self.assertTrue(ready,'No output from bridge'); return json.loads(self.proc.stdout.readline())
    def test_requires_explicit_instance(self):
        self.env.pop('HYPRLAND_INSTANCE_SIGNATURE')
        p=subprocess.run(['python3',str(HELPER),'--screen','TEST'],env=self.env,capture_output=True,text=True,timeout=2)
        self.assertEqual(p.returncode,2);self.assertEqual(self.calls,[])
    def test_changed_cursor_only(self):
        self.start();self.assertEqual(self.line(),{'awake':True})
        # TextIO may buffer the second line; read it directly after the status.
        point=json.loads(self.proc.stdout.readline());self.assertEqual((point['x'],point['y']),(20,30))
        time.sleep(.25);self.xy={'x':40,'y':50};point=self.line();self.assertEqual((point['x'],point['y']),(40,50));self.assertGreaterEqual(point['speed'],0)
    def test_dpms_off_never_queries_cursor(self):
        self.awake=False;self.start();self.assertEqual(self.line(),{'awake':False});time.sleep(1.2)
        self.assertNotIn('j/cursorpos',self.calls)
        self.awake=True;self.assertEqual(self.line(),{'awake':True})
        self.assertEqual(json.loads(self.proc.stdout.readline())['x'],20)
    def test_no_cursor_keeps_only_monitor_detection(self):
        self.start('--no-cursor'); self.assertEqual(self.line(), {'awake': True})
        time.sleep(.6); self.assertNotIn('j/cursorpos', self.calls)
    def test_sigterm_is_prompt(self):
        self.start();self.line();self.proc.terminate();self.assertEqual(self.proc.wait(timeout=2),0)

if __name__ == '__main__': unittest.main()
