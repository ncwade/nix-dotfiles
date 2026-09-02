{ pkgs, ... }:
let
  cavemanSource = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "v2.4.0";
    hash = "sha256-KuOJYB+HH/vhQLEDOuHEETNUNtHSHdDuxvb5xFjk7Jc=";
  };
  cavemanSkills = [
    "cavecrew"
    "caveman"
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
in
{
  home.file =
    builtins.listToAttrs (map (skill: {
      name = ".codex/skills/${skill}";
      value = {
        source = "${cavemanSource}/skills/${skill}";
        recursive = true;
        force = true;
      };
    }) cavemanSkills)
    // {
      ".codex/skills/git-workflow" = {
        source = ../skills/git-workflow;
        recursive = true;
        force = true;
      };
    };
}
