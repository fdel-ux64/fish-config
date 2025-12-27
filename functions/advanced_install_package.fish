function advanced_install_package --description "Install a package on Fedora, Arch/Manjaro, or Ubuntu/Debian"
    set -l package_name $argv[1]
    set -l arg $argv[1]

    # ---- Help flag ----
    if contains -- "$arg" "-h" "--help"
        echo "advanced_install_package — install a package using the system's package manager"
        echo
        echo "USAGE:"
        echo "  advanced_install_package [PACKAGE_NAME]"
        echo
        echo "If PACKAGE_NAME is not provided, you will be prompted."
        echo "The function auto-detects your Linux distro and chooses the right installer."
        return 0
    end

    # ---- Prompt for package name if missing ----
    if test -z "$package_name"
        read --prompt-str "Enter package name to install: " package_name
    end

    if test -z "$package_name"
        echo "❌ No package name provided. Exiting."
        return 1
    end

    # ---- Auto-detect distro ----
    set -l distro_id
    if test -f /etc/os-release
        set distro_id (string lower (string match -r '^ID=.*' < /etc/os-release | string replace -r '^ID=' ''))
        # Try ID_LIKE if ID is empty
        if test -z "$distro_id"
            set distro_id (string lower (string match -r '^ID_LIKE=.*' < /etc/os-release | string replace -r '^ID_LIKE=' ''))
        end
    end

    # ---- Helper function to run install commands ----
    function __install
        set -l cmd $argv[1]
        echo "Installing '$package_name' with $cmd..."
        eval $cmd
        or begin
            echo "❌ Installation failed. Please check the package name or internet connection."
            return 1
        end
        echo "✅ $package_name installed successfully!"
    end

    # ---- Map distro to install command ----
    switch $distro_id
        case fedora
            __install "sudo dnf install -y '$package_name'"
            return
        case arch manjaro
            __install "sudo pacman -S --noconfirm '$package_name'"
            return
        case ubuntu debian
            __install "sudo apt install -y '$package_name'"
            return
    end

    # ---- Fallback prompt if detection fails ----
    echo "Could not auto-detect distro. Please choose:"
    echo "1. Fedora"
    echo "2. Manjaro/Arch"
    echo "3. Ubuntu/Debian"
    read --prompt-str "Enter the number corresponding to your distro: " distro_choice

    switch $distro_choice
        case 1
            __install "sudo dnf install -y '$package_name'"
        case 2
            __install "sudo pacman -S --noconfirm '$package_name'"
        case 3
            __install "sudo apt install -y '$package_name'"
        case '*'
            echo "❌ Invalid choice. Exiting."
            return 1
    end
end
