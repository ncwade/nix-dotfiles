{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell = "/run/current-system/sw/bin/fish";
    terminal = "tmux-256color";
    escapeTime = 0;
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    prefix = "C-a";

    extraConfig = ''
      # Catppuccin Mocha palette
      set -g @ctp_base "#1e1e2e"
      set -g @ctp_mantle "#181825"
      set -g @ctp_crust "#11111b"
      set -g @ctp_surface0 "#313244"
      set -g @ctp_surface1 "#45475a"
      set -g @ctp_surface2 "#585b70"
      set -g @ctp_overlay0 "#6c7086"
      set -g @ctp_overlay1 "#7f849c"
      set -g @ctp_text "#cdd6f4"
      set -g @ctp_subtext0 "#a6adc8"
      set -g @ctp_subtext1 "#bac2de"
      set -g @ctp_lavender "#b4befe"
      set -g @ctp_blue "#89b4fa"
      set -g @ctp_sapphire "#74c7ec"
      set -g @ctp_sky "#89dceb"
      set -g @ctp_teal "#94e2d5"
      set -g @ctp_green "#a6e3a1"
      set -g @ctp_yellow "#f9e2af"
      set -g @ctp_peach "#fab387"
      set -g @ctp_maroon "#eba0ac"
      set -g @ctp_red "#f38ba8"
      set -g @ctp_mauve "#cba6f7"
      set -g @ctp_pink "#f5c2e7"
      set -g @ctp_flamingo "#f2cdcd"
      set -g @ctp_rosewater "#f5e0dc"

      # True color support
      set -ga terminal-overrides ",xterm-256color:Tc"
      set -ga terminal-overrides ",tmux-256color:Tc"

      # Status bar styling (matching starship colors)
      set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
      set -g status-position bottom
      set -g status-justify left
      set -g status-left-length 100
      set -g status-right-length 100

      # Left side: session name (purple like starship username section)
      set -g status-left "#[bg=#9A348E,fg=#1e1e2e,bold] #S #[fg=#9A348E,bg=#1e1e2e]"

      # Right side: time with heart (matching starship)
      set -g status-right "#[fg=#33658A,bg=#1e1e2e]#[bg=#33658A,fg=#cdd6f4] ♥ %H:%M #[fg=#33658A,bg=#1e1e2e]"

      # Window tabs styling
      set -g window-status-format "#[fg=#1e1e2e,bg=#45475a]#[fg=#cdd6f4,bg=#45475a] #I #W #[fg=#45475a,bg=#1e1e2e]"
      set -g window-status-current-format "#[fg=#1e1e2e,bg=#DA627D]#[fg=#1e1e2e,bg=#DA627D,bold] #I #W #[fg=#DA627D,bg=#1e1e2e]"
      set -g window-status-separator " "

      # Pane borders
      set -g pane-border-style "fg=#45475a"
      set -g pane-active-border-style "fg=#DA627D"

      # Message styling
      set -g message-style "bg=#DA627D,fg=#1e1e2e"
      set -g message-command-style "bg=#45475a,fg=#cdd6f4"

      # Mode styling (copy mode, etc.)
      set -g mode-style "bg=#45475a,fg=#cdd6f4"

      # Clock mode
      set -g clock-mode-colour "#89b4fa"

      # Pane number display
      set -g display-panes-active-colour "#DA627D"
      set -g display-panes-colour "#45475a"

      # Better split bindings
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Vim-style pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes with vim keys
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Quick reload
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off
    '';
  };
}
