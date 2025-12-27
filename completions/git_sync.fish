# Disable file completion by default
complete -c git_sync -f

# ---- Help flag ----
complete -c git_sync -s h -l help -d "Show help for git_sync"

# ---- Repository path completion ----
# Suggest directories containing a .git folder
function __git_sync_repo_paths
    for dir in ~/git/* ~/projects/*
        if test -d $dir/.git
            echo $dir
        end
    end
end

complete -c git_sync -n "not __fish_seen_subcommand_from" -a "(__git_sync_repo_paths)" -d "Repository path to sync"

# ---- Branch completion (optional for second arg if needed) ----
# This function lists branches in the selected repository
function __git_sync_branches
    set repo $argv[1]
    if test -d $repo/.git
        cd $repo
        git branch --format='%(refname:short)'
    end
end

# Example usage: second argument could be branch, but currently git_sync auto-detects branch
# If you later allow specifying a branch: uncomment this
# complete -c git_sync -n "__fish_seen_argument_from REPO_PATH" -a "(__git_sync_branches (commandline -co))" -d "Git branch"
