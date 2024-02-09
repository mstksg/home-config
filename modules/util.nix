{ pkgs, ... }:
{
  formatJson = buildInputs: cmd: body:
    let jsonFile = pkgs.writeTextDir "file.json" (builtins.toJSON body);
    in pkgs.runCommand "formatJson"
      { inherit buildInputs; }
      ''
        cat ${jsonFile}/file.json | ${cmd} > $out
      '';
}
