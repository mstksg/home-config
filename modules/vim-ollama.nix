{ config, pkgs, lib, ... }:
let
  cfg = config.vim-ollama;
  pythonEnv = pkgs.python3.withPackages (ps:
    [ ps.httpx ps.requests ps.jinja2 ] ++ lib.optional cfg.openai ps.openai);
  vim-ollama = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-ollama";
    version = "1.3.0-unstable-2026-10-10";
    src = pkgs.fetchFromGitHub {
      owner = "gergap";
      repo = "vim-ollama";
      rev = "c352598b663e8910b3f87a66d5c062ec275c866d";
      hash = "sha256-hpJMnoYXJMw4oEog2aOawySlHN4tItioYcIhIDrlmOE=";
    };
    doCheck = false;
    meta.homepage = "https://github.com/gergap/vim-ollama";
  };
in
{
  options.vim-ollama = {
    enable = lib.mkEnableOption "vim-ollama";
    host = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:11434";
    };
    code-model = lib.mkOption {
      type = lib.types.str;
      default = "qwen2.5-coder:7b";
    };
    edit-model = lib.mkOption {
      type = lib.types.str;
      default = "qwen3-coder:30b";
    };
    chat-model = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.5:9b";
    };
    openai = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vim.plugins = [ vim-ollama ];
    programs.vim.extraConfig = ''
      let $PYTHONPATH = "${pythonEnv}/${pkgs.python3.sitePackages}"
    '';

    home.file.".vim/config/ollama.vim".text = ''
      let g:ollama_use_venv = 0
      let g:ollama_python_interpreter = '${pythonEnv}/bin/python3'

      let g:ollama_host = '${cfg.host}'
      let g:ollama_model = '${cfg.code-model}'
      let g:ollama_context_lines = 512
      let g:ollama_model_options = { 'num_predict': 256 }

      let g:ollama_chat_model = '${cfg.chat-model}'
      let g:ollama_chat_options = {}
      let g:ollama_chat_systemprompt = 'Give concise, opinionated feedback, but do not criticize harshly.'

      let g:ollama_edit_model = '${cfg.edit-model}'

      let g:ollama_bwrap_command = '${pkgs.bubblewrap}/bin/bwrap'
      let g:ollama_bwrap_enabled = 1

      let g:ollama_logfile = '/tmp/logs/vim-ollama.log'
      let g:ollama_review_logfile = '/tmp/logs/vim-ollama-review.log'
    '';
  };
}
