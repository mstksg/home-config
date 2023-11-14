{ config, lib, pkgs, ... }: {
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

  config = {
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
    home.packages = [
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
      pkgs.lolcat
      pkgs.ncdu
      pkgs.nil
      pkgs.nixfmt
      pkgs.nodejs
      pkgs.ripgrep
      pkgs.sl
      pkgs.uptimed
      pkgs.wget
      pkgs.jump
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
        tmux = {
          autoStartRemote = true;
          itermIntegration = true;
        };
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
      };
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "vim";
      };
    };

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
      # terminal = "screen-256color";
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
      '';
    };

    programs.vim = {
      enable = true;
      defaultEditor = true;
      plugins = with pkgs.vimPlugins; [
        bufexplorer
        coc-explorer
        coc-nvim
        coc-fzf
        delimitMate
        fzf-vim
        syntastic
        tagbar
        vim-airline
        vim-airline-themes
        vim-colors-solarized
        vim-commentary
        vim-cool
        vim-endwise
        vim-eunuch
        vim-fugitive
        vim-gitgutter
        vim-indent-object
        vim-mundo
        vim-repeat
        vim-sensible
        vim-signature
        vim-startify
        vim-surround
        vim-tmux-navigator
        vim-unimpaired
        vim-wordmotion
      ];
      extraConfig = ''
        set encoding=utf-8

        set nobackup
        set nowritebackup

        set updatetime=300

        " display options
        syntax on
        set ruler
        set number
        set scrolloff=5
        set textwidth=78
        set signcolumn=yes
        set showmatch
        set nowrap
        set foldlevelstart=20
        set foldcolumn=1
        set foldmethod=syntax
        set t_Co=256
        set showcmd
        autocmd InsertEnter,InsertLeave * set cul!
        " match ErrorMsg '\%>80v.\+'
        set showbreak =\ ++\ \ \
        set linebreak
        colorscheme solarized

        if version >= 703
          set colorcolumn=+1
        endif

        set wildignore=*.o,*.swp,*.class,*.aux,*.dump-hi

        " keyboard options
        set expandtab
        set shiftwidth=4
        set softtabstop=4
        set tabstop=4
        set backspace=indent,eol,start
        set autoindent
        noremap  <Up> <nop>
        noremap! <Up> <Esc>
        noremap  <Down> <nop>
        noremap! <Down> <Esc>
        noremap  <Left> <nop>
        noremap! <Left> <Esc>
        noremap  <Right> <nop>
        noremap! <Right> <Esc>
        noremap  <Home> <nop>
        noremap! <Home> <Esc>
        noremap  <End> <nop>
        noremap! <End> <Esc>
        " noremap <Del> <nop>
        " noremap! <Del> <Esc>
        " noremap! <C_Del> <Del>
        nnoremap Q <nop>
        nnoremap K <nop>

        " commands

        " search options
        set ignorecase
        set smartcase
        set incsearch
        set hlsearch
        set showmatch

        " file options
        set autoread
        set hidden
        set history=1000
        set wildmenu
        set wildmode=list:longest,full
        set confirm

        " shortcuts
        noremap <F1> :BufExplorer<CR>
        " only if pandoc?
        " noremap <F2> :TOC<CR>
        noremap <F3> :NERDTreeToggle<CR><CR>
        noremap <F4> :MundoToggle<CR>
        noremap <F5> :!./%
        noremap <F6> :make<CR>
        noremap <F7> :setlocal spell! spelllang=en_us<CR>
        noremap <F8> :TagbarToggle<CR>
        " noremap <F9> :SignifyToggle<CR>
        noremap <F9> :GitGutterToggle<CR>
        noremap <F10> :SignatureToggle<CR>
        noremap <F11> :set list!<CR>:set list?<CR>
        noremap <F12> :set cursorline!<CR>:set cursorcolumn!<CR>
        " noremap <F12> :ls<CR>:b<SPACE>
        " autocmd CmdwinEnter * nnoremap <buffer> <cr> <cr>
        " autocmd FileType qf nnoremap <buffer> <cr> <cr>
        " noremap <leader>ev :e! ~/.vimrc<CR>
        noremap <leader>twr :normal gqip<CR>
        " noremap <leader>todo :vsp! ~/todo.txt<CR>
        " vmap <leader>sl "ry:call Send_to_Tmux(@r)<CR>
        " nmap <leader>sl vip<leader>sl
        " nmap <leader>p <A-p>
        " nmap <leader>P <A-P>
        " nmap <leader>p <Plug>yankstack_substitute_older_paste
        " nmap <leader>P <Plug>yankstack_substitute_newer_paste
        " noremap <leader>ys :Yanks<CR>
        " noremap <leader>so :so %<CR>
        noremap <leader>1 :b1<CR>
        noremap <leader>2 :b2<CR>
        noremap <leader>3 :b3<CR>
        noremap <leader>4 :b4<CR>
        noremap <leader>5 :b5<CR>
        noremap <leader>6 :b6<CR>
        noremap <leader>7 :b7<CR>
        noremap <leader>8 :b8<CR>
        noremap <leader>9 :b9<CR>
        noremap <leader>0 :b10<CR>
        noremap <leader>- :confirm bd<CR>
        noremap <leader>` :ls<CR>:b<SPACE>
        noremap <leader>ww :w<CR>
        noremap <leader>sp :set paste!<CR>:set paste?<CR>
        noremap <leader>be :BufExplorer<CR>
        " noremap <leader>bj :bn<CR>
        " noremap <leader>bk :bp<CR>
        " noremap <leader>wh :wincmd h<CR>
        " noremap <leader>wj :wincmd j<CR>
        " noremap <leader>wk :wincmd k<CR>
        " noremap <leader>wl :wincmd l<CR>
        " nnoremap <space><space> :<C-U>call InsertChar#insert(v:count1)<CR>
        inoremap <F1> <ESC>
        noremap Y y$
        " nnoremap <CR> :nohlsearch<CR>
        nnoremap <c-p> :FZF<CR>
        cabbrev wq w

        noremap <leader>tt :tn<CR>
        noremap <leader>tp :tN<CR>
        noremap <leader>ws :%s/\s\+$//<CR>:nohlsearch<CR>

        " plugin options
        let g:airline_theme='solarized'
        let g:airline_solarized_bg = 'dark'
        let g:airline_detect_whitespace = 2
        let g:airline_powerline_fonts = 1

        " coc.nvim
        " Use tab for trigger completion with characters ahead and navigate
        " NOTE: There's always complete item selected by default, you may want to enable
        " no select by `"suggest.noselect": true` in your configuration file
        " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
        " other plugin before putting this into your config
        inoremap <silent><expr> <TAB>
              \ coc#pum#visible() ? coc#pum#next(1) :
              \ CheckBackspace() ? "\<Tab>" :
              \ coc#refresh()
        inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

        " Make <CR> to accept selected completion item or notify coc.nvim to format
        " <C-g>u breaks current undo, please make your own choice
        inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                      \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

        function! CheckBackspace() abort
          let col = col('.') - 1
          return !col || getline('.')[col - 1]  =~# '\s'
        endfunction

        " Use <c-space> to trigger completion
        if has('nvim')
          inoremap <silent><expr> <c-space> coc#refresh()
        else
          inoremap <silent><expr> <c-@> coc#refresh()
        endif

        " Use `[g` and `]g` to navigate diagnostics
        " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
        nmap <silent> [g <Plug>(coc-diagnostic-prev)
        nmap <silent> ]g <Plug>(coc-diagnostic-next)

        " GoTo code navigation
        nmap <silent> gd <Plug>(coc-definition)
        nmap <silent> gy <Plug>(coc-type-definition)
        nmap <silent> gi <Plug>(coc-implementation)
        nmap <silent> gr <Plug>(coc-references)

        " Use K to show documentation in preview window
        nnoremap <silent> K :call ShowDocumentation()<CR>

        function! ShowDocumentation()
          if CocAction('hasProvider', 'hover')
            call CocActionAsync('doHover')
          else
            call feedkeys('K', 'in')
          endif
        endfunction

        " Highlight the symbol and its references when holding the cursor
        autocmd CursorHold * silent call CocActionAsync('highlight')

        " Symbol renaming
        nmap <leader>rn <Plug>(coc-rename)

        " Formatting selected code
        xmap <leader>f  <Plug>(coc-format-selected)
        nmap <leader>f  <Plug>(coc-format-selected)

        augroup mygroup
          autocmd!
          " Setup formatexpr specified filetype(s)
          autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
          " Update signature help on jump placeholder
          autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
        augroup end

        " Applying code actions to the selected code block
        " Example: `<leader>aap` for current paragraph
        xmap <leader>a  <Plug>(coc-codeaction-selected)
        nmap <leader>a  <Plug>(coc-codeaction-selected)

        " Remap keys for applying code actions at the cursor position
        nmap <leader>ac  <Plug>(coc-codeaction-cursor)
        " Remap keys for apply code actions affect whole buffer
        nmap <leader>as  <Plug>(coc-codeaction-source)
        " Apply the most preferred quickfix action to fix diagnostic on the current line
        nmap <leader>qf  <Plug>(coc-fix-current)

        " Remap keys for applying refactor code actions
        nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
        xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
        nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)

        " Run the Code Lens action on the current line
        nmap <leader>cl  <Plug>(coc-codelens-action)

        " Map function and class text objects
        " NOTE: Requires 'textDocument.documentSymbol' support from the language server
        xmap if <Plug>(coc-funcobj-i)
        omap if <Plug>(coc-funcobj-i)
        xmap af <Plug>(coc-funcobj-a)
        omap af <Plug>(coc-funcobj-a)
        xmap ic <Plug>(coc-classobj-i)
        omap ic <Plug>(coc-classobj-i)
        xmap ac <Plug>(coc-classobj-a)
        omap ac <Plug>(coc-classobj-a)

        " Remap <C-f> and <C-b> to scroll float windows/popups
        if has('nvim-0.4.0') || has('patch-8.2.0750')
          nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
          nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
          inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
          inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
          vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
          vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
        endif

        " Use CTRL-S for selections ranges
        " Requires 'textDocument/selectionRange' support of language server
        nmap <silent> <C-s> <Plug>(coc-range-select)
        xmap <silent> <C-s> <Plug>(coc-range-select)

        " Add `:Format` command to format current buffer
        command! -nargs=0 Format :call CocActionAsync('format')

        " Add `:Fold` command to fold current buffer
        command! -nargs=? Fold :call     CocAction('fold', <f-args>)

        " Add `:OR` command for organize imports of the current buffer
        command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

        " Add (Neo)Vim's native statusline support
        " NOTE: Please see `:h coc-status` for integrations with external plugins that
        " provide custom statusline: lightline.vim, vim-airline
        " set statusline^=%{coc#status()}%{get(b:,'coc_current_function',''')}
        set g:airline#extensions#coc#enabled = 1
        set g:airline#extensions#coc#show_coc_status = 1

        " Mappings for CoCList
        " Show all diagnostics
        nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
        " Manage extensions
        nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
        " Show commands
        nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
        " Find symbol of current document
        nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
        " Search workspace symbols
        nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
        " Do default action for next item
        nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
        " Do default action for previous item
        nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
        " Resume latest coc list
        nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
      '';
      settings = { background = "dark"; };
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
