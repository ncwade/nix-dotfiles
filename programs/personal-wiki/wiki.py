"""Shared wiki transactions and conservative, serialized Git sync."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import signal
import sys
import subprocess
import uuid


def lock(root, owner):
    directory = root / ".wiki-write.lock"
    directory.mkdir()  # Atomic acquisition; an existing lock is never stolen.
    try:
        (directory / "owner").write_text(owner + "\n")
    except BaseException:
        directory.rmdir()
        raise


def unlock(root, owner):
    directory = root / ".wiki-write.lock"
    if (directory / "owner").read_text().strip() != owner:
        raise ValueError("Lock belongs to another writer; leave it in place")
    (directory / "head").unlink(missing_ok=True)
    (directory / "owner").unlink()
    directory.rmdir()


def bootstrap(root, template):
    root.mkdir(parents=True, exist_ok=True)
    owner = f"bootstrap-{datetime.now(timezone.utc).isoformat()}"
    lock(root, owner)
    try:
        for name in ("raw", "sources", "entities", "topics", "notes"):
            (root / name).mkdir(exist_ok=True)
        for source in sorted(template.iterdir()):
            target = root / source.name
            # Refuse an unexpected symlink even if it points at a missing file.
            if target.exists() or target.is_symlink():
                continue
            with target.open("xb") as output, source.open("rb") as input_file:
                shutil.copyfileobj(input_file, output)
        # Existing .gitignore is user-owned. Warn instead of rewriting it.
        if ".wiki-write.lock/" not in (root / ".gitignore").read_text().splitlines():
            print("Add .wiki-write.lock/ to the wiki .gitignore before staging files.", file=sys.stderr)
    finally:
        unlock(root, owner)


def require_owner(root, owner):
    if (root / ".wiki-write.lock/owner").read_text().strip() != owner:
        raise ValueError("Lock belongs to another writer")


class Repository:
    def __init__(self, settings, executable="git"):
        self.root = Path(settings["path"]).resolve()
        self.branch = settings.get("branch", "main")
        self.remote = settings.get("remote")
        self.executable = executable

    def git(self, *args, allowed=(0,)):
        env = os.environ.copy()
        # -C alone does not defeat inherited repository/index overrides.
        for key in ("GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR", "GIT_INDEX_FILE",
                    "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES",
                    "GIT_NAMESPACE", "GIT_CONFIG_COUNT", "GIT_CONFIG_PARAMETERS",
                    "GIT_LITERAL_PATHSPECS", "GIT_GLOB_PATHSPECS", "GIT_NOGLOB_PATHSPECS",
                    "GIT_ICASE_PATHSPECS"):
            env.pop(key, None)
        env.update(GIT_TERMINAL_PROMPT="0", GCM_INTERACTIVE="Never")
        with subprocess.Popen(
                [self.executable, "-C", str(self.root), *args],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                env=env, start_new_session=True,
        ) as process:
            try:
                stdout, stderr = process.communicate(timeout=120)
            except subprocess.TimeoutExpired as error:
                # Kill Git's children too, so a timed-out SSH/hook cannot outlive the lock.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.communicate()
                raise ValueError(f"Git {args[0]} timed out; files and commits are retained") from error
            result = subprocess.CompletedProcess(process.args, process.returncode, stdout, stderr)
        if result.returncode not in allowed:
            detail = result.stderr.decode(errors="replace").strip()
            raise ValueError(f"Git {args[0]} failed: {detail or result.returncode}")
        return result

    def text(self, *args):
        return os.fsdecode(self.git(*args).stdout).strip()

    def check(self):
        metadata = self.root / ".git"
        if metadata.is_symlink() or not metadata.is_dir():
            raise ValueError("Wiki must be a standalone checkout with its own .git directory")
        if Path(self.text("rev-parse", "--show-toplevel")).resolve() != self.root:
            raise ValueError("Configured wiki path is not the repository root")
        if Path(self.text("rev-parse", "--absolute-git-dir")).resolve() != metadata:
            raise ValueError("Git metadata is outside the wiki")
        self.git("check-ref-format", "--branch", self.branch)
        if self.text("symbolic-ref", "--quiet", "--short", "HEAD") != self.branch:
            raise ValueError(f"Wiki must be on configured branch {self.branch!r}")
        for name in ("index.lock", "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD",
                     "rebase-merge", "rebase-apply", "BISECT_LOG"):
            if (metadata / name).exists():
                raise ValueError(f"Git operation in progress ({name}); resolve it first")
        if self.git("check-ignore", "-q", ".wiki-write.lock/", allowed=(0, 1)).returncode:
            raise ValueError("Add .wiki-write.lock/ to .gitignore before using transactions")
        self.text("rev-parse", "--verify", "HEAD")  # Initial commit is an explicit setup step.

    def changes(self):
        # Disable rename folding so every record has exactly one literal path.
        result = self.git("-c", "status.renames=false", "status", "--porcelain=v1",
                          "-z", "--untracked-files=all").stdout
        records = [record for record in result.split(b"\0") if record]
        if any(b"U" in record[:2] or record[:2] in (b"AA", b"DD") for record in records):
            raise ValueError("Unresolved Git conflicts")
        return {os.fsdecode(record[3:]) for record in records}

    def clean(self):
        if self.changes():
            raise ValueError("Wiki has uncommitted changes; finish or recover that update first")

    def check_remote(self):
        if not self.remote:
            raise ValueError("No remote configured; set programs.personalWiki.remote")
        for args in (("remote", "get-url", "--all", "origin"),
                     ("remote", "get-url", "--push", "--all", "origin")):
            if self.text(*args).splitlines() != [self.remote]:
                raise ValueError("Origin fetch/push URL differs from the configured remote")


def begin(repo, owner):
    lock(repo.root, owner)
    try:
        repo.check()
        repo.clean()
        (repo.root / ".wiki-write.lock/head").write_text(repo.text("rev-parse", "HEAD"))
    except BaseException:
        unlock(repo.root, owner)
        raise


def finish(repo, owner, message, paths):
    require_owner(repo.root, owner)
    repo.check()
    baseline = (repo.root / ".wiki-write.lock/head").read_text()
    if repo.text("rev-parse", "HEAD") != baseline:
        raise ValueError("HEAD changed since begin; retain the lock and review the update")
    if not message.strip() or "\n" in message or message.startswith("-"):
        raise ValueError("Supply a nonempty, single-line commit subject")
    selected = set()
    for name in paths:
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] in (".git", ".wiki-write.lock"):
            raise ValueError(f"Not a wiki content path: {name}")
        selected.add(path.as_posix())
    changed = repo.changes()
    if not changed:
        unlock(repo.root, owner)
        return "No changes; no commit created"
    if not changed.issubset(selected):
        raise ValueError("Changed files omitted from the update: " + ", ".join(sorted(changed - selected)))
    # Stage only actual changed files, never a directory/glob or unrelated content.
    repo.git("--literal-pathspecs", "add", "--", *sorted(changed))
    repo.git("commit", "-m", message)
    repo.clean()
    commit = repo.text("rev-parse", "HEAD")
    unlock(repo.root, owner)
    return f"Committed {commit}"


def sync_status(repo, status, detail):
    path = repo.root / ".git/personal-wiki-sync.json"
    try:
        previous = json.loads(path.read_text()) if path.exists() else {}
    except json.JSONDecodeError:
        previous = {}
    now = datetime.now(timezone.utc).isoformat()
    record = dict(attemptedAt=now, status=status, detail=detail,
                  lastSuccessAt=now if status == "ok" else previous.get("lastSuccessAt"))
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(record, indent=2) + "\n")
    temporary.replace(path)


def sync(repo):
    owner = "sync-" + uuid.uuid4().hex
    try:
        lock(repo.root, owner)
    except FileExistsError:
        return "Skipped: another wiki writer holds the lock"
    checked = False
    try:
        repo.check()
        checked = True
        repo.check_remote()
        repo.clean()
        target = f"refs/remotes/origin/{repo.branch}"
        repo.git("fetch", "--no-tags", "origin", f"+refs/heads/{repo.branch}:{target}")
        local = repo.text("rev-parse", "HEAD")
        remote = repo.text("rev-parse", target)
        if local == remote:
            result = "Already synchronized"
        elif repo.git("merge-base", "--is-ancestor", local, remote, allowed=(0, 1)).returncode == 0:
            repo.git("merge", "--ff-only", target)
            repo.clean()
            result = "Fast-forwarded incoming commits"
        elif repo.git("merge-base", "--is-ancestor", remote, local, allowed=(0, 1)).returncode == 0:
            repo.clean()
            if repo.text("rev-parse", "HEAD") != local:
                raise ValueError("HEAD changed during sync")
            repo.check_remote()
            repo.git("push", "--porcelain", "--no-follow-tags", "--recurse-submodules=no",
                     "origin", f"{local}:refs/heads/{repo.branch}")
            result = "Pushed committed updates"
        else:
            raise ValueError("Local and remote histories diverged; manual resolution required")
        sync_status(repo, "ok", result)
        return result
    except Exception as error:
        if checked:
            sync_status(repo, "error", str(error))
        raise
    finally:
        unlock(repo.root, owner)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--template", type=Path, required=True)
    parser.add_argument("--git", default="git", help="Git executable supplied by Nix")
    sub = parser.add_subparsers(dest="command", required=True)
    for command in ("config", "path", "bootstrap", "sync", "sync-status"):
        sub.add_parser(command)
    for command in ("lock", "unlock", "begin"):
        sub.add_parser(command).add_argument("owner", help="unique owner token retained by this chat")
    complete = sub.add_parser("finish")
    complete.add_argument("owner")
    complete.add_argument("--message", "-m", required=True)
    complete.add_argument("paths", nargs="+", help="Exact relative files belonging to this update")
    args = parser.parse_args()
    settings = json.loads(args.config.read_text())
    root = Path(settings["path"])
    repo = Repository(settings, args.git)
    if args.command == "config":
        print(json.dumps(settings, indent=2))
    elif args.command == "path":
        print(root)
    elif args.command == "bootstrap":
        bootstrap(root, args.template)
        print(f"Wiki scaffold ready at {root}; existing files preserved. Git is not initialized or synced.")
    elif args.command == "sync":
        print(sync(repo))
    elif args.command == "sync-status":
        path = repo.root / ".git/personal-wiki-sync.json"
        print(path.read_text() if path.exists() else "No sync result recorded yet")
    else:
        if not args.owner.strip() or "\n" in args.owner:
            raise ValueError("Use a nonempty, single-line owner token")
        if args.command == "begin":
            begin(repo, args.owner)
        elif args.command == "finish":
            print(finish(repo, args.owner, args.message, args.paths))
        else:
            {"lock": lock, "unlock": unlock}[args.command](root, args.owner)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        sys.exit(f"personal-wiki: {error}")
