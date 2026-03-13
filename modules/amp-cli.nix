{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.amp-cli;
  jsonFormat = pkgs.formats.json { };
  managedSkillsPath = "${config.xdg.configHome}/amp/skills";
  configuredSkillsPath =
    let
      value = lib.attrByPath [ "amp.skills.path" ] null cfg.settings;
    in
    if builtins.isString value then value else null;
  mergedSkillsPath = lib.concatStringsSep ":" (
    lib.filter (path: path != "") [
      (lib.optionalString (cfg.skills != { }) managedSkillsPath)
      (lib.optionalString (configuredSkillsPath != null) configuredSkillsPath)
    ]
  );
  mergedSettings =
    (lib.removeAttrs cfg.settings [ "amp.skills.path" ])
    // lib.optionalAttrs (cfg.mcpServers != { }) {
      "amp.mcpServers" = cfg.mcpServers;
    }
    // lib.optionalAttrs (mergedSkillsPath != "") {
      "amp.skills.path" = mergedSkillsPath;
    };
in
{
  options.programs.amp-cli = {
    enable = lib.mkEnableOption "Amp, Sourcegraph's agentic coding CLI";

    package = lib.mkPackageOption pkgs "amp-cli" { nullable = true; };

    pluginMode = lib.mkOption {
      type = lib.types.enum [
        "off"
        "all"
      ];
      default = "off";
      description = ''
        Controls Amp plugin loading via the `PLUGINS` environment variable.
        Set to `all` to enable plugins from `.amp/plugins` and
        `~/.config/amp/plugins`.
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        JSON configuration for Amp CLI settings.json.
        Settings are written to {file}`~/.config/amp/settings.json`.
        All settings use the `amp.` prefix.
        See <https://ampcode.com/manual> for supported values.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = ''
        MCP (Model Context Protocol) servers configuration.
        Merged into settings under the `amp.mcpServers` key.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Amp skills to install under {file}`~/.config/amp/skills`.
        Skill names are used as directory names and merged into
        `amp.skills.path` automatically.
      '';
    };

    agentConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = ''
        Global agent instructions written to
        {file}`~/.config/amp/AGENTS.md`.
      '';
    };

    agentConfigSource = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/Users/alice/.config/amp/AGENTS.private.md";
      description = ''
        Absolute path to an existing AGENTS.md file outside the Nix store.
        This is useful for keeping private instructions out of the dotfiles
        repository. If set, this takes precedence over `agentConfig`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.agentConfig != null && cfg.agentConfigSource != null);
        message = "programs.amp-cli: set either agentConfig or agentConfigSource, not both.";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    home.sessionVariables = lib.mkIf (cfg.pluginMode != "off") {
      PLUGINS = cfg.pluginMode;
    };

    xdg.configFile =
      {
        "amp/settings.json" = lib.mkIf (mergedSettings != { }) {
          source = jsonFormat.generate "amp-cli-settings.json" mergedSettings;
        };

        "amp/AGENTS.md" = lib.mkIf (cfg.agentConfig != null || cfg.agentConfigSource != null) (
          if cfg.agentConfigSource != null then
            {
              source = config.lib.file.mkOutOfStoreSymlink cfg.agentConfigSource;
            }
          else
            {
              text = cfg.agentConfig;
            }
        );
      }
      // lib.mapAttrs' (name: path: lib.nameValuePair "amp/skills/${name}" { source = path; }) cfg.skills;
  };
}
