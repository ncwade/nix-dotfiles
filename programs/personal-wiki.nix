{ config, lib, pkgs, ... }:
let
  cfg = config.programs.personalWiki;
  codexHome = "${config.home.homeDirectory}/.codex";
  settingsPath = "${config.xdg.configHome}/personal-wiki/config.json";
  settings = pkgs.writeText "personal-wiki-config.json" (builtins.toJSON {
    inherit (cfg) path remote branch permissionProfile;
    inherit codexHome;
  });
  skill = pkgs.runCommand "personal-wiki-skill" { } ''
    cp -R ${../skills/personal-wiki} $out
    chmod -R u+w $out
    substituteInPlace $out/SKILL.md --replace-fail '@settingsPath@' ${lib.escapeShellArg settingsPath}
  '';
  command = pkgs.writeShellScriptBin "personal-wiki" ''
    exec ${pkgs.python3}/bin/python3 ${./personal-wiki/wiki.py} \
      --git ${pkgs.git}/bin/git \
      --config ${lib.escapeShellArg settingsPath} \
      --template ${skill}/assets/template "$@"
  '';
in
{
  options.programs.personalWiki = {
    enable = lib.mkEnableOption "a shared personal wiki for local Codex chats";
    path = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/knowledge/personal-wiki";
      description = "Absolute path to the mutable wiki checkout; changing it does not move data.";
    };
    remote = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Exact origin fetch/push URL authorized for wiki sync; null disables the scheduled job.";
    };
    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Local and remote branch authorized for wiki commits and sync.";
    };
    sync = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run a macOS user agent to sync committed wiki updates when a remote is configured.";
      };
      intervalSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 900;
        description = "Seconds between remote sync attempts while logged in (coalesced during sleep).";
      };
    };
    permissionProfile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "personal-wiki";
      description = ''
        Named profile extending :workspace with the wiki root. Selected as the
        default only when no default is already configured. Null leaves permission
        configuration untouched for managed clients or legacy sandbox setups.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.path && cfg.path != "/"
          && cfg.path != config.home.homeDirectory
          && !(lib.hasPrefix "/nix/store" cfg.path)
          && !(lib.hasInfix "/../" "${cfg.path}/")
          && !(lib.hasInfix "\n" cfg.path);
        message = "personalWiki.path must be an absolute, dedicated mutable directory.";
      }
      {
        assertion = cfg.permissionProfile == null
          || builtins.match "[a-z][a-z0-9-]*" cfg.permissionProfile != null;
        message = "personalWiki.permissionProfile must be null or a lowercase profile name.";
      }
    ];

    home.packages = [ command ];
    xdg.configFile."personal-wiki/config.json".source = settings;

    launchd.agents.personal-wiki-sync = lib.mkIf (cfg.sync.enable && cfg.remote != null) {
      enable = true;
      config = {
        ProgramArguments = [ "${command}/bin/personal-wiki" "sync" ];
        StartInterval = cfg.sync.intervalSeconds;
        RunAtLoad = true;
        ProcessType = "Background";
        LowPriorityIO = true;
        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
          PATH = "${lib.makeBinPath [ pkgs.git pkgs.openssh pkgs.gh ]}:/usr/bin:/bin";
        };
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/personal-wiki-sync.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/personal-wiki-sync.log";
      };
    };

    # Use the same regular-file discovery convention as programs/codex.nix.
    home.activation.installPersonalWiki = lib.hm.dag.entryAfter [ "installCodexSkills" ] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/Library/Logs"}
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${./personal-wiki/configure.py} ${settings}
      $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync --archive --chmod=Du+w,Fu+w --delete \
        ${skill}/ ${lib.escapeShellArg "${codexHome}/skills/personal-wiki/"}
    '';
  };
}
