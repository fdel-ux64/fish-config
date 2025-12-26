function advanced_install_package
    # If a package name was passed as an argument, use it; otherwise ask
    if test (count $argv) -gt 0
        set package_name $argv[1]
    else
        read --prompt-str "Enter package name to install: " package_name
    end

    # Try to auto-detect the distro
    if test -f /etc/os-release
        set distro_id (string lower (string match -r '^ID=.*' < /etc/os-release | string replace -r '^ID=' ''))
    end

    if test "$distro_id" = "fedora"
        echo "Detected Fedora. Installing with dnf..."
        sudo dnf install -y $package_name
        if test $status -eq 0
            echo "$package_name installed successfully!"
        else
            echo "Installation failed. Please check your package name or internet connection."
        end
        return
    else if test "$distro_id" = "manjaro" -o "$distro_id" = "arch"
        echo "Detected Manjaro/Arch. Installing with pacman..."
        sudo pacman -S --noconfirm $package_name
        if test $status -eq 0
            echo "$package_name installed successfully!"
        else
            echo "Installation failed. Please check your package name or internet connection."
        end
        return
    else if test "$distro_id" = "ubuntu" -o "$distro_id" = "debian"
        echo "Detected Ubuntu/Debian. Installing with apt..."
        sudo apt install -y $package_name
        if test $status -eq 0
            echo "$package_name installed successfully!"
        else
            echo "Installation failed. Please check your package name or internet connection."
        end
        return
    end

    # Fallback to manual prompt if detection fails
    echo "Could not auto-detect distro. Please choose:"
    echo "1. Fedora"
    echo "2. Manjaro"
    echo "3. Ubuntu"
    read --prompt-str "Enter the number corresponding to your distro: " distro_choice

    switch $distro_choice
        case 1
            sudo dnf install -y $package_name
            if test $status -eq 0
                echo "$package_name installed successfully!"
            else
                echo "Installation failed."
            end
        case 2
            sudo pacman -S --noconfirm $package_name
            if test $status -eq 0
                echo "$package_name installed successfully!"
            else
                echo "Installation failed."
            end
        case 3
            sudo apt install -y $package_name
            if test $status -eq 0
                echo "$package_name installed successfully!"
            else
                echo "Installation failed."
            end
        case '*'
            echo "Invalid choice. Exiting."
    end
end
