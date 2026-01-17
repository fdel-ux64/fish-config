function current_brightness --description "Show current screen brightness using ddcutil"
    # ---- Help flag ----
    if contains -- $argv[1] "-h" "--help"
        echo "current_brightness — display current brightness of your monitor(s)"
        echo
        echo "USAGE:"
        echo "  current_brightness"
        echo
        echo "Requires: ddcutil"
        return 0
    end

    # ---- Check if ddcutil exists ----
    if not type -q ddcutil
        echo "❌ Error: 'ddcutil' is not installed or not in your PATH."
        return 1
    end

    # ---- Pre-check I2C permissions ----
    if not groups | string match -q "*i2c*"
        echo "⚠️  Warning: you are not in the 'i2c' group."
        echo "   ddcutil may fail with permission errors."
        echo
        echo "   Fix:"
        echo "     sudo usermod -aG i2c $USER"
        echo "     reboot (or log out/in)"
        echo
    end

    # ---- Run ddcutil and capture output ----
    set -l output (ddcutil getvcp 10 2>&1)
    set -l exit_code $status

    # ---- If ddcutil fails, fallback to /sys/class/backlight ----
    if test $exit_code -ne 0
        for dev in /sys/class/backlight/*
            if test -r "$dev/brightness"
                set -l brightness (cat "$dev/brightness")
                set -l max (cat "$dev/max_brightness" 2>/dev/null)

                if test -n "$max"
                    set -l percent (math "($brightness * 100) / $max")
                    echo "Laptop brightness: $percent%"
                else
                    echo "Laptop brightness value: $brightness"
                end
                return 0
            end
        end

        # ---- No fallback available: show original error ----
        if string match -q "*EACCES*" -- $output
            echo "❌ Permission denied accessing I²C devices."
            echo
            echo "Fix:"
            echo "  sudo usermod -aG i2c $USER"
            echo "  reboot (or log out/in)"
            echo
            echo "More info:"
            echo "  https://www.ddcutil.com/i2c_permissions"
        else
            echo "❌ Failed to read brightness:"
            echo $output
        end
        return 1
    end

    # ---- Success (external monitor via DDC/CI) ----
    echo $output
end

