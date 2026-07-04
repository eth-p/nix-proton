nix-proton:
{
  lib,
  config,
  ...
}:
let
  cfg = config.protonfixes;
  protonfix = (import ../lib/nix/protonfix.nix) { inherit lib; };
  localfixOptionName = appid: "protonfixes.localfixes.app.${lib.strings.escapeNixIdentifier appid}";
in
{
  options.protonfixes.localfixes = {
    enable = lib.mkEnableOption "Create local protonfixes";
    app = lib.mkOption {
      type = lib.types.attrsOf protonfix.type;
      description = "Local protonfixes applied to games.";
      default = { };
    };
  };

  config = lib.mkMerge [
    # Protonfixes local fixes:
    # https://github.com/Open-Wine-Components/umu-protonfixes/blob/c8d30ae16c28aee7d8a7fee0c5094861e9f1a4b8/README.md#local-fixes
    (lib.mkIf cfg.localfixes.enable (
      let
        fileForLocalfix = appid: "protonfixes/localfixes/${appid}.py";

        # A list of attrsets describing localfix aliases as symlinks.
        localfixesAliasesList = lib.lists.flatten (
          lib.attrsets.mapAttrsToList (
            appid: fix:
            lib.lists.map (alias: {
              inherit alias;
              source = appid;
            }) (protonfix.aliasesOf fix)
          ) cfg.localfixes.app
        );

        # Left-fold op for merging the localfixesAliasesList into an attrset.
        # mergeLocalfixAliasIntoAttrset :: attrset -> protonfix -> attrset
        mergeLocalfixAliasIntoAttrset =
          acc:
          { alias, source }:
          builtins.addErrorContext "while evaluating aliases of ``${localfixOptionName acc.${source}}'" (
            if lib.attrsets.hasAttr alias acc then
              throw "`${localfixOptionName acc.${alias}}' already defines an alias for ${alias}"
            else if lib.attrsets.hasAttr alias (cfg.localfixes.app) then
              throw "`${localfixOptionName alias}' already exists as a localfix"
            else
              acc
              // {
                ${alias} = source;
              }
          );

        # A map of localfix aliases, with the aliased appid as the key and original appid as the value.
        localfixesAliasesMap = lib.lists.foldl' mergeLocalfixAliasIntoAttrset { } localfixesAliasesList;

        # An `xdg.configFile` attrset of generated localfix scripts.
        localfixesFiles = lib.attrsets.mapAttrs' (appid: fix: {
          name = fileForLocalfix appid;
          value = {
            text = protonfix.generateProtonfix fix;
          };
        }) cfg.localfixes.app;

        # An `xdg.configFile` attrset of aliased localfix scripts.
        localfixesAliases = lib.attrsets.mapAttrs' (linkAppid: fixAppid: {
          name = fileForLocalfix linkAppid;
          value = localfixesFiles.${fileForLocalfix fixAppid};
        }) localfixesAliasesMap;

      in
      {
        xdg.configFile = localfixesFiles // localfixesAliases;
      }
    ))
  ];
}
