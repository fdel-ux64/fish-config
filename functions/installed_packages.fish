function installed_packages --description "Unified installed package viewer (auto-detect Arch/Debian/RPM distros)"

    # ---- Backend detection (order matters) ----
    set -l backend ""

    if test -f /etc/debian_version
        set backend deb
    else if test -f /etc/arch-release
        set backend arch
    else if command -q rpm
        set backend rpm
    end

    # ---- Optional: show detected backend ----
    if test (string lower -- "$argv[1]") = --backend
        if test -n "$backend"
            echo " Detected backend: $backend"
            return 0
        else
            echo " No supported backend detected."
            return 1
        end
    end

    # ---- Dispatch ----
    switch $backend

        case deb
            if functions -q deb_installed
                deb_installed $argv
            else
                echo " ❌ Missing function: deb_installed"
                return 1
            end

        case arch
            if functions -q arch_installed
                arch_installed $argv
            else
                echo " ❌ Missing function: arch_installed"
                return 1
            end

        case rpm
            if functions -q rpm_installed
                rpm_installed $argv
            else
                echo " ❌ Missing function: rpm_installed"
                return 1
            end

        case '*'
            echo " ❌ Unsupported distribution"
            echo
            echo " Supported backends:"
            echo "  • Debian-based (Ubuntu, Mint, etc.)"
            echo "  • Arch-based"
            echo "  • RPM-based (Fedora, RHEL, openSUSE, etc.)"
            echo
            return 1
    end
end
