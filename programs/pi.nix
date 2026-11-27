{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pi;
  jsonFormat = pkgs.formats.json { };

  apertureConfig =
    lib.optionalAttrs (cfg.apertureBaseUrl != "") {
      baseUrl = cfg.apertureBaseUrl;
    }
    // {
      version = "0.18.0";
      onboardingDone = cfg.apertureBaseUrl != "";
      dedicated = {
        enabled = true;
        providers = [ ];
      };
      mcp = {
        enabled = false;
      };
    };

  settingsConfig =
    {
      "$schema" = "https://pi.dev/schemas/settings.schema.json";
      defaultProvider = "aperture";
      theme = cfg.theme;
      npmCommand = [ "${pkgs.nodejs}/bin/npm" ];
      packages = [ cfg.aperturePackage ];
    }
    // lib.optionalAttrs (cfg.defaultModel != null) {
      defaultModel = cfg.defaultModel;
    }
    // lib.optionalAttrs cfg.enableCodemode {
      defaultTools = [ "+codemode" ];
      codemode = {
        mode = "on";
      };
    };

  agentsMd = ''
    # Pi Agent Instructions

    - Keep changes minimal, direct, and verified with the relevant checks.
    - Prefer Pi's `/tree` session branching and navigation over spawning sub-agents or multi-agent frameworks.
    - Use shared skills in `~/.agents/skills/` when relevant:
      - `/skill:tech-spec` for concise, code-shaped specifications before larger edits.
      - `/skill:rex` when inspecting or controlling sibling panes, tabs, or dev servers inside Rex.
    - Respect project-local `AGENTS.md` and `.agents/skills/` when present.
  '';

  piAgentDir = "${config.home.homeDirectory}/.pi/agent";
  aperturePkgMarker = "${piAgentDir}/npm/node_modules/@aliou/pi-ts-aperture/package.json";
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent";

    package = lib.mkPackageOption pkgs "pi-coding-agent" { };

    apertureBaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Base URL of the Tailscale Aperture gateway written to
        ~/.pi/agent/extensions/aperture.json. When empty, baseUrl is omitted so
        APERTURE_BASE_URL or /aperture:onboarding can supply it at runtime.
      '';
    };

    defaultModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Default model ID under defaultProvider written to
        ~/.pi/agent/settings.json (e.g. "tycho/inkling-2-mini").
      '';
    };

    enableCodemode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable Pi Codemode by adding "+codemode" to defaultTools and setting
        codemode.mode = "on".
      '';
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "system";
      description = ''
        Pi TUI theme name. Built-in options are "system" (inherits the
        terminal palette), "dark", and "light"; custom themes require a JSON
        file under ~/.pi/agent/themes/.
      '';
    };

    aperturePackage = lib.mkOption {
      type = lib.types.str;
      default = "npm:@aliou/pi-ts-aperture";
      description = "Pi package spec for the Tailscale Aperture extension.";
    };

    manageRexSkill = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Manage ~/.agents/skills/rex/SKILL.md declaratively via home.file.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.apertureBaseUrl == ""
          || (
            (lib.hasPrefix "http://" cfg.apertureBaseUrl || lib.hasPrefix "https://" cfg.apertureBaseUrl)
            && !(lib.hasSuffix "/" cfg.apertureBaseUrl)
          );
        message = "programs.pi.apertureBaseUrl must be empty or an http(s) URL without a trailing slash.";
      }
    ];

    home.packages = [ cfg.package ];

    # Manage only individual files so ~/.pi/agent/ remains writable for sessions,
    # cached model catalogs, and npm-installed extension packages.
    home.file = {
      ".pi/agent/extensions/aperture.json".source =
        jsonFormat.generate "pi-aperture.json" apertureConfig;
      ".pi/agent/settings.json".source =
        jsonFormat.generate "pi-settings.json" settingsConfig;
      ".pi/agent/AGENTS.md".text = agentsMd;
      ".agents/skills/tech-spec/SKILL.md".source = ../skills/tech-spec/SKILL.md;
      ".agents/skills/rex/SKILL.md" = lib.mkIf cfg.manageRexSkill {
        source = ../skills/rex/SKILL.md;
      };
    };

    home.activation.installPiAperture = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${piAgentDir}/extensions"}
      if [ ! -f ${lib.escapeShellArg aperturePkgMarker} ]; then
        PATH="${lib.makeBinPath [ cfg.package pkgs.nodejs pkgs.git pkgs.coreutils ]}:$PATH"
        if ! $DRY_RUN_CMD ${cfg.package}/bin/pi update --extensions; then
          echo "warning: unable to install ${cfg.aperturePackage} (offline?); run 'pi update --extensions' once online" >&2
        fi
      fi
    '';
  };
}
