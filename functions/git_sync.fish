function git_sync --description "Synchronize a Git repository: pull, add, commit, and push interactively"
    set -l DEFAULT_REPO ~/git/REPO
    set -l REMOTE origin
    set -l REPO_DIR
    set -l ASK_SAVE yes

    # ---- Help flag ----
    if contains -- $argv[1] "-h" "--help"
        echo "git_sync — interactively sync a git repository"
        echo
        echo "USAGE:"
        echo "  git_sync [REPO_PATH]"
        echo
        echo "If REPO_PATH is not provided, uses the default repo."
        echo "Prompts for pull, add, commit, and push interactively."
        return 0
    end

    # ---- Select repository ----
    if test (count $argv) -ge 1
        set REPO_DIR $argv[1]
        set ASK_SAVE yes
    else if test -d $DEFAULT_REPO
        set REPO_DIR $DEFAULT_REPO
        set ASK_SAVE no
    else
        read --prompt-str "📁 Default repo not found. Enter repo path: " REPO_DIR
        set ASK_SAVE yes
    end

    # ---- Normalize path ----
    set REPO_DIR (string replace -r '^~' $HOME $REPO_DIR)
    set REPO_DIR (realpath $REPO_DIR)

    # ---- Validate repo ----
    if not test -d $REPO_DIR
        echo "❌ Repo directory not found: $REPO_DIR"
        return 1
    end

    # ---- Offer to save as default ----
    if test "$ASK_SAVE" = "yes"
        read --prompt-str "💾 Make this repo the default for future runs? (y/N): " save_repo
        if string match -qr '^(y|Y)$' "$save_repo"
            # Persistently update DEFAULT_REPO
            functions -c git_sync __git_sync_tmp
            functions __git_sync_tmp | string replace -r 'set DEFAULT_REPO .*' "set DEFAULT_REPO $REPO_DIR" | functions --save git_sync
            functions -e __git_sync_tmp
            echo "✅ Default repo updated to $REPO_DIR"
        end
    end

    cd $REPO_DIR
    echo "📂 Repo: "(pwd)

    # ---- Ensure git repo ----
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "❌ Not a git repository"
        return 1
    end

    # ---- Show status ----
    echo "📊 Git status:"
    git status --short --branch

    # ---- Abort if modified (ignore untracked) ----
    set -l dirty (git status --porcelain --untracked-files=no | string trim)
    if test -n "$dirty"
        echo "⚠️  Modified or staged files detected. Commit or stash first."
        echo "$dirty"
        return 1
    end

    # ---- Detect branch ----
    set -l BRANCH (git symbolic-ref --short HEAD 2>/dev/null)
    if test -z "$BRANCH"
        set BRANCH main
    end

    # ---- Git pull ----
    read --prompt-str "🔄 Pull with rebase from $REMOTE/$BRANCH? (y/N): " sync_answer
    if string match -qr '^(y|Y)$' "$sync_answer"
        git pull --rebase $REMOTE $BRANCH
        or begin
            echo "❌ git pull failed"
            return 1
        end
    end

    # ---- Add / Commit / Push ----
    read --prompt-str "➕ Add & commit files? (y/N): " add_answer
    if string match -qr '^(y|Y)$' "$add_answer"
        # Prompt for files to add
        read --prompt-str "➕ Enter files to add (space-separated) or '.' for all: " files_to_add
        if test -z "$files_to_add"
            set files_to_add .
        end

        git add $files_to_add
        or begin
            echo "❌ git add failed"
            return 1
        end

        # Commit message
        read --prompt-str "✏️  Commit message: " commit_msg
        if test -z "$commit_msg"
            echo "❌ Commit message cannot be empty"
            return 1
        end

        git commit -m "$commit_msg"
        or begin
            echo "❌ git commit failed"
            return 1
        end

        # Push
        read --prompt-str "🚀 Push to $REMOTE/$BRANCH? (y/N): " push_answer
        if string match -qr '^(y|Y)$' "$push_answer"
            git push $REMOTE $BRANCH
            or begin
                echo "❌ git push failed"
                return 1
            end
        end
    end

    echo "✅ git_sync complete"
end
