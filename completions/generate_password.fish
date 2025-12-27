# Disable file completion
complete -c generate_password -f

# Help flag
complete -c generate_password -s h -l help -d "Show help"

# First argument: password length
complete -c generate_password -n "not __fish_seen_subcommand_from" -a "16 20 32 64" -d "Password length"

# Second argument: number of passwords
complete -c generate_password -n "__fish_seen_argument_from 16 20 32 64" -a "1 2 3 5 10" -d "Number of passwords"
