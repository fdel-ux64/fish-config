# Disable file completion for safety
complete -c advanced_install_package -f

# Help flags
complete -c advanced_install_package -s h -l help -d "Show help"

# First argument: package name (common examples, no file completion)
# Users can still type any package manually
complete -c advanced_install_package \
    -n "not __fish_seen_subcommand_from" \
    -a "vim git curl wget python3 htop tmux docker" \
    -d "Package name to install"
