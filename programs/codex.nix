{
  config,
  lib,
  pkgs,
  ...
}:
let
  cavemanSource = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "v2.4.0";
    hash = "sha256-KuOJYB+HH/vhQLEDOuHEETNUNtHSHdDuxvb5xFjk7Jc=";
  };
  adhdSource = pkgs.fetchFromGitHub {
    owner = "ayghri";
    repo = "i-have-adhd";
    rev = "6f1f982d0a47c65899af3c5a7450b7098bc65325";
    hash = "sha256-ijQ7Mz0FbeWxlkn7rbn5JuG0e6jQeEYBkuroE2N/MZY=";
  };
  cavemanSkills = [
    "cavecrew"
    "caveman-commit"
    "caveman-compress"
    "caveman-discover"
    "caveman-evidence-review"
    "caveman-explore"
    "caveman-help"
    "caveman-learn"
    "caveman-manage"
    "caveman-optimize"
    "caveman-review"
    "caveman-setup"
    "caveman-stats"
    "investigate-first"
    "lean-build"
    "migration"
    "safe-refactor"
    "surgical-patch"
    "verify-and-stop"
  ];
  skillRoot = "${config.home.homeDirectory}/.codex/skills";
  installSkill = name: source: ''
    $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync \
      --archive \
      --chmod=Du+w,Fu+w \
      --delete \
      ${lib.escapeShellArg "${source}/"} \
      ${lib.escapeShellArg "${skillRoot}/${name}/"}
  '';
in
{
  # Codex 0.153.x ignores skills whose SKILL.md is a symlink. Home Manager's
  # home.file creates symlinks, so copy these trees after it finishes linking.
  home.activation.installCodexSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg skillRoot}
    ${lib.concatMapStrings (
      skill: installSkill skill "${cavemanSource}/skills/${skill}"
    ) cavemanSkills}
    ${installSkill "i-have-adhd" "${adhdSource}/skills/i-have-adhd"}
    ${installSkill "git-workflow" ../skills/git-workflow}
  '';
}
