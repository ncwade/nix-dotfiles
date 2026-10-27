"""Integration tests use only disposable local repositories; no network or user Git config."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('wiki', Path(__file__).resolve().parents[1] / 'programs/personal-wiki/wiki.py')
wiki = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(wiki)
GIT = shutil.which('git')


@unittest.skipUnless(GIT, 'Git required for local integration tests')
class WikiGitTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='wiki-git-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.env = patch.dict(os.environ, {'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.root = self.base / 'wiki with spaces'
        self.remote = self.base / 'remote.git'
        self.git(self.base, 'init', '--bare', str(self.remote))
        self.git(self.base, 'init', '-b', 'main', str(self.root))
        self.identity(self.root)
        (self.root / '.gitignore').write_text('.wiki-write.lock/\n')
        (self.root / 'index.md').write_text('# Index\n')
        (self.root / 'notes').mkdir()
        self.git(self.root, 'add', '.gitignore', 'index.md')
        self.git(self.root, 'commit', '-m', 'docs(wiki): initialize fixture')
        self.git(self.root, 'remote', 'add', 'origin', str(self.remote))
        self.git(self.root, 'push', '-u', 'origin', 'main')
        self.repo = wiki.Repository({'path': str(self.root), 'remote': str(self.remote), 'branch': 'main'}, GIT)

    def git(self, root, *args):
        return subprocess.run([GIT, '-C', str(root), *args], check=True, capture_output=True, text=True).stdout.strip()

    def identity(self, root):
        self.git(root, 'config', 'user.name', 'Wiki Test')
        self.git(root, 'config', 'user.email', 'wiki-test@example.invalid')

    def update(self, name='notes/one.md'):
        wiki.begin(self.repo, 'test-owner')
        (self.root / name).write_text('New evidence\n')
        wiki.finish(self.repo, 'test-owner', 'docs(wiki): save evidence', [name])

    def peer_update(self):
        peer = self.base / 'peer'
        self.git(self.base, 'clone', '-b', 'main', str(self.remote), str(peer))
        self.identity(peer)
        (peer / 'incoming.md').write_text('Incoming evidence\n')
        self.git(peer, 'add', 'incoming.md')
        self.git(peer, 'commit', '-m', 'docs(wiki): add incoming evidence')
        self.git(peer, 'push', 'origin', 'main')

    def test_one_inline_commit_and_no_inline_push(self):
        before = self.git(self.root, 'rev-parse', 'HEAD')
        self.update()
        self.assertNotEqual(self.git(self.root, 'rev-parse', 'HEAD'), before)
        self.assertEqual(self.git(self.remote, 'rev-parse', 'main'), before)
        self.assertEqual(self.git(self.root, 'show', '--pretty=', '--name-only', 'HEAD'), 'notes/one.md')
        self.assertEqual(self.repo.changes(), set())
        self.assertFalse((self.root / '.wiki-write.lock').exists())

    def test_push_and_idempotent_resync(self):
        self.update()
        self.assertEqual(wiki.sync(self.repo), 'Pushed committed updates')
        self.assertEqual(self.git(self.remote, 'rev-parse', 'main'), self.git(self.root, 'rev-parse', 'HEAD'))
        self.assertEqual(wiki.sync(self.repo), 'Already synchronized')
        status = json.loads((self.root / '.git/personal-wiki-sync.json').read_text())
        self.assertEqual(status['status'], 'ok')
        self.assertIsNotNone(status['lastSuccessAt'])

    def test_sync_fast_forwards_incoming_commit(self):
        self.peer_update()
        self.assertEqual(wiki.sync(self.repo), 'Fast-forwarded incoming commits')
        self.assertTrue((self.root / 'incoming.md').exists())

    def test_divergence_preserves_both_histories(self):
        self.peer_update()
        self.update()
        local = self.git(self.root, 'rev-parse', 'HEAD')
        remote = self.git(self.remote, 'rev-parse', 'main')
        with self.assertRaisesRegex(ValueError, 'diverged'):
            wiki.sync(self.repo)
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), local)
        self.assertEqual(self.git(self.remote, 'rev-parse', 'main'), remote)
        self.assertFalse((self.root / '.wiki-write.lock').exists())
        self.assertEqual(json.loads((self.root / '.git/personal-wiki-sync.json').read_text())['status'], 'error')

    def test_dirty_tree_is_neither_committed_nor_pushed(self):
        original = self.git(self.root, 'rev-parse', 'HEAD')
        (self.root / 'index.md').write_text('Unfinished edit')
        with self.assertRaisesRegex(ValueError, 'uncommitted'):
            wiki.begin(self.repo, 'owner')
        with self.assertRaisesRegex(ValueError, 'uncommitted'):
            wiki.sync(self.repo)
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), original)
        self.assertEqual(self.git(self.remote, 'rev-parse', 'main'), original)
        self.assertEqual((self.root / 'index.md').read_text(), 'Unfinished edit')

    def test_sync_skips_active_writer(self):
        wiki.begin(self.repo, 'owner')
        self.assertIn('Skipped', wiki.sync(self.repo))
        wiki.require_owner(self.root, 'owner')
        wiki.unlock(self.root, 'owner')

    def test_finish_refuses_omitted_changes_without_staging(self):
        wiki.begin(self.repo, 'owner')
        (self.root / 'notes/one.md').write_text('My update')
        (self.root / 'unexpected.md').write_text('Another editor')
        with self.assertRaisesRegex(ValueError, 'omitted'):
            wiki.finish(self.repo, 'owner', 'docs(wiki): save note', ['notes/one.md'])
        self.assertEqual(self.git(self.root, 'diff', '--cached', '--name-only'), '')
        wiki.require_owner(self.root, 'owner')

    def test_signing_failure_retains_content_and_lock(self):
        self.git(self.root, 'config', 'commit.gpgsign', 'true')
        self.git(self.root, 'config', 'gpg.program', '/usr/bin/false')
        wiki.begin(self.repo, 'owner')
        original = self.git(self.root, 'rev-parse', 'HEAD')
        (self.root / 'notes/one.md').write_text('Keep this content')
        with self.assertRaisesRegex(ValueError, 'commit failed'):
            wiki.finish(self.repo, 'owner', 'docs(wiki): save note', ['notes/one.md'])
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), original)
        self.assertEqual((self.root / 'notes/one.md').read_text(), 'Keep this content')
        self.assertEqual(self.git(self.root, 'config', 'commit.gpgsign'), 'true')
        wiki.require_owner(self.root, 'owner')

    def test_remote_mismatch_and_wrong_branch_stop(self):
        self.git(self.root, 'config', 'remote.origin.pushurl', str(self.base / 'unexpected.git'))
        with self.assertRaisesRegex(ValueError, 'URL differs'):
            wiki.sync(self.repo)
        self.git(self.root, 'config', '--unset', 'remote.origin.pushurl')
        self.git(self.root, 'switch', '-c', 'unexpected')
        with self.assertRaisesRegex(ValueError, 'configured branch'):
            wiki.begin(self.repo, 'owner')

    def test_empty_transaction_and_changed_head(self):
        before = self.git(self.root, 'rev-parse', 'HEAD')
        wiki.begin(self.repo, 'owner')
        self.assertIn('No changes', wiki.finish(self.repo, 'owner', 'docs(wiki): empty', ['index.md']))
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), before)
        wiki.begin(self.repo, 'owner')
        self.git(self.root, 'commit', '--allow-empty', '-m', 'docs(wiki): other editor')
        with self.assertRaisesRegex(ValueError, 'HEAD changed'):
            wiki.finish(self.repo, 'owner', 'docs(wiki): empty', ['index.md'])

    def test_missing_remote_branch_does_not_publish_implicitly(self):
        self.git(self.remote, 'update-ref', '-d', 'refs/heads/main')
        with self.assertRaisesRegex(ValueError, 'fetch failed'):
            wiki.sync(self.repo)

    def test_inherited_git_directory_does_not_redirect_operations(self):
        with patch.dict(os.environ, {'GIT_DIR': str(self.remote), 'GIT_INDEX_FILE': str(self.base / 'bad-index')}):
            wiki.begin(self.repo, 'owner')
            wiki.finish(self.repo, 'owner', 'docs(wiki): no changes', ['index.md'])
        self.assertFalse((self.base / 'bad-index').exists())

    def test_literal_filename_with_spaces_and_deletion(self):
        name = 'notes/a [1] b.md'
        self.update(name)
        wiki.begin(self.repo, 'owner')
        (self.root / name).unlink()
        wiki.finish(self.repo, 'owner', 'docs(wiki): remove note', [name])
        self.assertEqual(self.repo.changes(), set())

    def test_cli_transaction(self):
        settings = self.base / 'settings.json'
        settings.write_text(json.dumps({'path': str(self.root), 'remote': str(self.remote), 'branch': 'main'}))
        command = [sys.executable, '-B', SPEC.origin, '--git', GIT, '--config', str(settings),
                   '--template', str(self.base)]
        subprocess.run([*command, 'begin', 'cli-owner'], check=True, capture_output=True)
        (self.root / 'notes/cli.md').write_text('CLI update')
        result = subprocess.run([*command, 'finish', 'cli-owner', '--message', 'docs(wiki): test CLI',
                                 '--', 'notes/cli.md'], check=True, capture_output=True, text=True)
        self.assertIn('Committed ', result.stdout)
        self.assertEqual(self.repo.changes(), set())

    def test_push_does_not_follow_tags(self):
        self.update()
        self.git(self.root, 'config', 'push.followTags', 'true')
        self.git(self.root, 'tag', '-a', 'local-only', '-m', 'Local tag')
        wiki.sync(self.repo)
        self.assertEqual(self.git(self.remote, 'tag', '--list'), '')

    def test_rejected_push_keeps_local_commit_and_last_success(self):
        wiki.sync(self.repo)
        status_path = self.root / '.git/personal-wiki-sync.json'
        last_success = json.loads(status_path.read_text())['lastSuccessAt']
        before = self.git(self.remote, 'rev-parse', 'main')
        self.update()
        local = self.git(self.root, 'rev-parse', 'HEAD')
        hook = self.remote / 'hooks/pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n')
        hook.chmod(0o755)
        with self.assertRaisesRegex(ValueError, 'push failed'):
            wiki.sync(self.repo)
        self.assertEqual(self.git(self.remote, 'rev-parse', 'main'), before)
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), local)
        status = json.loads(status_path.read_text())
        self.assertEqual(status['status'], 'error')
        self.assertEqual(status['lastSuccessAt'], last_success)
        self.assertFalse((self.root / '.wiki-write.lock').exists())
