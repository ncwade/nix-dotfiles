set -x VIRTUAL_ENV_DISABLE_PROMPT 1
set -g theme_display_git_default_branch yes
export SSH_AUTH_SOCK=(gpgconf --list-dirs agent-ssh-socket)
gpg-connect-agent /bye
#set -g theme_git_default_branches master main
#set -g theme_git_worktree_support yes
set -g theme_display_k8s_context yes
set -g theme_display_k8s_namespace yes
set -g theme_newline_cursor yes

if test -e ~/.asdf/asdf.fish
    source ~/.asdf/asdf.fish
    if ! test -e ~/.asdf/completions/asdf.fish
        mkdir -p ~/.config/fish/completions; and ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
    end
    if ! test -e ~/.tool-versions
        asdf plugin add python
        asdf install python 3.10.1
        asdf global python 3.10.1
    end
end

direnv hook fish | source
alias nvim "direnv exec / nvim"
set -x GOPRIVATE "github.com/gdcorp-*,github.secureserver.net"
fish_add_path -m ~/.local/bin
alias ssh="kitty +kitten ssh"

