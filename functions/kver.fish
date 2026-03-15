function kver --description "Display current kernel version and optionally open kernel.org"
    # ---- Show current kernel version ----
    set -l current_kernel (uname -r)
    echo "Current Kernel Version: $current_kernel"

    # ---- Help flag ----
    if contains -- $argv[1] "-h" "--help"
        echo "kver — show current Linux kernel version"
        echo
        echo "USAGE:"
        echo "  kver [-c|--compare]"
        echo
        echo "OPTIONS:"
        echo "  -c, --compare    Fetch and compare with latest stable kernel from kernel.org"
        echo
        echo "After displaying the kernel version, you will be prompted to visit https://kernel.org."
        return 0
    end

    # ---- Fetch latest kernel version if requested ----
    if contains -- $argv[1] "-c" "--compare"
        echo
        echo "Fetching latest kernel version from kernel.org..."

        set -l latest_kernel ""

        if type -q curl
            set latest_kernel (wget -qO- https://www.kernel.org/finger_banner | grep "^The latest stable version" | awk '{print $NF}')
        else if type -q wget
            set latest_kernel (wget -qO- https://www.kernel.org/finger_banner | grep -i "latest stable" | head -1 | awk '{print $NF}')
        else
            echo "⚠️  curl or wget not found. Cannot fetch latest kernel version."
            return 1
        end

        if test -n "$latest_kernel"
            # Validate format before doing any math on it
            if not string match -qr '^[0-9]+\.[0-9]+(\.[0-9]+)?$' "$latest_kernel"
                echo "❌ Unexpected version format: $latest_kernel"
                return 1
            end

            echo "Latest Stable Kernel:   $latest_kernel"
            echo

            # Extract base version from current kernel (e.g. 6.19.7 from 6.19.7-200.fc43.x86_64)
            set -l current_version (echo $current_kernel | string replace -r '([0-9]+\.[0-9]+\.[0-9]+).*' '$1')

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

            set -l is_current false
            if test "$cur_parts[1]" -eq "$lat_parts[1]" \
                -a "$cur_parts[2]" -eq "$lat_parts[2]" \
                -a "$cur_parts[3]" -eq "$lat_parts[3]"
                set is_current true
            end

            if $is_current
                echo "✅ You're running the latest stable kernel!"
            else
                echo "ℹ️  A newer kernel is available."
            end

            echo
            read --prompt-str "Visit kernel.org? (y/N): " visit
            if string match -qr '^(y|Y)$' "$visit"
                if type -q xdg-open
                    xdg-open https://kernel.org &; disown
                else if type -q firefox
                    firefox https://kernel.org &; disown
                else
                    echo "❌ No browser command found. Please open https://kernel.org manually."
                end
            end
        else
            echo "❌ Could not retrieve latest kernel version."
        end
    end
end
