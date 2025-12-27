function current_brightness --description "Show current screen brightness using ddcutil"
    # ---- Help flag ----
    if contains -- $argv[1] "-h" "--help"
        echo "current_brightness — display current brightness of your monitor(s)"
        echo
        echo "USAGE:"
        echo "  current_brightness"
        echo
        echo "This command requires 'ddcutil' to be installed."
        return 0
    end

    # ---- Check if ddcutil exists ----
    if not type -q ddcutil
        echo "❌ Error: 'ddcutil' is not installed or not in your PATH."
        return 1
    end

    # ---- Show brightness ----
    ddcutil getvcp 10
end
