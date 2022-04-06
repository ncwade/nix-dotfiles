{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs; [
    ];

    extraConfig = builtins.readFile ./config/init.vim;
  };
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";

    plugins = with pkgs.tmuxPlugins; [
      {
       plugin = dracula;
       extraConfig = ''
          set -g @dracula-show-battery false
          set -g @dracula-show-powerline true
          set -g @dracula-refresh-rate 20
          set -g @dracula-show-left-icon 🚀
        '';
      }
    ];
    extraConfig = ''
      unbind '"'
      unbind %
      unbind M-j
      unbind M-k
      unbind M-h
      unbind M-l

      # Window Management
      bind | split-window -h
      bind - split-window -v
      bind-key -n C-S-Up resize-pane -U 10
      bind-key -n C-S-Down resize-pane -D 10
      bind-key -n C-S-Left resize-pane -L 10
      bind-key -n C-S-Right resize-pane -R 10

      # Movement
      bind k set-option -g status
      bind j set-option -g status
      bind h previous-window
      bind l next-window
      bind-key -n M-j select-pane -D
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-l select-pane -R

      # Utilities
      bind r source-file ~/.config/tmux/tmux.conf
    '';
  };
  programs.gpg = {
    enable = true;
  };
  programs.git = {
    enable = true;
    userName = "Nick Wade";
    userEmail = "me@ncwade.com";
    signing = {
      key = "8A892A4DCAB96A68";
      signByDefault = true;
    };
    extraConfig = {
      github.user = "ncwade";
      push.default = "simple";
      init.defaultBranch = "main";
      url."git@github-gdcorp:/gdcorp-infosec".insteadOf = "https://github.com/gdcorp-infosec";
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
  programs.fish = {
    enable = true;
    shellAliases = {
      pbcopy = "xclip";
      pbpaste = "xclip -o";
      nix-grub-clean = "sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch";
    };

    interactiveShellInit = builtins.readFile ./config/config.fish;

    plugins = [
      {
        name = "theme-bobthefish";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "theme-bobthefish";
          rev = "332f23abd7a095d5b2c024a061af7b890a4f0c20";
          sha256 = "0nhhc0d5z9k0srpalg7dv6zrls0qsw29bqp9vaajipcz53j7x6lf";
        };
      }
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
            owner = "jethrokuan";
            repo = "z";
            rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
            sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
        };
      }
      {
        name = "fish-fzf";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "6b592e4140168820f5df9dd28b0a93e409e0d0c3";
          sha256 = "1xzh5jwgilnk5rh7wywmzw1s084b2pilh0hvkfm5kyl37hmh0y3n";
        };
      }
    ];
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/ncwade.pub";
        identitiesOnly = true;
      };
      "github-gdcorp" = {
        hostname = "github.com";
        identityFile = "~/.ssh/nwade-previous-employer.pub";
        identitiesOnly = true;
      };
    };
  };

  home.packages = [
    pkgs.fzf
    pkgs.bat
    pkgs.direnv
    pkgs.htop
    pkgs.jq
    pkgs.xclip
    pkgs.ripgrep
  ];
}

