{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    tmuxinator = {
      enable = true;
      projects."uds-fleet-dev" = {
        name = "uds-fleet-dev";
        root = "~/src/github.com/work-org/internal/uds-fleet-command";
        startup_window = "Fleet Command";
        enable_pane_titles = true;
        pane_title_position = "bottom";
        windows = [
          {
            "Fleet Command" = {
              layout = "main-vertical";
              panes = [
                {
                  "Fleet bootstrap + UI" = ''
                    tmux set-option -p @workspace_label 'Fleet bootstrap + UI'; and mise trust; and mise install; and uds run dev-cluster --no-progress; and uds run setup:create-keycloak-user --no-progress; and uds run api:create-automation-client --no-progress; and uds run setup:ui-proxy-file --no-progress; and tmux wait-for -S uds-fleet-command-ready; and uds run dev:ui --no-progress
                  '';
                }
                {
                  "Fleet controls" = "tmux set-option -p @workspace_label 'Fleet controls'; and echo 'Fleet Command control shell: restart the package with uds run dev:package-restart --no-progress'";
                }
              ];
            };
          }
          {
            "Remote Agent" = {
              root = "~/src/github.com/work-org/internal/uds-remote-agent";
              layout = "main-vertical";
              panes = [
                {
                  "Local Agent" = ''
                    tmux set-option -p @workspace_label 'Local Agent'; and echo 'Waiting for Fleet Command setup…'; and tmux wait-for uds-fleet-command-ready; and mise trust; and mise install; and printf '%s\n' 'features:' '  fleet:' '    enabled: true' '  allowInsecureTLS:' '    enabled: true' > /tmp/uds-remote-agent-fleet.yaml; and uds run dev:run-local-agent --set INSECURE=true --with config_file=/tmp/uds-remote-agent-fleet.yaml --no-progress
                  '';
                }
                {
                  "Agent controls" = "tmux set-option -p @workspace_label 'Agent controls'; and echo 'Local Agent control shell: stop the agent with Ctrl-C, then rerun dev:run-local-agent'";
                }
              ];
            };
          }
          {
            Operations = {
              layout = "even-horizontal";
              panes = [
                {
                  "Command API" = "tmux set-option -p @workspace_label 'Command API'; and echo 'Create an enrollment token: uds run api:create-enrollment-token --with expires_at=2027-01-01T00:00:00Z --no-progress'";
                }
                {
                  "Agent CLI" = "tmux set-option -p @workspace_label 'Agent CLI'; and cd ~/src/github.com/work-org/internal/uds-remote-agent; and echo 'Remote Agent control shell: run uds run build:client --no-progress before enrollment'";
                }
              ];
            };
          }
        ];
      };
    };
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
          set -g @catppuccin_application_text " #W"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
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

      # Keep Tmuxinator's descriptive window names while processes run.
      set -g automatic-rename off
      set -g allow-rename off

      # Display stable per-pane labels rather than shell-generated command titles.
      set -g pane-border-status top
      set -g pane-border-format ' #{?@workspace_label,#{@workspace_label},#{pane_title}} '
    '';
  };
}
