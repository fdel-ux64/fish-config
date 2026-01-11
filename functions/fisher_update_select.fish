function fisher_update_select --description "Interactively update Fisher plugins"
    set plugins (fisher list | sort)

    if test (count $plugins) -eq 0
        echo "No Fisher plugins installed."
        return
    end

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
        echo
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

    read -P "Proceed with update? [y/N]: " confirm
    switch (string lower -- $confirm)
        case y yes
            fisher update $selected
        case '*'
            echo "Aborted."
    end
end
