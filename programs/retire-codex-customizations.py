"""Retire files installed by the previous Home Manager generation, once per transition."""
import os
from pathlib import Path
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import tomllib


def activation_step(script, name):
    marker = f'_iNote "Activating %s" "{name}"\n'
    return script.partition(marker)[2].split('\n_iNote "Activating %s"', 1)[0]


def without_wiki_block(text, name, markdown=False):
    start, end = (f"# {prefix}nix-config personal-wiki {name}" for prefix in ("", "end "))
    if markdown:
        start, end = (f"<!-- {line[2:]} -->" for line in (start, end))
    lines = text.splitlines(keepends=True)
    markers = [line.rstrip("\r\n") for line in lines if line.rstrip("\r\n") in (start, end)]
    if not markers:
        return text
    if markers != [start, end]:
        raise ValueError(f"Malformed personal-wiki block: {name}")
    return re.sub(r"^" + re.escape(start) + r"\r?\n.*?^" + re.escape(end) + r"(?:\r?\n|\Z)",
                  "", text, count=1, flags=re.M | re.S)


def retire(generation, home, state):
    script = (generation / "activate").read_text()
    skills = activation_step(script, "installCodexSkills")
    wiki = activation_step(script, "installPersonalWiki")
    rex = activation_step(script, "installRexCodexSkills")
    if not (skills or wiki or rex):
        return

    codex = home / ".codex"
    edits = []
    if wiki:
        for name, blocks in (("config.toml", ("default", "profile")), ("AGENTS.md", ("guidance",))):
            path = codex / name
            if not path.is_file():
                continue
            original = path.read_bytes()
            updated = original.decode()
            for block in blocks:
                updated = without_wiki_block(updated, block, markdown=name == "AGENTS.md")
            if updated.encode() != original:
                if path.is_symlink():
                    raise ValueError(f"Reconcile the wiki markers in symlink {path} before retrying")
                if name == "config.toml":
                    tomllib.loads(updated)
                edits.append((path, original, updated.encode()))

    # Match the exact rsync destination argument, including the personal-wiki skill.
    root = codex / "skills"
    destinations = set()
    for line in (skills + "\n" + wiki).splitlines():
        args = shlex.split(line.rstrip().removesuffix("\\"))
        if args:
            destinations.add(args[-1])
    owned = [p for p in root.iterdir() if str(p) + "/" in destinations] if root.is_dir() else []
    if owned or edits:
        state.mkdir(mode=0o700, parents=True, exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix="codex-before-removal-", dir=state))
        print(f"Archiving previous Codex customizations in {backup}", flush=True)
        for path, original, updated in edits:
            (backup / path.name).write_bytes(original)
            with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as tmp:
                pending = Path(tmp.name)
                tmp.write(updated)
            try:
                pending.chmod(stat.S_IMODE(path.stat().st_mode))
                if path.read_bytes() != original:
                    raise ValueError(f"{path} changed during activation; retry")
                os.replace(pending, path)
            finally:
                pending.unlink(missing_ok=True)
        if owned:
            (backup / "skills").mkdir()
            for path in owned:
                shutil.move(path, backup / "skills" / path.name)

    if rex:
        subprocess.run([generation / "home-path/bin/rex", "skill", "remove", "--agent", "codex"], check=True)


if __name__ == "__main__":
    home = Path.home()
    state = Path(os.environ.get("XDG_STATE_HOME") or home / ".local/state")
    retire(Path(sys.argv[1]), home, state / "nix-dotfiles")
