set -x VIRTUAL_ENV_DISABLE_PROMPT 1
set -g theme_display_k8s_context yes
set -g theme_display_k8s_namespace yes
set -g theme_newline_cursor yes

if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
else if test -d /nix/var/nix/profiles/default/bin
    fish_add_path /nix/var/nix/profiles/default/bin
end

if test -d $HOME/.nix-profile/bin
    fish_add_path $HOME/.nix-profile/bin
end

if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

if type -q direnv
    direnv hook fish | source
    alias nvim "direnv exec / nvim"
end

fish_add_path $HOME/.local/bin

alias cdr="cd \$(git rev-parse --show-toplevel)"

set --export POETRY_VIRTUALENVS_IN_PROJECT "true"
if test (uname -m) = arm64
    set --export TGENV_ARCH "arm64"
end
if test -S ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
    set --export SSH_AUTH_SOCK ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
end
set --export EDITOR nvim

for file in ~/.local/configs/fish/*
    if test -f $file
        source $file
    end
end

if type -q starship
    starship init fish | source
end

if type -q mise
    if set -q MVM_MISE_HOOK_ON_PWD
        # mvm sets this before config.fish is sourced. `mise activate` normally
        # evaluates hook-env before every prompt; on a VirtioFS mount that can
        # dominate prompt latency. Keep mise's full environment support, but
        # update it when PWD changes instead.
        mise activate --no-hook-env fish | source

        function __mvm_mise_hook_env --on-variable PWD --description 'Update mise environment after directory changes'
            command mise hook-env -s fish | source
        end

        __mvm_mise_hook_env
    else
        mise activate fish | source
    end
end
