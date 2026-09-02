---
name: git-workflow
description: Require explicit approval before any Git CLI command, and prepare concise Conventional Commits and repository-template-based pull requests.
---

# Git approval

Before running any command that invokes `git`, request the user's explicit approval for that command. This includes read-only commands such as `git status`, `git diff`, `git log`, and `git show`, as well as mutating commands. Do not combine an unapproved Git command with other shell commands.

Treat approval as limited to the specific Git command or closely grouped commands described in the approval request. A request to inspect the repository is not approval to commit, amend, rebase, push, or otherwise modify it.

# Commits

Use concise Conventional Commit subjects: `type(scope): imperative summary`. Choose the narrowest truthful type and scope; omit the scope when it adds no clarity. Keep the subject under 72 characters. Add a body only when it records material context not evident from the diff.

# Pull requests

Before drafting a PR description, look for a local template using repository files, including `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `PULL_REQUEST_TEMPLATE.md`, and templates under `.github/PULL_REQUEST_TEMPLATE/`.

When a template exists, retain its section headings and answer each section only with facts supported by the changes and validation performed. When no template exists, use a concise summary and tests section. Use a concise Conventional Commit-style PR title unless the repository specifies another convention.
