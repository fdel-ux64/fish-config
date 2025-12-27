function advanced_install_package
    # Package name
    if test (count $argv) -gt 0
        set package_name $argv[1]
    else
        read --prompt-str "Enter package name to install: " package_name
    end

    if test -z "$package_name"
        echo "❌ No package name provided."
        return 1
    end

    # Detect distro
    if test -f /etc/os-release
        set distro_id (string lower (string match -r '^ID=.*' < /etc/os-release | string replace -r '^ID=' ''))
    end

    # Determine installer command
    switch $distro_id
        case fedora
            set installer_cmd "sudo dnf install -y $package_name"
        case arch manjaro
            set installer_cmd "sudo pacman -S --noconfirm $package_name"
        case ubuntu debian
            set installer_cmd "sudo apt install -y $package_name"
        case '*'
            echo "Could not detect distro. Choose:"
            echo "1. Fedora"
            echo "2. Arch/Manjaro"
            echo "3. Ubuntu/Debian"
            read --prompt-str "Enter number: " distro_choice
            switch $distro_choice
                case 1
                    set installer_cmd "sudo dnf install -y $package_name"
                case 2
                    set installer_cmd "sudo pacman -S --noconfirm $package_name"
                case 3
                    set installer_cmd "sudo apt install -y $package_name"
                case '*'
                    echo "❌ Invalid choice. Exiting."
                    return 1
            end
    end

    echo "Installing '$package_name'..."

    # Run installer and capture output (stdout+stderr)
    set output (eval $installer_cmd 2>&1)

    # Check if already installed
    if string match -q '*already installed*' "$output"
        echo "ℹ️  Package '$package_name' is already installed."
    else if string match -q '*Nothing to do*' "$output"
        echo "ℹ️  Package '$package_name' is already installed."
    else if test $status -eq 0
        echo "✅ Package '$package_name' installed successfully!"
    else
        echo "❌ Installation failed. Check package name or internet connection."
        echo "$output"
        return 1
    end
end
