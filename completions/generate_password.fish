# Fisher completion for generate_password

# Command itself
complete -c generate_password -f

# Help flags
complete -c generate_password -s h -l help -d "Show help"

# Optional numeric arguments (length and count)
# Fish does not provide positional argument completion directly, but we can hint with descriptions
complete -c generate_password -n '__fish_use_subcommand' -a '16 20 32' -d 'Suggested password lengths'
complete -c generate_password -n '__fish_use_subcommand' -a '1 5 10' -d 'Number of passwords to generate'
