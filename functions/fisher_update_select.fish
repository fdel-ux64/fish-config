function fisher_update_select --description "Interactively or non-interactively update Fisher plugins"
    set non_interactive 0
    set auto_yes 0
    # Parse flags
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
    set plugins (fisher list | sort)
    if test (count $plugins) -eq 0
        echo "No Fisher plugins installed."
        return
    end
    # -------------------------
    # Non-interactive: --all
    # -------------------------
    if test $non_interactive -eq 1
        if test $auto_yes -eq 1
            fisher update
            return
        end
        echo -n "Update ALL plugins? [y/N]: "
        echo  # Force flush
        read confirm
        switch (string lower -- $confirm)
            case y yes
                fisher update
            case '*'
                echo "Aborted."
        end
        return
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
    
    if test "$choice" = "q" -o "$choice" = "n"
        echo "Aborted. No plugins updated."
        return
    end
    if test "$choice" = "a"
        if test $auto_yes -eq 1
            fisher update
            return
        end
        read -P "Update ALL plugins? [y/N]: " confirm
        switch (string lower -- $confirm)
            case y yes
                fisher update
            case '*'
                echo "Aborted."
        end
        return
    end
    set choices (string split ' ' -- $choice)
    set selected
    for idx in $choices
        if string match -qr '^[0-9]+$' -- $idx
            if test $idx -ge 1 -a $idx -le (count $plugins)
                set selected $selected $plugins[$idx]
            else
                echo "Invalid selection: $idx"
                return 1
            end
        else
            echo "Invalid input: $idx"
            return 1
        end
    end
    if test (count $selected) -eq 0
        echo "No valid plugins selected."
        return
    end
    echo
    echo "Selected plugins:"
    for p in $selected
        echo "  - $p"
    end
    echo
    if test $auto_yes -eq 1
        fisher update $selected
        return
    end
    
    read -P "Proceed with update? [y/N]: " confirm
    switch (string lower -- $confirm)
        case y yes
            fisher update $selected
        case '*'
            echo "Aborted."
    end
end
