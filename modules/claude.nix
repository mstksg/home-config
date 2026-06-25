{ config, pkgs, lib, ... }:
let
  cfg = config.jle.claude;
  jq = "${pkgs.jq}/bin/jq";
  hlint = "${pkgs.hlint}/bin/hlint";
  hookDir = "${config.homePath}/.claude/hooks";

  substituteHook = file: substitutions:
    builtins.replaceStrings
      (map (s: s.from) substitutions)
      (map (s: s.to) substitutions)
      (builtins.readFile file);
in
{
  options.jle.claude = {
    enable = lib.mkEnableOption "Claude Code settings and hooks";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = null;

      settings = {
        awsAuthRefresh = "aws-sso-refresh";
        env = {
          ANTHROPIC_MODEL = "us.anthropic.claude-opus-4-6-v1";
          ANTHROPIC_SMALL_FAST_MODEL = "us.anthropic.claude-opus-4-6-v1";
          CLAUDE_CODE_SUBAGENT_MODEL = "us.anthropic.claude-opus-4-6-v1";
          ANTHROPIC_DEFAULT_SONNET_MODEL = "us.anthropic.claude-opus-4-6-v1";
          ANTHROPIC_DEFAULT_HAIKU_MODEL = "us.anthropic.claude-opus-4-6-v1";
          AWS_PROFILE = "bedrock.commercial";
          AWS_REGION = "us-west-2";
          CLAUDE_CODE_ENABLE_TELEMETRY = "1";
          CLAUDE_CODE_USE_BEDROCK = "1";
          OTEL_EXPORTER_OTLP_ENDPOINT = "https://armory.anduril.dev";
          OTEL_EXPORTER_OTLP_PROTOCOL = "http/json";
          OTEL_LOGS_EXPORTER = "otlp";
          OTEL_LOGS_EXPORT_INTERVAL = "5000";
          OTEL_METRICS_EXPORTER = "otlp";
          OTEL_METRIC_EXPORT_INTERVAL = "10000";
          CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
          OTEL_RESOURCE_ATTRIBUTES = "user_name=jle";
        };
        permissions = {
          allow = [
            "mcp__claude-notes__get"
            "mcp__claude-notes__get_cell"
            "mcp__claude-notes__list_cells"
            "mcp__claude-notes__list_notebooks"
            "mcp__claude-notes__validate"
          ];
          bash.allow = [
            "nix build*"
            "nix build* |*"
            "nix build* 2>&1*"
            "nix run*"
            "nix run* |*"
            "nix run* 2>&1*"
            "nix-shell*"
            "nix-build*"
            "nix eval*"
            "nix flake*"
            "nix develop*"
            "treefmt*"
            "gh*"
            "git*"
            "grep*"
            "rg*"
            "sed*"
            "awk*"
            "head*"
            "tail*"
            "cat*"
            "ls*"
            "pwd*"
            "cd*"
            "find*"
            "file*"
            "stat*"
            "du*"
            "df*"
            "wc*"
            "which*"
            "whereis*"
            "tree*"
            "less*"
            "more*"
            "echo*"
            "claude-relay serve*"
            "claude-relay invite*"
            "claude-relay revoke*"
            "claude-relay token*"
            "claude-relay register*"
            "claude-relay notify*"
            "claude-relay poll*"
            "claude-relay mark-read*"
            "claude-relay close*"
            "claude-relay request*"
            "claude-relay request-close*"
          ];
        };
        hooks = {
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${hookDir}/check-bash.sh";
                }
              ];
            }
            {
              matcher = "Edit|Write";
              hooks = [
                {
                  type = "command";
                  command = "${hookDir}/check-hlint.sh";
                }
                {
                  type = "command";
                  command = "${hookDir}/check-blacklist.sh";
                }
                {
                  type = "command";
                  command = "${hookDir}/check-let-where.sh";
                }
                {
                  type = "command";
                  command = "${hookDir}/check-em-dash.sh";
                }
              ];
            }
          ];
          Stop = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "${hookDir}/check-response.sh";
                }
              ];
            }
          ];
        };
        enabledPlugins = {
          "clangd-lsp@claude-plugins-official" = true;
          "slack-cli@anduril-claude-clams" = true;
        };
        extraKnownMarketplaces = {
          anduril-claude-clams = {
            source = {
              source = "git";
              url = "git@ghe.anduril.dev:anduril/claude-clams.git";
            };
          };
        };
        skipWebFetchPreflight = true;
        skipDangerousModePermissionPrompt = true;
        mcpServers = {
          claude-notes = {
            command = "claude-notes-mcp";
          };
        };
        allowedPrompts = [
          { tool = "Bash"; prompt = "build the project"; }
          { tool = "Bash"; prompt = "format code"; }
          { tool = "Bash"; prompt = "run tests"; }
          { tool = "Bash"; prompt = "check build status"; }
          { tool = "Bash"; prompt = "git add, git continuing to rebase or merge"; }
          { tool = "Bash"; prompt = "lint files and code"; }
          { tool = "Bash"; prompt = "search for patterns"; }
          { tool = "Bash"; prompt = "Get counts or investigate file contents"; }
        ];
      };

    };

    home.file = {
      ".claude/hooks/check-bash.sh" = {
        executable = true;
        source = ../hooks/check-bash.sh;
      };
      ".claude/hooks/check-blacklist.sh" = {
        executable = true;
        text = substituteHook ../hooks/check-blacklist.sh [
          { from = "/home/jle/.nix-profile/bin/jq"; to = jq; }
        ];
      };
      ".claude/hooks/check-hlint.sh" = {
        executable = true;
        text = substituteHook ../hooks/check-hlint.sh [
          { from = "/home/jle/.nix-profile/bin/jq"; to = jq; }
          { from = "/home/jle/.nix-profile/bin/hlint"; to = hlint; }
          { from = "hook_dir=\"$(dirname \"$0\")\""; to = "hook_dir=\"${hookDir}\""; }
        ];
      };
      ".claude/hooks/check-let-where.sh" = {
        executable = true;
        text = substituteHook ../hooks/check-let-where.sh [
          { from = "/home/jle/.nix-profile/bin/jq"; to = jq; }
        ];
      };
      ".claude/hooks/check-em-dash.sh" = {
        executable = true;
        text = substituteHook ../hooks/check-em-dash.sh [
          { from = "/home/jle/.nix-profile/bin/jq"; to = jq; }
        ];
      };
      ".claude/hooks/check-response.sh" = {
        executable = true;
        source = ../hooks/check-response.sh;
      };
      ".claude/hooks/hlint.yaml".source = ../hooks/hlint.yaml;
    };
  };
}
