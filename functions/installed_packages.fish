function installed_packages --description "Unified installed package viewer (auto-detect Arch/RPM)"

    # ---- Backend detection ----
    set -l backend ""

    if command -q rpm
        set backend rpm
    else if test -f /etc/arch-release
        set backend arch
    end

    # ---- Optional: show detected backend ----
    if test (string lower -- $argv[1]) = "--backend"
        if test -n "$backend"
            echo "Detected backend: $backend"
            return 0
        else
            echo "No supported backend detected."
            return 1
        end
    end

    # ---- Dispatch ----
    switch $backend
        case rpm
            if functions -q rpm_installed
                rpm_installed $argv
            else
                echo "❌ Missing function: rpm_installed"
                return 1
            end

        case arch
            if functions -q arch_installed
                arch_installed $argv
            else
                echo "❌ Missing function: arch_installed"
                return 1
            end

        case '*'
            echo "❌ Unsupported distribution"
            echo
            echo "This function currently supports:"
            echo "  • Arch-based systems"
            echo "  • RPM-based systems"
            echo
            echo "You can still use:"
            echo "  arch_installed"
            echo "  rpm_installed"
            return 1
    end
end
