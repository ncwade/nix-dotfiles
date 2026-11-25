from pathlib import Path
import runpy
import shlex
import tempfile
import unittest
from unittest.mock import patch


retire = runpy.run_path(str(Path(__file__).resolve().parents[1] / "programs/retire-codex-customizations.py"))["retire"]


class RetirementTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = Path(tmp.name) / "test user"
        self.generation = Path(tmp.name) / "generation"
        self.generation.mkdir()
        self.state = self.home / "state"
        self.codex = self.home / ".codex"
        self.skills = self.codex / "skills"
        for name in ("git-workflow", "personal-wiki", "manual", ".system"):
            path = self.skills / name
            path.mkdir(parents=True)
            (path / "SKILL.md").write_text("local copy")
        installer = []
        for name, skill in (("installCodexSkills", "git-workflow"), ("installPersonalWiki", "personal-wiki")):
            installer.extend([f'_iNote "Activating %s" "{name}"', "  " + shlex.quote(str(self.skills / skill) + "/")])
        (self.generation / "activate").write_text("\n".join(installer) + "\n")

    def migrate(self):
        retire(self.generation, self.home, self.state)

    def test_transition_preserves_other_settings_and_skills(self):
        config = self.codex / "config.toml"
        keep = b'model = "my-model"\r\n'
        config.write_bytes(b'# nix-config personal-wiki default\r\ndefault_permissions = "personal-wiki"\r\n'
                           b'# end nix-config personal-wiki default\r\n' + keep +
                           b'# nix-config personal-wiki profile\r\n[permissions.personal-wiki]\r\n'
                           b'# end nix-config personal-wiki profile\r\n')
        guidance = self.codex / "AGENTS.md"
        guidance.write_text("My own instructions\n<!-- nix-config personal-wiki guidance -->\nold\n"
                            "<!-- end nix-config personal-wiki guidance -->\n")
        before = config.read_bytes()
        self.migrate()
        backup, = self.state.iterdir()
        self.assertEqual((backup / "config.toml").read_bytes(), before)
        self.assertEqual(config.read_bytes(), keep)
        self.assertEqual(guidance.read_text(), "My own instructions\n")
        self.assertEqual({p.name for p in self.skills.iterdir()}, {"manual", ".system"})
        self.assertEqual((backup / "skills/git-workflow/SKILL.md").read_text(), "local copy")
        self.migrate()
        self.assertEqual(list(self.state.iterdir()), [backup])

    def test_invalid_markers_preserve_originals(self):
        (self.codex / "AGENTS.md").write_text("<!-- nix-config personal-wiki guidance -->\n")
        with self.assertRaises(ValueError):
            self.migrate()
        self.assertTrue((self.skills / "git-workflow").exists())
        self.assertFalse(self.state.exists())

    def test_rex_only_removed_when_previous_generation_installed_it(self):
        with patch("subprocess.run") as run:
            self.migrate()
            run.assert_not_called()
            (self.generation / "activate").write_text('_iNote "Activating %s" "installRexCodexSkills"\nrex skill setup\n')
            self.migrate()
            run.assert_called_once_with([self.generation / "home-path/bin/rex", "skill", "remove", "--agent", "codex"], check=True)
