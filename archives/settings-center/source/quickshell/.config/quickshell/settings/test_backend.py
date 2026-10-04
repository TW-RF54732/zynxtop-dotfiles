#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys, tempfile, unittest
from unittest.mock import patch
import backend as b

class BackendTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root=pathlib.Path(self.tmp.name)
        self.patch=patch.multiple(b,CONFIG=self.root/'config',ROOT=self.root/'config/settings-center',STATE=self.root/'state')
        self.patch.start(); self.addCleanup(self.patch.stop)
        self.caps=patch.object(b,'capabilities',return_value={'hyprland':False}); self.caps.start(); self.addCleanup(self.caps.stop)
    def save(self,changes): return b.apply(dict(revision=b.read()[1],changes=changes))
    def test_initial_read_does_not_write(self):
        result=b.snapshot(); self.assertEqual(len(result['pages']),15); self.assertFalse(b.ROOT.exists())
    def test_only_changes_backup_and_reset(self):
        self.save({'typography.bodySize':20})
        self.assertEqual(b.read()[0]['values'],{'typography.bodySize':20})
        self.save({'dnd':True})
        self.assertEqual(json.loads((b.ROOT/'settings.json.previous').read_text())['values'],{'typography.bodySize':20})
        self.save({'typography.bodySize':None})
        self.assertEqual(b.read()[0]['values'],{'dnd':True})
    def test_external_conflict(self):
        revision=b.read()[1]; self.save({'dnd':True})
        with self.assertRaisesRegex(ValueError,'外部修改'): b.apply(dict(revision=revision,changes={'dnd':False}))
    def test_generated_external_conflict(self):
        self.save({'dnd':True}); revision=b.read()[1]
        (b.ROOT/'kitty.conf').write_text('# external edit')
        with self.assertRaises(ValueError): b.apply(dict(revision=revision,changes={'dnd':False}))
    def test_corrupt_file_preserved(self):
        b.ROOT.mkdir(parents=True); p=b.ROOT/'settings.json'; p.write_text('{broken')
        with self.assertRaises(ValueError): b.read()
        self.assertEqual(p.read_text(),'{broken')
    def test_invalid_values_no_writes(self):
        for changes in ({'typography.bodySize':0},{'dnd':1},{'font_size':float('nan')},{'wallpaper':'a\nsource=oops'},{'privateKey':'secret'}):
            with self.assertRaises(ValueError): self.save(changes)
        self.assertFalse((b.ROOT/'settings.json').exists())
    def test_write_failure_rolls_back(self):
        self.save({'dnd':True}); original={p.name:p.read_bytes() for p in b.ROOT.iterdir() if p.is_file()}
        atomic=b.atomic
        def fail(path,text):
            if path.name=='kitty.conf' and text: raise OSError('disk full')
            atomic(path,text)
        with patch.object(b,'atomic',side_effect=fail):
            with self.assertRaises(OSError): self.save({'font_size':18})
        for name,data in original.items(): self.assertEqual((b.ROOT/name).read_bytes(),data)
    def test_symlink_target_untouched(self):
        b.ROOT.mkdir(parents=True); target=self.root/'tracked'; target.write_text('tracked')
        (b.ROOT/'kitty.conf').symlink_to(target)
        with self.assertRaises(ValueError): self.save({'font_size':18})
        self.assertTrue((b.ROOT/'kitty.conf').is_symlink()); self.assertEqual(target.read_text(),'tracked')
    def test_read_existing_kitty_symlink(self):
        target=self.root/'kitty.conf'; target.write_text('font_size 17\nfont_family Test Font\n')
        (b.CONFIG/'kitty').mkdir(parents=True); (b.CONFIG/'kitty/kitty.conf').symlink_to(target)
        result=b.snapshot(); self.assertEqual(result['values']['font_size'],17)
        self.save({'font_size':19}); self.assertEqual(target.read_text(),'font_size 17\nfont_family Test Font\n')
    def test_hypr_unavailable_not_saved(self):
        with self.assertRaisesRegex(ValueError,'Hyprland'): self.save({'general.border_size':2})
        self.assertFalse((b.ROOT/'settings.json').exists())
    def test_hypr_failed_apply_rolls_back(self):
        self.save({'dnd':True}); before=b.read()[0]
        with patch.object(b,'capabilities',return_value={'hyprland':True}),patch.object(b,'run',side_effect=ValueError('cancelled')):
            with self.assertRaises(ValueError): self.save({'general.border_size':2})
        self.assertEqual(b.read()[0],before)
    def test_lua_escaping(self):
        value=b.lua('中文"\\\n')
        self.assertNotIn('\n',value); self.assertNotIn('中文',value); self.assertIn('\\034',value)
    def test_secrets_not_in_argv_or_error(self):
        with patch.object(b.subprocess,'run',return_value=subprocess.CompletedProcess([],1,'password: secret','secret')) as mock:
            with self.assertRaises(ValueError) as result: b.action({'name':'wifi-connect','arg':'Home','password':'secret'})
        self.assertNotIn('secret',str(result.exception)); self.assertNotIn('secret',str(mock.call_args.args)); self.assertEqual(mock.call_args.kwargs['input'],'secret\n')
    def test_last_monitor_rejected(self):
        with patch.object(b,'run',return_value=json.dumps([{'name':'DP-1'}])):
            with self.assertRaisesRegex(ValueError,'最後'): b.monitors({'op':'monitor-preview','monitors':[{'output':'DP-1','disabled':True}]})
    def test_shortcut_conflict(self):
        with patch.object(b,'run',return_value=json.dumps([{'modmask':64,'key':'C'}])):
            with self.assertRaisesRegex(ValueError,'衝突'): b.validate_bindings({'bind.browser':'SUPER + C'}, {})
    def test_network_validation_and_cancellation(self):
        from system_settings import network
        with self.assertRaises(ValueError): network({'uuid':'x'*36,'properties':{}},lambda *a: None)
        def cancelled(*args): raise ValueError('authorization cancelled')
        with self.assertRaisesRegex(ValueError,'cancelled'): network({'uuid':'a'*36,'properties':{'ipv4.method':'auto'}},cancelled)
    def test_monitor_guard_eof_timeout_and_confirm(self):
        binpath=self.root/'bin'; binpath.mkdir()
        executable=binpath/'hyprctl'; log=self.root/'calls'
        executable.write_text('#!/usr/bin/env python3\nimport os,pathlib\npathlib.Path(os.environ["GUARD_LOG"]).write_text("restored")\n'); executable.chmod(0o700)
        env=dict(os.environ,PATH=str(binpath)+':'+os.environ['PATH'],XDG_CONFIG_HOME=str(b.CONFIG),XDG_STATE_HOME=str(self.root/'state'),GUARD_LOG=str(log))
        for mode in ('eof','timeout','confirm'):
            log.unlink(missing_ok=True)
            proc=subprocess.Popen([sys.executable,"-B",str(pathlib.Path(b.__file__).with_name('monitor_guard.py'))],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True,env=env)
            proc.stdin.write(json.dumps({'restore':'hl.monitor({})','code':'-- confirmed','seconds':0.1})+'\n'); proc.stdin.flush()
            if mode=='confirm': proc.stdin.write('confirm\n'); proc.stdin.flush()
            if mode!='timeout': proc.stdin.close()
            proc.wait(timeout=5)
            response=json.loads(proc.stdout.read()); proc.stdout.close()
            if mode=='timeout': proc.stdin.close()
            self.assertEqual(response['ok'],mode=='confirm'); self.assertEqual(log.exists(),mode!='confirm')
        self.assertEqual((b.ROOT/'monitors.lua').read_text(),'-- confirmed')

if __name__=='__main__': unittest.main()
