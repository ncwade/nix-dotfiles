# Authorized personal-wiki automation

The user has authorized `personal-wiki begin` / `finish` to inspect and commit
each requested wiki update, and `personal-wiki sync` to fetch, fast-forward, and
push committed updates periodically to the configured origin/branch. These
helper operations do not require repeated Git approval. The exception applies
only to the canonical wiki configured in `personal-wiki config`, using its
write lock and repository/remote checks. It does not authorize arbitrary Git
commands, other repositories, repository creation, changes to remotes or Git
settings, rebases, conflict resolution, or force pushes. Filesystem and network
permissions still apply. See the `personal-wiki` skill for the transaction flow.
