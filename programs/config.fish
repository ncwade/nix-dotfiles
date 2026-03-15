set -x VIRTUAL_ENV_DISABLE_PROMPT 1
set -g theme_display_k8s_context yes
set -g theme_display_k8s_namespace yes
set -g theme_newline_cursor yes

/opt/homebrew/bin/brew shellenv | source
direnv hook fish | source
alias nvim "direnv exec / nvim"
fish_add_path $HOME/.local/bin

alias cdr="cd \$(git rev-parse --show-toplevel)"

set --export POETRY_VIRTUALENVS_IN_PROJECT "true"
set --export TGENV_ARCH "arm64"
set --export SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
set --export EDITOR nvim

for file in ~/.local/configs/fish/*
    if test -f $file
        source $file
    end
end

starship init fish | source
mise activate fish | source
