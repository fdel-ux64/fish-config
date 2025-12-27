function kver --description "Display current kernel version and optionally open kernel.org"
    # ---- Show current kernel version ----
    set -l current_kernel (uname -r)
    echo "Current Kernel Version: $current_kernel"

    # ---- Help flag ----
    if contains -- $argv[1] "-h" "--help"
        echo "kver — show current Linux kernel version"
        echo
        echo "USAGE:"
        echo "  kver"
        echo
        echo "After displaying the kernel version, you will be prompted to visit https://kernel.org."
        return 0
    end

    # ---- Prompt to visit kernel.org ----
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
