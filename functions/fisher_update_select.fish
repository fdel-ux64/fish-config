# Helper: prompt for confirmation
# Usage: __fisher_update_select_confirm <auto_yes> <prompt>
function __fisher_update_select_confirm
    if test "$argv[1]" -eq 1
        return 0
    end
    while true
        if not read -P "$argv[2] [y/N]: " resp
            echo "Aborted." >&2
            return 1
        end
        switch (string lower -- $resp)
            case y yes
                return 0
            case n no ''
                echo "Aborted."
                return 1
            case '*'
                echo "Please answer yes or no."
        end
    end
end

# Helper: find plugins matching a query string
# Match priority: exact full name -> owner-only ("owner/*") -> substring (case-insensitive)
# Usage: __fisher_update_select_find_matches <query> <plugin1> <plugin2> ...
function __fisher_update_select_find_matches
    set -l query $argv[1]
    set -l plugins $argv[2..-1]
    set -l matches

    # 1. exact match
    for p in $plugins
        if test "$p" = "$query"
            set matches $matches $p
        end
    end
    if test (count $matches) -gt 0
        printf '%s\n' $matches
        return
    end

    # 2. owner-only match (e.g. "fdel-ux64" -> "fdel-ux64/fish-config")
    for p in $plugins
        if string match -q -- "$query/*" $p
            set matches $matches $p
        end
    end
    if test (count $matches) -gt 0
        printf '%s\n' $matches
        return
    end

    # 3. substring match, case-insensitive, as a last resort
    for p in $plugins
        if string match -qi -- "*$query*" $p
            set matches $matches $p
        end
    end
    if test (count $matches) -gt 0
        printf '%s\n' $matches
    end
end

function fisher_update_select \
    --description "Selectively update Fisher plugins (interactive or scripted)"

    # --- flag parsing ---
    set -l do_all 0
    set -l auto_yes 0
    set -l queries

    for arg in $argv
        switch $arg
            case --help -h
                echo "Usage: fisher_update_select [--all] [--yes|-y] [plugin-name]"
                echo ""
                echo "Interactively select Fisher plugins to update, or update a"
                echo "specific plugin directly by name (full \"owner/repo\" or just"
                echo "\"owner\", as long as the match is unambiguous)."
                echo ""
                echo "Options:"
                echo "  --all        Update all plugins, skip interactive picker"
                echo "  --yes, -y    Skip confirmation prompts (works standalone too)"
                echo "  --help, -h   Show this help"
                return 0
            case --all
                set do_all 1
            case --yes -y
                set auto_yes 1
            case '--*'
                echo "Unknown flag: $arg" >&2
                return 2
            case '*'
                set queries $queries $arg
        end
    end

    # --- get plugin list ---
    set -l plugins (fisher list)
    set -l count_plugins (count $plugins)
    if test $count_plugins -eq 0
        echo "No plugins installed."
        return 0
    end

    # --- direct name/query match mode ---
    if test (count $queries) -gt 0 -a $do_all -eq 0
        set -l matched
        for q in $queries
            for m in (__fisher_update_select_find_matches $q $plugins)
                if not contains -- $m $matched
                    set matched $matched $m
                end
            end
        end

        switch (count $matched)
            case 0
                echo "No installed plugin matches: "(string join ', ' $queries) >&2
                echo "" >&2
                echo "Installed plugins:" >&2
                for p in $plugins
                    echo "  $p" >&2
                end
                return 1
            case 1
                set -l target $matched[1]
                if test $auto_yes -eq 1
                    echo "Updating: $target"
                else
                    if not __fisher_update_select_confirm $auto_yes "Update $target?"
                        return 0
                    end
                end
                fisher update $target
                return
            case '*'
                echo "Multiple plugins matched "(string join ', ' $queries)":"
                for m in $matched
                    echo "  - $m"
                end
                echo "Please refine your query, or run without arguments to pick interactively."
                return 1
        end
    end

    # --- all mode ---
    if test $do_all -eq 1
        if not __fisher_update_select_confirm $auto_yes "Update ALL plugins?"
            return 0
        end
        fisher update
        return
    end

    # --- interactive mode ---
    while true
        echo "Installed plugins:"
        for i in (seq $count_plugins)
            echo "  $i) $plugins[$i]"
        end
        echo
        echo "Enter indices (e.g. 1 2 5), 'a' for all, or 'q' to quit."

        if not read -P "> " choice
            echo "Aborted."
            return 0
        end

        switch (string lower -- (string trim -- $choice))
            case q quit
                echo "Aborted."
                return 0
            case a all
                if not __fisher_update_select_confirm $auto_yes "Update ALL plugins?"
                    continue
                end
                fisher update
                return
            case ''
                continue
        end

        set -l raw (string match -ar '[0-9]+' -- $choice)
        set -l selected
        set -l invalid 0

        for idx in $raw
            if test $idx -lt 1 -o $idx -gt $count_plugins
                echo "Out of range: $idx"
                set invalid 1
                continue
            end
            # Deduplicate: only append if not already in selected
            if not contains -- $plugins[$idx] $selected
                set selected $selected $plugins[$idx]
            end
        end

        if test (count $selected) -eq 0
            echo "No valid selection."
            continue
        end

        echo "Selected: "(string join ', ' $selected)
        if test $invalid -eq 1
            echo "Some inputs were out of range and ignored."
        end

        if not __fisher_update_select_confirm $auto_yes "Proceed?"
            return 0
        end

        fisher update $selected
        return
    end
end
