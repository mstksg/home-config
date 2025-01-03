{ pkgs, ... }:
let
  util = (import ./util.nix) { inherit pkgs; };
  simplePlugin = name: body: pkgs.vimUtils.buildVimPlugin {
    inherit name;
    src = pkgs.writeTextDir "plugin/${name}.vim" body;
  };
  utilPlugins = {
    vimfile-locations = simplePlugin "vimfile-locations" ''
      " Save your backups to a less annoying place than the current directory.
      " If you have .vim-backup in the current directory, it'll use that.
      " Otherwise it saves it to ~/._vim/backup or . if all else fails.
      if isdirectory($HOME . '/._vim/backup') == 0
        :silent !mkdir -p ~/._vim/backup >/dev/null 2>&1
      endif
      set backupdir-=.
      set backupdir+=.
      set backupdir-=~/
      set backupdir^=~/._vim/backup/
      set backupdir^=./.vim-backup/
      set backup

      " Save your swp files to a less annoying place than the current directory.
      " If you have .vim-swap in the current directory, it'll use that.
      " Otherwise it saves it to ~/._vim/swap, ~/tmp or .
      if isdirectory($HOME . '/._vim/swap') == 0
        :silent !mkdir -p ~/._vim/swap >/dev/null 2>&1
      endif
      set directory=./.vim-swap//
      set directory+=~/._vim/swap//
      set directory+=~/tmp//
      set directory+=.

      " viminfo stores the the state of your previous editing session
      set viminfo+=n~/._vim/viminfo

      if exists("+undofile")
        " undofile - This allows you to use undos after exiting and restarting
        " This, like swap and backups, uses .vim-undo first, then ~/._vim/undo
        " :help undo-persistence
        " This is only present in 7.3+
        if isdirectory($HOME . '/._vim/undo') == 0
          :silent !mkdir -p ~/._vim/undo > /dev/null 2>&1
        endif
        set undodir=./.vim-undo//
        set undodir+=~/._vim/undo//
        set undofile
      endif
    '';
    coc-bindings = simplePlugin "coc-bindings" ''
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
      let g:airline#extensions#coc#enabled = 1
      let g:airline#extensions#coc#show_coc_status = 1

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
      nnoremap <silent><nowait> <space>e  <Cmd>CocCommand explorer<CR>

      " by filetype
      autocmd FileType markdown let b:coc_enabled = 0
      autocmd FileType pandoc let b:coc_suggest_disable = 1

      " codeLens text
      hi CocCodeLens term=bold cterm=italic ctermfg=242 gui=italic guifg=#555555
    '';
  };
  vim-mql5 = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-mql5";
    version = "2015-10-27";
    src = pkgs.fetchFromGitHub {
      owner = "rupurt";
      repo = "vim-mql5";
      rev = "6ccfa51f3643a45e2b457fee0f9aac3c37dfc8bd";
      sha256 = "sha256-WKB5m8fJXoONtZFe2Xgm1xn+vsnPCcaRMeY7bQiBaTk=";
    };
    meta.homepage = "https://github.com/rupurt/vim-mql5";
  };
