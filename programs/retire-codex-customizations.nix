{ lib, pkgs, ... }:
{
  # These were writable copies made by activation, outside home.file management.
  home.activation.retireCodexCustomizations = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    if [[ -n "''${oldGenPath:-}" ]]; then
      run ${pkgs.python3}/bin/python3 ${./retire-codex-customizations.py} "$oldGenPath"
    fi
  '';
}
