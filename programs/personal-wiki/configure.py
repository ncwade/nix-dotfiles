"""Merge only owned blocks into mutable Codex files; no Git or network operations."""
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import tomllib


def block(text, name, body, *, prepend=False, markdown=False):
    start = f"<!-- nix-config personal-wiki {name} -->" if markdown else f"# nix-config personal-wiki {name}"
    end = f"<!-- end nix-config personal-wiki {name} -->" if markdown else f"# end nix-config personal-wiki {name}"
    if text.count(start) != text.count(end) or text.count(start) > 1:
        raise ValueError(f"Malformed managed block: {name}")
    pattern = re.compile(r"^" + re.escape(start) + r"\n.*?^" + re.escape(end) + r"\n?", re.M | re.S)
    replacement = f"{start}\n{body.rstrip()}\n{end}\n" if body else ""
    if start in text:
        if not pattern.search(text):
            raise ValueError(f"Malformed managed block: {name}")
        return pattern.sub(lambda _: replacement, text, count=1)
    if not replacement:
        return text
    if prepend:
        return replacement + text
    return text + ("\n" if text and not text.endswith("\n") else "") + replacement


def read_regular(path):
    if path.is_symlink():
        raise ValueError(f"Refusing to replace symlink: {path}; reconcile its owner first")
    return path.read_text() if path.exists() else ""


def replace(path, old, new):
    if old == new:
        return
    if path.exists():
        backup = path.with_name(path.name + ".before-personal-wiki")
        if not backup.exists():
            with backup.open("x") as f:
                f.write(old)
            backup.chmod(0o600)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=".personal-wiki-")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(new)
        os.chmod(tmp, path.stat().st_mode & 0o777 if path.exists() else 0o600)
        if read_regular(path) != old:
            raise ValueError(f"File changed during activation: {path}; retry with Codex closed")
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def configure(settings):
    home = Path(settings["codexHome"])
    config_path, agents_path = home / "config.toml", home / "AGENTS.md"
    old_config, old_agents = read_regular(config_path), read_regular(agents_path)
    new_config = old_config
    profile = settings["permissionProfile"]
    if profile is not None:
        # Strip only our blocks before detecting conflicting user-owned keys.
        base = block(block(old_config, "default", ""), "profile", "")
        parsed = tomllib.loads(base)
        if any(k in parsed for k in ("sandbox_mode", "sandbox_workspace_write")) or any(
            any(k in p for k in ("sandbox_mode", "sandbox_workspace_write"))
            for p in parsed.get("profiles", {}).values()
        ):
            raise ValueError("Legacy sandbox settings found. Set programs.personalWiki.permissionProfile = null and attach the wiki folder, or explicitly migrate those settings first.")
        if profile in parsed.get("permissions", {}):
            raise ValueError(f"Permission profile {profile!r} already belongs to another configuration; choose another name")
        if "default_permissions" not in parsed:
            base = block(base, "default", f"default_permissions = {json.dumps(profile)}", prepend=True)
        elif parsed["default_permissions"] != profile:
            print(f"Keeping existing default_permissions; select {profile!r} explicitly to grant wiki access.", file=sys.stderr)
        body = f'''[permissions.{profile}]
description = "Workspace editing with the shared personal wiki"
extends = ":workspace"

[permissions.{profile}.workspace_roots]
{json.dumps(settings['path'])} = true

[permissions.{profile}.filesystem]
{json.dumps(str(Path(settings['path']) / '.git'))} = "write"'''
        new_config = block(base, "profile", body)
        tomllib.loads(new_config)
    guidance = f'''## Personal knowledge wiki

The shared local wiki is `{settings['path']}`. Use the `personal-wiki` skill
at `{home}/skills/personal-wiki/SKILL.md` for requests to ingest sources,
query the wiki, save conclusions there, or check its health. Use it across
projects; do not create project-specific copies. Ordinary chats are not
captured automatically. The user authorized the wiki helper to commit each completed
update and periodically sync its configured origin/branch. Use its begin/finish
transaction and sync command; other Git operations retain existing approval rules.
This is local Codex guidance, not ChatGPT web memory.'''
    new_agents = block(old_agents, "guidance", guidance, markdown=True)
    # All content is checked before touching either file.
    home.mkdir(parents=True, exist_ok=True)
    replace(config_path, old_config, new_config)
    replace(agents_path, old_agents, new_agents)
    override = home / "AGENTS.override.md"
    if override.exists() and override.read_text().strip():
        print(f"WARNING: {override} takes precedence over AGENTS.md; add wiki routing there if desired.", file=sys.stderr)


if __name__ == "__main__":
    try:
        configure(json.loads(Path(sys.argv[1]).read_text()))
    except (ValueError, OSError) as error:
        sys.exit(f"personal-wiki configuration: {error}")
