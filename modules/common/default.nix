{ config, lib, pkgs, ... }:
let
  vimUtils = (import ./vim.nix) { inherit pkgs; };
in
{
  options = {
    user = lib.mkOption {
      type = pkgs.lib.types.str;
      description = "Primary user of the system";
    };
    email = lib.mkOption {
      type = pkgs.lib.types.str;
      description = "Email of the user";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      description = "Human readable name of the user";
    };
    homePath = lib.mkOption {
      type = lib.types.path;
      description = "Path of user's home directory.";
      default = builtins.toPath (if pkgs.stdenv.isDarwin then
        "/Users/${config.user}"
      else
        "/home/${config.user}");
    };
  };

  config =
    {
      home.username = "${config.user}";
      home.homeDirectory = "${config.homePath}";
      # Home Manager needs a bit of information about you and the paths it should
      # manage.

      # This value determines the Home Manager release that your configuration is
      # compatible with. This helps avoid breakage when a new Home Manager release
      # introduces backwards incompatible changes.
      #
      # You should not change this value, even if you update Home Manager. If you do
      # want to update the value, then make sure to first check the Home Manager
      # release notes.
      home.stateVersion = "22.11"; # Please read the comment before changing.

      # The home.packages option allows you to install Nix packages into your
      # environment.
      home.packages = builtins.filter (p: builtins.elem pkgs.system p.meta.platforms) [
        # # Adds the 'hello' command to your environment. It prints a friendly
        # # "Hello, world!" when run.
        # pkgs.hello

        # # It is sometimes useful to fine-tune packages, for example, by applying
        # # overrides. You can do that directly here, just don't forget the
        # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
        # # fonts?
        # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

        # # You can also create simple shell scripts directly inside your
        # # configuration. For example, this adds a command 'my-hello' to your
        # # environment:
        # (pkgs.writeShellScriptBin "my-hello" ''
        #   echo "Hello, ${config.home.username}!"
        # '')

        pkgs.cachix
        pkgs.cmatrix
        pkgs.fzf
        pkgs.glances
        pkgs.haskell-language-server
        pkgs.jq
        pkgs.killall
        pkgs.lolcat
        pkgs.ncdu
        pkgs.nil
        pkgs.nixfmt
        pkgs.nixpkgs-fmt
        pkgs.nodejs
        pkgs.ripgrep
        pkgs.sl
        pkgs.tree
        pkgs.uptimed
        pkgs.wget
      ];

      # Home Manager is pretty good at managing dotfiles. The primary way to manage
      # plain files is through 'home.file'.
      home.file = {
        # # Building this configuration will create a copy of 'dotfiles/screenrc' in
        # # the Nix store. Activating the configuration will then make '~/.screenrc' a
        # # symlink to the Nix store copy.
        # ".screenrc".source = dotfiles/screenrc;

        # # You can also set the file content immediately.
        # ".gradle/gradle.properties".text = ''
        #   org.gradle.console=verbose
        #   org.gradle.daemon.idletimeout=3600000
        # '';
        ".vim/coc-settings.json".text = ''
          {
            "languageserver": {
              "haskell": {
                "command": "haskell-language-server-wrapper",
                "args": ["--lsp"],
                "rootPatterns": ["*.cabal", "stack.yaml", "cabal.project", "package.yaml", "hie.yaml"],
                "filetypes": ["haskell", "lhaskell"]
              },
              "nix": {
                "command": "nil",
                "filetypes": ["nix"],
                "rootPatterns": ["flake.nix"],
                "settings": {
                  "nil": {
                    "formatting": { "command": ["nixpkgs-fmt"] }
                  }
                }
              }
            }
          }
        '';
        ".haskeline".text = ''
          editMode: Vi
        '';
      };

      programs.fzf = {
        enable = true;
        tmux.enableShellIntegration = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
      };

      programs.zsh = {
        enable = true;
        shellAliases = { ll = "ls -al"; };
        history = { size = 1000000; };

        zplug = {
          enable = true;
          plugins = [{ name = "jeffreytse/zsh-vi-mode"; }];
        };

        prezto = {
          enable = true;
          ssh.identities = [ "id_ed25519" ];
          # tmux = {
          #   autoStartRemote = true;
          #   itermIntegration = true;
          # };
          prompt = {
            pwdLength = "short";
            showReturnVal = true;
            theme = "clint";
          };
          utility.safeOps = true;
        };
      };

      programs.bash = {
        enable = true;
        shellAliases = { ll = "ls -al"; };
        historySize = 1000000;
        historyControl = [ "ignoredups" "ignorespace" ];
        initExtra = ''
          set -o vi
        '';
      };

      programs.readline = {
        enable = true;
        extraConfig = ''
          set -o vi
        '';
      };

      programs.git = {
        enable = true;
        userName = "${config.user}";
        userEmail = "${config.email}";
        aliases = {
          st = "status";
          lg =
            "lg = log --oneline --abbrev-commit --all --graph --decorate --color";
          sha = "rev-parse HEAD";
        };
        extraConfig = {
          init.defaultBranch = "main";
          core.editor = "vim";
        };
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper.hosts = [
          "https://github.com"
        ];
      };

      programs.gh-dash.enable = true;

      programs.autojump.enable = true;

      programs.tmux = {
        enable = true;
        prefix = "C-a";
        baseIndex = 0;
        newSession = true;
        escapeTime = 0;
        secureSocket = false;
        keyMode = "vi";
        aggressiveResize = true;
        historyLimit = 250000;
        terminal = "xterm-256color";
        extraConfig = ''
          bind | split-window -h -c '#{pane_current_path}'
          bind - split-window -v -c '#{pane_current_path}'
          bind \\ split-window -h -c '#{pane_current_path}' \; resize-pane -R 30

          bind-key k select-pane -U
          bind-key j select-pane -D
          bind-key h select-pane -L
          bind-key l select-pane -R

          bind-key C-a last-window
          bind-key a send-prefix

          set -g status-justify left
          set -g status-bg black
          set -g status-fg white
          set -g status-left ""
          set -g status-right "#[fg=green]#H #[fg=default]| #[fg=cyan]%b %d %R"

          set-window-option -g window-status-style dim
          set-window-option -g window-status-current-style bright

          setw -g monitor-activity on
          set -g visual-activity on

          set -ga terminal-overrides ',*256col*:Tc'
        '';
      };

      programs.vim = vimUtils.vimConfig;

      # You can also manage environment variables but you will have to manually
      # source
      #
      #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      #
      # or
      #
      #  /etc/profiles/per-user/jle/etc/profile.d/hm-session-vars.sh
      #
      # if you don't want to manage your shell through Home Manager.
      home.sessionVariables = {
        # EDITOR = "vim";
      };

      nixpkgs.config.allowUnfreePredicate = _: true;

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    };
}
