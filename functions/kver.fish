function kver --description "Display current kernel version and optionally open kernel.org"
    # ---- Unknown flag guard ----
    for arg in $argv
        if string match -qr -- '^-' $arg
            if not contains -- $arg "-h" "--help" "-help" "-c" "--compare" "-o" "--open"
                echo "❌ Unknown option: $arg"
                echo
                echo "kver — show current Linux kernel version"
                echo
                echo "USAGE:"
                echo "  kver [--compare] [--open]"
                echo
                echo "OPTIONS:"
                echo "  -c, --compare    Fetch and compare with latest stable kernel from kernel.org"
                echo "  -o, --open       Open kernel.org in the default browser and exit"
                return 1
            end
        end
    end

    # ---- Help flag ----
    if contains -- "--help" $argv; or contains -- "-h" $argv; or contains -- "-help" $argv
        echo "kver — show current Linux kernel version"
        echo
        echo "USAGE:"
        echo "  kver [--compare] [--open]"
        echo
        echo "OPTIONS:"
        echo "  -c, --compare    Fetch and compare with latest stable kernel from kernel.org"
        echo "  -o, --open       Open kernel.org in the default browser and exit"
        return 0
    end

    # ---- Open flag (standalone only — when combined with --compare, open runs after) ----
    set -l has_open 0
    if contains -- "--open" $argv; or contains -- "-o" $argv
        set has_open 1
    end
    set -l has_compare 0
    if contains -- "--compare" $argv; or contains -- "-c" $argv
        set has_compare 1
    end
    if test $has_open -eq 1 -a $has_compare -eq 0
        echo "Opening kernel.org..."
        if type -q xdg-open
            xdg-open https://kernel.org >/dev/null 2>&1 &; disown
        else if type -q firefox
            firefox https://kernel.org >/dev/null 2>&1 &; disown
        else
            echo "❌ No browser command found. Please open https://kernel.org manually."
            return 1
        end
        return 0
    end

    # ---- Show current kernel version ----
    set -l current_kernel (uname -r)
    echo "Current kernel: $current_kernel"

    # ---- Compare flag ----
    if contains -- "--compare" $argv; or contains -- "-c" $argv
        if not type -q curl
            echo "❌ curl not found. Cannot fetch latest kernel version."
            return 1
        end

        set -l latest_kernel (curl -fsSL https://www.kernel.org/finger_banner | grep "^The latest stable version" | awk '{print $NF}')

        if test -z "$latest_kernel"
            echo "❌ Could not retrieve latest kernel version."
            return 1
        end

        # Validate format before doing any math on it
        if not string match -qr '^[0-9]+\.[0-9]+(\.[0-9]+)?$' "$latest_kernel"
            echo "❌ Unexpected version format: $latest_kernel"
            return 1
        end

        echo "Latest stable:  $latest_kernel"

        # Extract base version from current kernel (e.g. 6.16.0 from 6.16.0-200.fc44.x86_64)
        set -l current_version (string replace -r '([0-9]+\.[0-9]+\.[0-9]+).*' '$1' $current_kernel)

        # Split into parts
        set -l cur_parts (string split '.' $current_version)
        set -l lat_parts (string split '.' $latest_kernel)

        # Pad to 3 segments so comparison is always safe (e.g. "6.20" -> "6.20.0")
        while test (count $cur_parts) -lt 3
            set -a cur_parts 0
        end
        while test (count $lat_parts) -lt 3
            set -a lat_parts 0
        end

        if test "$cur_parts[1]" -eq "$lat_parts[1]" \
            -a "$cur_parts[2]" -eq "$lat_parts[2]" \
            -a "$cur_parts[3]" -eq "$lat_parts[3]"
            echo "Up to date."
        else
            echo "Update available."
        end

        # ---- Open flag after compare ----
        if contains -- "--open" $argv; or contains -- "-o" $argv
            echo "Opening kernel.org..."
            if type -q xdg-open
                xdg-open https://kernel.org >/dev/null 2>&1 &; disown
            else if type -q firefox
                firefox https://kernel.org >/dev/null 2>&1 &; disown
            else
                echo "❌ No browser command found. Please open https://kernel.org manually."
            end
        end
    end
end
