# Disable file completion
complete -c instlist -f

# Help flags (always available)
complete -c instlist -s h -l help -d 'Show help'

# Primary options (only if none already used)
complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a today \
    -d 'Packages installed today'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a yesterday \
    -d 'Packages installed yesterday'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a last-week \
    -d 'Packages installed in the last 7 days'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a this-month \
    -d 'Packages installed this month'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a last-month \
    -d 'Packages installed last calendar month'

# Aliases
complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a td \
    -d 'Alias for today'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a yd \
    -d 'Alias for yesterday'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a lw \
    -d 'Alias for last-week'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a tm \
    -d 'Alias for this-month'

complete -c instlist \
    -n 'not __fish_seen_subcommand_from today yesterday last-week this-month last-month td yd lw tm lm' \
    -a lm \
    -d 'Alias for last-month'
