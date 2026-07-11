{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell =
      if pkgs.stdenv.isDarwin
      then "/run/current-system/sw/bin/fish"
      else "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    prefix = "C-s";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"

          set -g @catppuccin_status_user "on"
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_user} #{E:@catppuccin_status_application} #{E:@catppuccin_status_session}"
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ga terminal-overrides ",xterm-256color:RGB"

      # Reload config
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Vim-style pane navigation
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # Status bar position
      set-option -g status-position top
      set -g status-style bg=default
    '';
  };
}
