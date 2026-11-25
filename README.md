# nix-dotfiles

Home Manager profiles, user programs, and themes for Nick Wade.

## Flake interface

This flake exports `homeManagerModules.desktop`, `cli`, `mvm`, and `rex`.
The consuming machine flake supplies each account's username and home directory.
The Rex module imports the pinned upstream Rex module together with its local configuration.
This repository does not depend on `nix-hosts` or employer configuration.

[nix-hosts](https://github.com/ncwade/nix-hosts) assembles complete machines and enables optional integrations per host. It makes this flake follow its Nixpkgs input so both repositories use the same package revision.

## Development

Keep `nix-dotfiles` beside `nix-hosts` and stage new source files before evaluating a Git checkout:

```console
python3 -B -m unittest discover -s tests -p 'test_*.py'
cd ../nix-hosts
nix flake check --no-build --all-systems --no-write-lock-file \
  --override-input nix-dotfiles path:../nix-dotfiles
```

After committing and pushing changes here, run `nix flake update nix-dotfiles` in `nix-hosts`, validate, and commit its lock file. Builds and activation run through `nix-hosts`.

## History

Relevant file history was extracted from the cleaned `ncwade/nix-config` branches as of `679e37ce806288f07c390ba6848e2a6f50ddf781`.
Commits touching only machine files were omitted, and surviving commit IDs changed during extraction. License and ignore-file history are shared with `nix-hosts`.
No old pull-request references or editor checkpoints were imported. The unrelated older `ncwade/nix-home` repository is not an input to this migration.
