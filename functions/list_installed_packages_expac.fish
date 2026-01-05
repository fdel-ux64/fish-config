function list_installed_packages_expac --description "List packages installed in a period using expac"
    # help / usage
    if test (count $argv) -gt 0
        switch $argv[1]
            case '-h' '--help'
                echo "Usage: list_installed_packages [today|yesterday|last-week]"
                echo
                echo "Interactive mode (no args):"
                echo "  list_installed_packages"
                echo "    Prompts for: today / yesterday / last week"
                echo
                echo "Non-interactive examples:"
                echo "  list_installed_packages today"
                echo "  list_installed_packages yesterday"
                echo "  list_installed_packages last-week"
                return
        end
    end
    set period ""
    if test (count $argv) -gt 0
        set period $argv[1]
    end
    if test -z "$period"
        echo "Choose period: (1) today  (2) yesterday  (3) last week"
        read -P "Choice> " choice
        switch $choice
            case 1
                set period "today"
            case 2
                set period "yesterday"
            case 3
                set period "last-week"
            case '*'
                echo "Invalid choice."
                return
        end
    end
    set now (date +%s)
    set header ""
    switch $period
        case 'today'
            set from (date -d "00:00" +%s)
            set header "📦 List of packages installed today"
        case 'yesterday'
            set from (date -d "yesterday 00:00" +%s)
            set to (date -d "today 00:00" +%s)
            set now $to
            set header "📦 List of packages installed yesterday"
        case 'last-week'
            set from (date -d "7 days ago" +%s)
            set header "📦 List of packages installed in the last 7 days"
        case '*'
            echo "Unknown period: $period"
            echo "Run 'list_installed_packages --help' for usage."
            return
    end
    # expac: "<epoch> <name> <version>"
    set -l output (expac --timefmt=%s '%l %n %v' | awk -v FROM="$from" -v NOW="$now" '
        {
            t = $1
            name = $2
            version = $3
            if (t >= FROM && t <= NOW) {
                cmd = "date -d @" t " \"+%Y-%m-%d %T\""
                cmd | getline human
                close(cmd)
                print human "|" name "|" version
            }
        }
    ' | sort -t'|' -k2,2 | tr '|' ' ')
    # Display header and results
    if test -n "$output"
        echo
        echo "═══════════════════════════════════════════════════════════"
        echo "  $header"
        echo "═══════════════════════════════════════════════════════════"
        echo
        printf '%s\n' $output
        echo
        set count (count $output)
        echo "Total: $count package(s)"
    else
        echo
        echo "📦 No packages installed $period"
    end
end
