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

function clone-github-org --description 'Clone every accessible repository in a GitHub organization'
    if test (count $argv) -ne 1
        echo "Usage: clone-github-org <github-org>" >&2
        return 2
    end

    if not type -q gh
        echo "clone-github-org requires the GitHub CLI (gh)." >&2
        return 1
    end

    if not type -q git
        echo "clone-github-org requires git." >&2
        return 1
    end

    set -l org $argv[1]
    set -l repos (command gh api --paginate "orgs/$org/repos?type=all&per_page=100" --jq '.[] | [.visibility, .name, .ssh_url] | @tsv')
    set -l list_status $status
    if test $list_status -ne 0
        return $list_status
    end

    if test (count $repos) -eq 0
        echo "No accessible repositories found for $org." >&2
        return 0
    end

    set -l failed 0
    for repo in $repos
        set -l fields (string split \t -- "$repo")
        set -l visibility (string lower -- $fields[1])
        set -l name $fields[2]
        set -l ssh_url $fields[3]
        set -l destination "$org/$visibility/$name"

        if test -e "$destination"
            echo "Skipping $destination (already exists)"
            continue
        end

        mkdir -p "$org/$visibility"
        echo "Cloning $ssh_url -> $destination"
        if not command git clone "$ssh_url" "$destination"
            set failed (math $failed + 1)
        end
    end

    if test $failed -gt 0
        echo "$failed repository clone(s) failed." >&2
        return 1
    end
end

function update-github-repos --description 'Fast-forward pull every child GitHub repository'
    if test (count $argv) -ne 0
        echo "Usage: update-github-repos" >&2
        return 2
    end

    if not type -q git
        echo "update-github-repos requires git." >&2
        return 1
    end

    set -l git_dirs (command find . -type d -name .git -prune -print)
    if test (count $git_dirs) -eq 0
        echo "No child Git repositories found."
        return 0
    end

    set -l failed 0
    set -l updated 0
    for git_dir in $git_dirs
        set -l repo (dirname "$git_dir")
        set -l remote_url (command git -C "$repo" remote get-url origin 2>/dev/null)

        if not string match -qr '(^|[@/:])github\.com([/:]|$)' -- "$remote_url"
            continue
        end

        echo "Updating $repo"
        if command git -C "$repo" pull --ff-only
            set updated (math $updated + 1)
        else
            set failed (math $failed + 1)
        end
    end

    if test $updated -eq 0; and test $failed -eq 0
        echo "No child GitHub repositories found."
    end

    if test $failed -gt 0
        echo "$failed repository update(s) failed." >&2
        return 1
    end
end

function ghcr-login --description 'Authenticate Docker to GitHub Container Registry using gh'
    if test (count $argv) -ne 0
        echo "Usage: ghcr-login" >&2
        return 2
    end

    if not type -q gh
        echo "ghcr-login requires the GitHub CLI (gh)." >&2
        return 1
    end

    if not type -q docker
        echo "ghcr-login requires Docker." >&2
        return 1
    end

    set -l username (command gh api user --jq .login)
    set -l username_status $status
    if test $username_status -ne 0
        return $username_status
    end

    set -l token (command gh auth token)
    set -l token_status $status
    if test $token_status -ne 0
        return $token_status
    end

    printf '%s\n' "$token" | command docker login ghcr.io --username "$username" --password-stdin
end

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
