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
        
        # Try to fetch using curl or wget
        if type -q curl
            set latest_kernel (curl -s https://www.kernel.org/finger_banner | head -1 | awk '{print $NF}')
        else if type -q wget
            set latest_kernel (wget -qO- https://www.kernel.org/finger_banner | head -1 | awk '{print $NF}')
        else
            echo "⚠️  curl or wget not found. Cannot fetch latest kernel version."
        end
        
        if test -n "$latest_kernel"
            echo "Latest Stable Kernel:   $latest_kernel"
            echo
            
            # Extract base version from current kernel
            set -l current_version (echo $current_kernel | string replace -r '([0-9]+\.[0-9]+\.[0-9]+).*' '$1')
            
            if test "$current_version" = "$latest_kernel"
                echo "✅ You're running the latest stable kernel!"
            else
                echo "ℹ️  A newer kernel version may be available."
            end
        else
            echo "❌ Could not retrieve latest kernel version."
        end
    end
    
    # ---- Prompt to visit kernel.org ----
    echo
    read --prompt-str "Visit kernel.org? (y/N): " visit
    
    # Handle response (case-insensitive)
    if string match -qr '^(y|Y)$' "$visit"
        # Try to open in default browser, fallback to firefox
        if type -q xdg-open
            nohup xdg-open https://kernel.org >/dev/null 2>&1 &
        else if type -q firefox
            nohup firefox https://kernel.org >/dev/null 2>&1 &
        else
            echo "❌ No browser command found. Please open https://kernel.org manually."
        end
    end
end
