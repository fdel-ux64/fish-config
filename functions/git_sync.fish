function git_sync
    # --- DEFAULT CONFIG ---
    set DEFAULT_REPO ~/git/REPO
    set REMOTE origin

    # --- REPO SELECTION ---
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

    # --- EXPAND ~ AND NORMALIZE PATH ---
    set REPO_DIR (string replace -r '^~' $HOME $REPO_DIR)
    set REPO_DIR (realpath $REPO_DIR)

    # --- VALIDATE REPO ---
    if not test -d $REPO_DIR
        echo "❌ Repo directory not found: $REPO_DIR"
        return 1
    end

    # --- OFFER TO SAVE AS DEFAULT ---
    if test "$ASK_SAVE" = "yes"
        read --prompt-str "💾 Make this repo the default for future runs? (y/n): " save_repo
        if test "$save_repo" = "y"
            # Persistently update DEFAULT_REPO
            functions -c git_sync __git_sync_tmp

            functions __git_sync_tmp | \
                sed "s|set DEFAULT_REPO .*|set DEFAULT_REPO $REPO_DIR|" | \
                functions --save git_sync

            functions -e __git_sync_tmp
            echo "✅ Default repo updated to $REPO_DIR"
        end
    end

    # --- GO TO REPO ---
    cd $REPO_DIR
    echo "📂 Repo: "(pwd)

    # --- ENSURE GIT REPO ---
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "❌ Not a git repository"
        return 1
    end

    # --- SHOW STATUS ---
    echo "📊 Git status:"
    git status --short --branch

    # --- ABORT IF MODIFIED (IGNORE UNTRACKED FILES) ---
    set dirty (git status --porcelain --untracked-files=no | string trim)
    if test -n "$dirty"
        echo "⚠️  Modified or staged files detected. Commit or stash first."
        echo "$dirty"
        return 1
    end

    # --- BRANCH DETECTION ---
    set BRANCH (git symbolic-ref --short HEAD 2>/dev/null)
    if test -z "$BRANCH"
        set BRANCH main
    end

    # --- GIT PULL ---
    read --prompt-str "🔄 Pull with rebase from $REMOTE/$BRANCH? (y/n): " sync_answer
    if test "$sync_answer" = "y"
        git pull --rebase $REMOTE $BRANCH
        or begin
            echo "❌ git pull failed"
            return 1
        end
    end

    # --- ADD / COMMIT ---
    read --prompt-str "➕ Add & commit files? (y/n): " add_answer
    if test "$add_answer" = "y"
        # Prompt for files to add (with default '.')
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

        # --- PUSH ---
        read --prompt-str "🚀 Push to $REMOTE/$BRANCH? (y/n): " push_answer
        if test "$push_answer" = "y"
            git push $REMOTE $BRANCH
            or begin
                echo "❌ git push failed"
                return 1
            end
        end
    end

    echo "✅ git_sync complete"
end