in
{
  config = {
    home.packages = [
      (pkgs.writeShellScriptBin "haskell-language-server-wrapper-2" ''
        if command -v haskell-language-server &> /dev/null
        then
          haskell-language-server "$@"
        elif command -v haskell-language-server-wrapper &> /dev/null
        then
          haskell-language-server-wrapper "$@"
        else
          echo "Neither haskell-language-server nor haskell-language-server-wrapper found."
          exit 1
        fi
      '')
      pkgs.dhall-lsp-server
      pkgs.haskellPackages.cabal-fmt
      pkgs.haskellPackages.fourmolu
      pkgs.nil
      pkgs.nodePackages.bash-language-server
      pkgs.nodePackages.prettier
      pkgs.ormolu
      pkgs.shfmt
    ];
    xdg.configFile."fourmolu.yaml".source = util.formatJson [ pkgs.yq ] "yq -y"
      {
        indentation = 2;
        column-limit = 100;
        function-arrows = "trailing";
        comma-style = "leading";
        import-export-style = "diff-friendly";
        indent-wheres = true;
        record-break-space = true;
        newlines-between-decls = 1;
        haddock-style = "single-line";
        haddock-style-module = null;
        let-style = "inline";
        in-style = "right-align";
        single-constraint-parens = "never";
        unicode = "detect";
        respectful = true;
        fixities = [ ];
        reexports = [ ];
      };
    home.file = {
      ".vim/coc-settings.json".source = util.formatJson [ pkgs.jq ] "jq"
        {
          coc.preferences.enableLinkedEditing = true;
          colors.enable = true;
          codeLens = {
            enable = true;
          };
          diagnostic = {
            checkCurrentLine = true;
            floatConfig = {
              border = true;
              rounded = true;
            };
            format = "%message [%source]";
            separateRelatedInformationAsDiagnostics = true;
            virtualText = true;
          };
          git.addGBlameToVirtualText = true;
          semanticTokens = {
            enable = true;
            filetypes = [ "c" "cpp" "haskell" "nix" "purescript" "dhall" "bash" ];
          };
          languageserver = {
            haskell = {
              command = "haskell-language-server-wrapper-2";
              args = [ "--lsp" ];
              rootPatterns = [ "*.cabal" "stack.yaml" "cabal.project" "package.yaml" "hie.yaml" ];
              filetypes = [ "haskell" "lhaskell" ];
              settings = {
                haskell = {
                  formattingProvider = "fourmolu";
                  plugin.fourmolu.config.external = true;
                };
              };
            };
            nix = {
              command = "nil";
              filetypes = [ "nix" ];
              rootPatterns = [ "flake.nix" ];
              settings = {
                nil = {
                  formatting = { command = [ "nixpkgs-fmt" ]; };
                };
              };
            };
            purescript = {
              command = "purescript-language-server";
              args = [ "--stdio" ];
              filetypes = [ "purescript" ];
              "trace.server" = "off";
              rootPatterns = [ "bower.json" "psc-package.json" "spago.dhall" "spago.yaml" ];
              settings = {
                purescript = {
                  addSpagoSources = true;
                  addNpmPath = false;
                  formatter = "purs-tidy";
                };
              };
            };
            dhall = {
              command = "dhall-lsp-server";
              filetypes = [ "dhall" ];
            };
            bash = {
              command = "bash-language-server";
              args = [ "start" ];
              filetypes = [ "sh" ];
              ignoredRootPaths = [ "~" ];
            };
          };
        };
    };
    programs.vim =
      {
        enable = true;
        defaultEditor = true;
        settings = { background = "dark"; };
        plugins = with pkgs.vimPlugins; [
          NrrwRgn
          awesome-vim-colorschemes
          bufexplorer
          coc-clangd
          coc-explorer
          coc-fzf
          coc-git
          coc-nvim
          delimitMate
          dhall-vim
          fzf-vim
          haskell-vim
          purescript-vim
          syntastic
          tagbar
          utilPlugins.coc-bindings
          utilPlugins.vimfile-locations
          vim-airline
          vim-airline-themes
          vim-commentary
          vim-cool
          vim-endwise
          vim-eunuch
          vim-fugitive
          vim-gitgutter
          vim-indent-object
          vim-ledger
          vim-mql5
          vim-mundo
          vim-pandoc
          vim-pandoc-after
          vim-pandoc-syntax
          vim-pug
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
          set t_Co=256
          set termguicolors

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
          set relativenumber
          autocmd InsertEnter,InsertLeave * set cul!
          " match ErrorMsg '\%>80v.\+'
          set showbreak =\ ++\ \ \
          set linebreak
          " colorscheme orange-moon
          " colorscheme atom
          " colorscheme sorbet
          " colorscheme OceanicNext
          colorscheme solarized8

          if version >= 703
            set colorcolumn=+1
          endif

          set wildignore=*.o,*.swp,*.class,*.aux,*.dump-hi

          " keyboard options
          set expandtab
          set shiftwidth=2
          set softtabstop=2
          set tabstop=2
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
          " noremap  <CR> <nop>
          " noremap! <CR> <Esc>
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
          " noremap <F3> :NERDTreeToggle<CR><CR>
          nmap <F3> <Cmd>CocCommand explorer<CR>
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
          noremap <leader>time "=strftime("%Y/%m/%d %H:%M:%S")<CR>p
          command! Shuffle :sort /.*\%6v/

          command! ToggleTabs :setlocal et!

          command! Tabs :setlocal noet sts=8 ts=8 sw=8
          command! Tabs4 :setlocal noet sts=4 ts=4 sw=4
          command! FourSpaces :setlocal et sts=4 ts=4 sw=4
          command! TwoSpaces :setlocal et sts=4 ts=4 sw=2

          function! s:Underline(chars)
            let chars = empty(a:chars) ? '-' : a:chars
            let nr_columns = virtcol('$') - 1
            let uline = repeat(chars, (nr_columns / len(chars)) + 1)
            put =strpart(uline, 0, nr_columns)
          endfunction
          command! -nargs=? Underline call s:Underline(<q-args>)

          " plugin options
          let g:airline_theme='solarized'
          let g:airline_solarized_bg = 'dark'
          let g:airline_detect_whitespace = 2
          let g:airline_powerline_fonts = 0

          let g:pandoc#formatting#mode='h'

          autocmd FileType ledger setlocal commentstring=;\ %s
          autocmd FileType cabal setlocal foldmethod=indent
        '';
      };
  };
}
