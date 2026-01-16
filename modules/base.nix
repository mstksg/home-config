{ config, lib, pkgs, ... }:
let
  checkPlatform = p: builtins.elem pkgs.system p.meta.platforms;
  util = (import ./util.nix) { inherit pkgs; };
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
    autoTmux = lib.mkOption {
      type = lib.types.bool;
      description = "Whether or not to automatically enter a persistent tmux session on a new shell. set $NO_TMUX to bypass";
      default = false;
    };
    extraTmuxWindows = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Extra tmux windows to load on the default pane, in tmuxp format";
      default = [ ];
    };
    gpgSignKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Require gpg signing for this key (email) for git and other relevant places.";
      default = null;
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
      home.packages = with pkgs; builtins.filter checkPlatform [
        # rogue
        binutils
        cachix
        cmatrix
        csvlens
        fastfetch
        file
        fx
        fzf
        git-crypt
        glances
        hexyl
        jq
        killall
        lolcat
        miniserve
        ncdu
        nix-inspect
        nix-prefetch-git
        nix-tree
        nixfmt-classic
        nixpkgs-fmt
        nodejs
        pv
        ripgrep
        sl
        tldr
        tree
        unzip
        w3m
        wcalc
        wget
        zip
      ] ++
      [
        (pkgs.writeShellScriptBin "tmuxp-default" ''
          [[ -t 0 ]] && [[ -z $NO_TMUX ]] && [[ -z $TMUX ]] && tmuxp load --yes default
        '')
        (pkgs.writeShellScriptBin "y" ''
          echo "y not?"
        '')
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

        ".haskeline".text = ''
          maxHistorySize: Nothing
          historyDuplicates: IgnoreConsecutive
          editMode: Vi
        '';
      };
      xdg.configFile."tmuxp/default.yaml".source =
        util.formatJson [ pkgs.yq ] "yq -y"
          {
            session_name = "default";
            windows = [
              { window_name = "htop"; panes = [ "glances" ]; }
            ] ++ config.extraTmuxWindows ++ [
              { window_name = "welcome"; panes = [ "cmatrix -ab" ]; focus = true; }
            ];
          };
      programs.fzf = {
        enable = true;
        tmux.enableShellIntegration = false;
      };

      programs.zsh = {
        enable = true;
        history = { size = 1000000; };

        zplug = {
          enable = true;
          plugins = [{ name = "jeffreytse/zsh-vi-mode"; }];
        };

        prezto = {
          enable = true;
          ssh.identities = [ "id_ed25519" ];
          prompt = {
            pwdLength = "short";
            showReturnVal = true;
            theme = "clint";
          };
          utility.safeOps = true;
        };

        initContent = lib.mkBefore ''
          ${lib.strings.optionalString config.autoTmux ''
            [[ -o interactive ]] && [[ -z $NO_TMUX ]] && tmuxp-default
          ''}
        '';
      };

      programs.fish = {
        enable = true;
        shellInit = ''
          fish_vi_key_bindings
          set fish_greeting
          # fish_config theme choose "Solarized Dark"
          ${lib.strings.optionalString config.autoTmux ''
          if not set -q NO_TMUX and status --is-interactive
            tmuxp-default
          end
          ''}
        '';

        plugins = [
          {
            name = "bass";
            src = pkgs.fetchFromGitHub {
              owner = "edc";
              repo = "bass";
              rev = "79b62958ecf4e87334f24d6743e5766475bcf4d0";
              sha256 = "sha256-3d/qL+hovNA4VMWZ0n1L+dSM1lcz7P5CQJyy+/8exTc=";
            };
          }
        ];
      };

      programs.bash = {
        enable = true;
        shellAliases = { };
        historySize = 1000000;
        historyControl = [ "ignoredups" "ignorespace" ];
        initExtra = ''
          set -o vi

          ${lib.strings.optionalString config.autoTmux ''
            # TODO: make this be ignored when scp
            [[ $- == *i* ]] && [[ -z $NO_TMUX ]] && tmuxp-default
          ''}
        '';
      };

      programs.readline = {
        enable = true;
        variables = {
          editing-mode = "vi";
        };
      };

      programs.bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
        # config = {
        #   theme = "Solarized (dark)";
        # };
      };

      programs.git = {
        enable = true;
        lfs.enable = true;
        signing = {
          key = config.gpgSignKey;
          signByDefault = config.gpgSignKey != null;
        };
        settings = {
          user = {
            name = config.user;
            email = config.email;
          };
          alias = {
            st = "status";
            lg = "log --oneline --abbrev-commit --all --graph --decorate --color";
            sha = "rev-parse HEAD";
            last = "log -1 HEAD --stat";
            commit-now = "!git commit -m $(date --iso-8601=seconds)";
          };
          init.defaultBranch = "main";
          core.editor = "vim";
          merge.conflictstyle = "diff3";
          diff.colorMoved = "default";
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          light = false;
          dark = true;
          side-by-side = false;
          line-numbers = true;
          features = "zebra-dark";
          # this isn't in the RTP for some reason so we clone it from
          # https://github.com/dandavison/delta/blob/main/themes.gitconfig
          zebra-dark = {
            minus-style = "syntax \"#330f0f\"";
            minus-emph-style = "syntax \"#4f1917\"";
            plus-style = "syntax \"#0e2f19\"";
            plus-emph-style = "syntax \"#174525\"";
            map-styles = ''
              bold purple => syntax "#330f29",
              bold blue => syntax "#271344",
              bold cyan => syntax "#0d3531",
              bold yellow => syntax "#222f14"
            '';
            zero-style = "syntax";
            whitespace-error-style = "#aaaaaa";
          };
        };
      };

      programs.gh = {
        enable = true;
        gitCredentialHelper.hosts = [
          "https://github.com"
        ];
        # Workaround for https://github.com/nix-community/home-manager/issues/4744
        settings.version = 1;
      };

      programs.eza = {
        enable = true;
        git = true;
      };

      programs.gh-dash.enable = true;

      programs.autojump.enable = true;

      programs.tmux = {
        enable = true;
        prefix = "C-a";
        baseIndex = 0;
        newSession = false;
        escapeTime = 0;
        secureSocket = false;
        keyMode = "vi";
        aggressiveResize = true;
        historyLimit = 250000;
        terminal = "xterm-256color";
        shell = "${pkgs.fish}/bin/fish";
        tmuxp.enable = true;
        plugins = with pkgs.tmuxPlugins; [
          # cpu
          # tmux-powerline
          fuzzback
        ];
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
          # set -g status-right "#{sysstat_cpu} | #{sysstat_mem} | #{sysstat_swap} | #{sysstat_loadavg} | #[fg=cyan]#(echo $USER)#[default]@#H"
          set -g status-right "#[fg=green]#H #[fg=default]| #[fg=cyan]%b %d %R"

          set-window-option -g window-status-style dim
          set-window-option -g window-status-current-style bright

          setw -g monitor-activity on
          set -g visual-activity on

          set -ga terminal-overrides ',*256col*:Tc'
        '';
      };

      programs.nix-index.enable = true;

      programs.gpg.enable = true;

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      programs.starship.enable = true;

      services.ssh-agent.enable = pkgs.stdenv.hostPlatform.isLinux;

        services.gpg-agent = {
          enable = pkgs.stdenv.hostPlatform.isLinux;
          defaultCacheTtl = 259200;
          defaultCacheTtlSsh = 259200;
          pinentry.package = pkgs.pinentry-curses;
        };

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
