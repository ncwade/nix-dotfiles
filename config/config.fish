set -g theme_display_git_default_branch yes
export SSH_AUTH_SOCK=(gpgconf --list-dirs agent-ssh-socket)
gpg-connect-agent /bye
#set -g theme_git_default_branches master main
#set -g theme_git_worktree_support yes
