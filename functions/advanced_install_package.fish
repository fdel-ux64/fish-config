function advanced_install_package
    # Help flag
    if contains -- --help $argv; or contains -- -h $argv
        echo "Usage: advanced_install_package [PACKAGE]"
        echo ""
        echo "Install a package using the system package manager."
        echo "Auto-detects the distro from /etc/os-release; falls back to manual selection."
        echo ""
        echo "Supported distros:"
        echo "  Fedora               dnf"
        echo "  Arch / Manjaro       pacman"
        echo "  Ubuntu / Debian /    apt"
        echo "  Linux Mint / Pop!_OS"
        echo ""
        echo "Arguments:"
        echo "  PACKAGE    Name of the package to install (prompted if omitted)"
        echo ""
        echo "Options:"
        echo "  -h, --help    Show this help message"
        echo ""
        echo "Examples:"
        echo "  advanced_install_package curl"
        echo "  advanced_install_package"
        return 0
    end

    # Validate argument count — silently drop extras
    if test (count $argv) -gt 1
        echo "Warning: only the first package name will be used."
    end

    # Get package name from arg or prompt
    if test (count $argv) -gt 0
        set package_name $argv[1]
    else
        read --prompt-str "Enter package name to install: " package_name
    end

    # Trim and reject empty package name
    set package_name (string trim $package_name)
    if test -z "$package_name"
        echo "Error: no package name provided." >&2
        return 1
    end

    # Auto-detect distro — handle quoted values (e.g. ID="ubuntu")
    set distro_id ""
    if test -f /etc/os-release
        set distro_id (grep '^ID=' /etc/os-release | string replace -r '^ID=|"' '' | string lower)
        # Fall back to ID_LIKE for derivative distros (e.g. Pop!_OS, Linux Mint)
        if test -z "$distro_id"
            set id_like (grep '^ID_LIKE=' /etc/os-release | string replace -r '^ID_LIKE=|"' '' | string lower)
            set distro_id (string split ' ' $id_like)[1]
        end
    end

    # Attempt auto-install based on detected distro
    set -l install_status 0
    switch "$distro_id"
        case fedora
            echo "Detected Fedora. Installing with dnf..."
            sudo dnf install -y $package_name
            set install_status $status
        case manjaro arch
            echo "Detected Manjaro/Arch. Installing with pacman..."
            sudo pacman -S --noconfirm $package_name
            set install_status $status
        case ubuntu debian linuxmint pop
            echo "Detected $distro_id. Installing with apt..."
            sudo apt install -y $package_name
            set install_status $status
        case '*'
            # Fallback: manual selection
            echo "Could not auto-detect distro. Please choose:"
            echo "1. Fedora (dnf)"
            echo "2. Arch / Manjaro (pacman)"
            echo "3. Ubuntu / Debian (apt)"
            read --prompt-str "Enter number: " distro_choice
            switch "$distro_choice"
                case 1
                    sudo dnf install -y $package_name
                    set install_status $status
                case 2
                    sudo pacman -S --noconfirm $package_name
                    set install_status $status
                case 3
                    sudo apt install -y $package_name
                    set install_status $status
                case '*'
                    echo "Invalid choice. Exiting." >&2
                    return 1
            end
    end

    if test $install_status -ne 0
        echo "Error: installation failed (exit code $install_status)." >&2
    end
    return $install_status
end
