"""Run with: python3 -m unittest discover -s tests -p 'test_personal_wiki.py'."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]


def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, REPO / 'programs/personal-wiki' / filename)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


configure = module('configure', 'configure.py')
wiki = module('wiki', 'wiki.py')


class PersonalWikiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / 'codex'
        self.home.mkdir()
        self.settings = dict(codexHome=str(self.home), path=str(self.root / 'wiki with spaces'),
                             remote=None, permissionProfile='personal-wiki')
        self.config = self.home / 'config.toml'
        self.agents = self.home / 'AGENTS.md'

    def test_preserves_user_settings_and_instructions_idempotently(self):
        original = '# keep my comment\nmodel = "user-model"\napproval_policy = "on-request"\n[features]\nexample = true\n[permissions.existing]\nextends = ":read-only"\n'
        guidance = '# My preferences\nAlways ask before Git.\n'
        self.config.write_text(original)
        self.agents.write_text(guidance)
        configure.configure(self.settings)
        first = self.config.read_text(), self.agents.read_text()
        configure.configure(self.settings)
        self.assertEqual(first, (self.config.read_text(), self.agents.read_text()))
        self.assertIn(original, first[0])
        self.assertTrue(first[1].startswith(guidance))
        result = tomllib.loads(first[0])
        self.assertEqual(result['approval_policy'], 'on-request')
        self.assertEqual(result['permissions']['existing'], {'extends': ':read-only'})
        profile = result['permissions']['personal-wiki']
        self.assertEqual(profile, {'description': 'Workspace editing with the shared personal wiki',
                                  'extends': ':workspace', 'workspace_roots': {self.settings['path']: True},
                                  'filesystem': {self.settings['path'] + '/.git': 'write'}})
        self.assertEqual((self.home / 'config.toml.before-personal-wiki').read_text(), original)

    def test_path_change_replaces_old_grant(self):
        configure.configure(self.settings)
        previous = self.settings['path']
        self.settings['path'] = str(self.root / 'new wiki')
        configure.configure(self.settings)
        self.assertNotIn(previous, self.config.read_text())
        self.assertIn(self.settings['path'], self.agents.read_text())

    def test_keeps_existing_default(self):
        self.config.write_text('default_permissions = ":read-only"\n')
        with contextlib.redirect_stderr(io.StringIO()):
            configure.configure(self.settings)
        self.assertEqual(tomllib.loads(self.config.read_text())['default_permissions'], ':read-only')

    def test_conflicts_fail_before_writing(self):
        for original in ['sandbox_mode = "workspace-write"\n',
                         '[profiles.old]\nsandbox_mode = "read-only"\n',
                         '[permissions.personal-wiki]\nextends = ":read-only"\n',
                         '# nix-config personal-wiki profile\nbroken = true\n']:
            with self.subTest(original=original):
                self.config.write_text(original)
                with self.assertRaises(ValueError):
                    configure.configure(self.settings)
                self.assertEqual(self.config.read_text(), original)
                self.assertFalse(self.agents.exists())

    def test_symlink_refused(self):
        other = self.root / 'other'
        other.write_text('model = "keep"\n')
        self.config.symlink_to(other)
        with self.assertRaises(ValueError):
            configure.configure(self.settings)
        self.assertEqual(other.read_text(), 'model = "keep"\n')

    def test_manual_permissions_leave_legacy_settings_untouched(self):
        original = 'sandbox_mode = "workspace-write"\n'
        self.config.write_text(original)
        self.settings['permissionProfile'] = None
        configure.configure(self.settings)
        self.assertEqual(self.config.read_text(), original)
        self.assertTrue(self.agents.exists())

    def test_override_is_preserved_and_reported(self):
        override = self.home / 'AGENTS.override.md'
        override.write_text('My temporary instructions')
        with contextlib.redirect_stderr(io.StringIO()) as output:
            configure.configure(self.settings)
        self.assertIn('takes precedence', output.getvalue())
        self.assertEqual(override.read_text(), 'My temporary instructions')

    def test_bootstrap_preserves_content_and_has_no_git_side_effects(self):
        root = Path(self.settings['path'])
        template = REPO / 'skills/personal-wiki/assets/template'
        wiki.bootstrap(root, template)
        (root / 'index.md').write_text('Existing curated index')
        (root / 'raw/original.bin').write_bytes(b'original\x00bytes')
        (root / 'log.md').write_text('Earlier history\n')
        wiki.bootstrap(root, template)
        self.assertEqual((root / 'index.md').read_text(), 'Existing curated index')
        self.assertEqual((root / 'raw/original.bin').read_bytes(), b'original\x00bytes')
        self.assertEqual((root / 'log.md').read_text(), 'Earlier history\n')
        self.assertFalse((root / '.git').exists())
        self.assertFalse((root / '.wiki-write.lock').exists())
        self.assertEqual({p.name for p in root.iterdir() if p.is_dir()},
                         {'raw', 'sources', 'entities', 'topics', 'notes'})

    def test_lock_excludes_second_writer_and_wrong_owner(self):
        wiki.lock(self.root, 'chat-one')
        with self.assertRaises(FileExistsError):
            wiki.lock(self.root, 'chat-two')
        with self.assertRaises(ValueError):
            wiki.unlock(self.root, 'chat-two')
        self.assertEqual((self.root / '.wiki-write.lock/owner').read_text(), 'chat-one\n')
        wiki.unlock(self.root, 'chat-one')
        wiki.lock(self.root, 'chat-two')
        wiki.unlock(self.root, 'chat-two')

    def test_bootstrap_respects_lock(self):
        wiki.lock(self.root, 'another-chat')
        with self.assertRaises(FileExistsError):
            wiki.bootstrap(self.root, REPO / 'skills/personal-wiki/assets/template')
        self.assertFalse((self.root / 'index.md').exists())
        wiki.unlock(self.root, 'another-chat')


if __name__ == '__main__':
    unittest.main()
