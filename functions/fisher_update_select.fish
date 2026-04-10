function fisher_update_select --description "Interactively or non-interactively update Fisher plugins"
    set -l non_interactive 0
    set -l auto_yes 0

    for arg in $argv
        switch $arg
            case --all
                set non_interactive 1
            case --yes
                set auto_yes 1
            case '*'
                echo "Unknown option: $arg"
                echo "Supported options: --all, --yes"
                return 1
        end
    end

    set -l plugins (fisher list | sort)
    if test (count $plugins) -eq 0
        echo "No Fisher plugins installed."
        return 0
    end

    # --all: update everything, skip confirmation unless --yes is absent
    # Rationale: --all means "I want all of them"; the extra confirmation adds
    # friction without safety. --yes makes it fully non-interactive.
    if test $non_interactive -eq 1
        if test $auto_yes -eq 0
            read -P "Update ALL plugins? [y/N]: " confirm
            switch (string lower -- $confirm)
                case y yes
                case '*'
                    echo "Aborted."
                    return 0
            end
        end
        fisher update
        return 0
    end

    # -------------------------
    # Interactive mode
    # -------------------------
    echo "Installed Fisher plugins:"
    echo
    for i in (seq (count $plugins))
        printf "  %2d) %s\n" $i $plugins[$i]
    end
    echo
    echo "Select plugins to update:"
    echo "  - Numbers separated by spaces (e.g. 1 3 5)"
    echo "  - 'a' to update all"
    echo "  - 'n' or 'q' to quit"
    echo

    read -P "Your choice: " choice
    set choice (string trim -- $choice)

    # Empty input
    if test -z "$choice"
        echo "No input provided. Aborted."
        return 0
    end

    switch (string lower -- $choice)
        case q n
            echo "Aborted. No plugins updated."
            return 0
        case a
            if test $auto_yes -eq 0
                read -P "Update ALL plugins? [y/N]: " confirm
                switch (string lower -- $confirm)
                    case y yes
                    case '*'
                        echo "Aborted."
                        return 0
                end
            end
            fisher update
            return 0
    end

    # Numeric selection
    set -l raw_indices (string split -n ' ' -- $choice)
    set -l seen_indices
    set -l selected

    for idx in $raw_indices
        if not string match -qr '^[0-9]+$' -- $idx
            echo "Invalid input: $idx"
            return 1
        end

        if test $idx -lt 1 -o $idx -gt (count $plugins)
            echo "Invalid selection: $idx (valid range: 1–"(count $plugins)")"
            return 1
        end

        # Deduplicate
        if contains -- $idx $seen_indices
            continue
        end
        set seen_indices $seen_indices $idx
        set selected $selected $plugins[$idx]
    end

    if test (count $selected) -eq 0
        echo "No valid plugins selected."
        return 0
    end

    echo
    echo "Selected plugins:"
    for p in $selected
        echo "  - $p"
    end
    echo

    if test $auto_yes -eq 0
        read -P "Proceed with update? [y/N]: " confirm
        switch (string lower -- $confirm)
            case y yes
            case '*'
                echo "Aborted."
                return 0
        end
    end

    fisher update $selected
end
