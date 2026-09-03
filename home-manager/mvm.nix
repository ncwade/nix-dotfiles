{ config, lib, pkgs, ... }:

let
  starshipConfig = builtins.fromTOML (builtins.readFile ../programs/starship.toml);
  starshipMvmConfig = starshipConfig // {
    # Git's untracked-file scan over the VirtioFS project mount took ~0.5 s on
    # every prompt. Keep the branch module but omit the expensive status module.
    git_status = (starshipConfig.git_status or { }) // {
      disabled = true;
    };
  };
  starshipMvmToml = (pkgs.formats.toml { }).generate "starship-mvm.toml" starshipMvmConfig;
in
{
  imports = [
    ../programs/amp.nix
    ../programs/fish.nix
    ../programs/starship.nix
    ../programs/opencode.nix
    ../programs/tmux.nix
  ];

  home.username = "ncwade";
  # Lima gives the guest user a distinct home so it never collides with the
  # macOS home directory exposed through mounts.
  home.homeDirectory = "/home/ncwade.guest";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    POETRY_VIRTUALENVS_IN_PROJECT = "true";
  };

  xdg.configFile."starship-mvm.toml".source = starshipMvmToml;
  # MVM opens its shell through Lima, and remote tools often invoke Bash
  # directly. Make the Home Manager profile available even when Fish is bypassed.
  home.activation.ensureNixInMvmShells = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="/usr/bin:/bin:$PATH"

    for shell_file in "$HOME/.bashrc" "$HOME/.profile"; do
      touch "$shell_file"
      if ! grep -q 'mvm nix profile' "$shell_file"; then
        cat >>"$shell_file" <<'EOF'

# mvm nix profile
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
if [ -d "$HOME/.nix-profile/bin" ]; then
  export PATH="$HOME/.nix-profile/bin:$PATH"
fi
EOF
      fi
    done
  '';

  home.packages = with pkgs; [
    direnv
    fd
    fish
    git
    jq
    mise
    neovim
    nil
    nixd
    ripgrep
    starship
  ];

  # MVM's base shell setup is Bash-oriented. Keep the guest-specific bits in a
  # separate Fish config rather than mounting ~/.local/configs from the host:
  # that host directory contains credentials and must not enter a sandbox.
  xdg.configFile."fish/conf.d/mvm.fish".text = ''
    set --export STARSHIP_CONFIG "$HOME/.config/starship-mvm.toml"
    # Keep mise available, but let the common Fish config update its environment
    # only after directory changes rather than once per prompt.
    set --export MVM_MISE_HOOK_ON_PWD 1

    if test -d "$HOME/.opencode/bin"
        fish_add_path "$HOME/.opencode/bin"
    end

    set --export COREPACK_HOME "$HOME/.cache/corepack"

    if set -q TERM; and not infocmp "$TERM" >/dev/null 2>&1
        set --export TERM xterm-256color
    end
  '';

  home.activation.configureFishLoginShell = lib.hm.dag.entryAfter [ "installPackages" ] ''
    export PATH="/usr/bin:/bin:$PATH"

    fish_bin="${config.home.homeDirectory}/.nix-profile/bin/fish"

    if [ -x "$fish_bin" ]; then
      if ! grep -Fxq "$fish_bin" /etc/shells; then
        printf '%s\n' "$fish_bin" | /usr/bin/sudo tee -a /etc/shells >/dev/null
      fi

      current_shell="$(getent passwd "${config.home.username}" | cut -d: -f7)"
      if [ "$current_shell" != "$fish_bin" ]; then
        /usr/bin/sudo chsh -s "$fish_bin" "${config.home.username}"
      fi
    fi
  '';
}
