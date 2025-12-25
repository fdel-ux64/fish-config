complete -c instlist -f

# Flags
complete -c instlist -s h -l help -d 'Show help'

# Primary options
complete -c instlist -n '__fish_use_subcommand' -a today       -d 'Packages installed today'
complete -c instlist -n '__fish_use_subcommand' -a yesterday   -d 'Packages installed yesterday'
complete -c instlist -n '__fish_use_subcommand' -a last-week   -d 'Packages installed in the last 7 days'
complete -c instlist -n '__fish_use_subcommand' -a this-month  -d 'Packages installed this month'
complete -c instlist -n '__fish_use_subcommand' -a last-month  -d 'Packages installed last calendar month'

# Aliases
complete -c instlist -n '__fish_use_subcommand' -a td -d 'Alias for today'
complete -c instlist -n '__fish_use_subcommand' -a yd -d 'Alias for yesterday'
complete -c instlist -n '__fish_use_subcommand' -a lw -d 'Alias for last-week'
complete -c instlist -n '__fish_use_subcommand' -a tm -d 'Alias for this-month'
complete -c instlist -n '__fish_use_subcommand' -a lm -d 'Alias for last-month'
