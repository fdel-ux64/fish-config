function fisher_update_select \
    --description "Selectively update Fisher plugins (interactive or scripted)"

    # --- flag parsing ---
    set -l do_all 0
    set -l auto_yes 0

    for arg in $argv
        switch $arg
            case --help -h
                echo "Usage: fisher_update_select [--all] [--yes|-y]"
                echo ""
                echo "Interactively select Fisher plugins to update."
                echo ""
                echo "Options:"
                echo "  --all        Update all plugins, skip interactive picker"
                echo "  --yes, -y    Skip confirmation prompts (use with --all)"
                echo "  --help, -h   Show this help"
                return 0
            case --all
                set do_all 1
            case --yes -y
                set auto_yes 1
            case '--*'
                echo "Unknown flag: $arg" >&2
                return 2
        end
    end

    # --- get plugin list ---
    set -l plugins (fisher list)
    set -l count_plugins (count $plugins)
    if test $count_plugins -eq 0
        echo "No plugins installed."
        return 0
    end

    # --- helper: confirm ---
    # Takes auto_yes flag as $1, prompt as $2
    function __fus_confirm
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

    # --- all mode ---
    if test $do_all -eq 1
        if not __fus_confirm $auto_yes "Update ALL plugins?"
            return 0
        end
        fisher update
        return $status
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
                if not __fus_confirm $auto_yes "Update ALL plugins?"
                    continue
                end
                fisher update
                return $status
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
            set selected $selected $plugins[$idx]
        end

        set selected (printf "%s\n" $selected | sort -u)

        if test (count $selected) -eq 0
            echo "No valid selection."
            continue
        end

        echo "Selected: "(string join ', ' $selected)
        if test $invalid -eq 1
            echo "Some inputs were out of range and ignored."
        end

        if not __fus_confirm $auto_yes "Proceed?"
            continue
        end

        fisher update $selected
        return $status
    end
end
