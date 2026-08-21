{ pkgs, lib, ... }:
{
  # Desktop: Homebrew cask `cursor` on Darwin, nixpkgs `code-cursor` on Linux.
  # CLI: Homebrew cask `cursor-cli` on Darwin, nixpkgs `cursor-cli` on Linux.
  # Both CLIs ship `cursor-agent`; official docs also use `agent`.
  home.packages =
    lib.optionals pkgs.stdenv.isLinux [ pkgs.cursor-cli ]
    ++ [
      (pkgs.writeShellScriptBin "agent" ''
        set -euo pipefail
        if command -v cursor-agent >/dev/null 2>&1; then
          exec cursor-agent "$@"
        fi
        echo "cursor-agent not found; install the Cursor CLI" >&2
        exit 127
      '')
    ];
}
