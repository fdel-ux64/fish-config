function list_installed_packages_expac --description "List packages installed in a period using expac"
    # Distro check
    if not test -f /etc/arch-release
        echo "Error: This function is designed for Arch-based distributions only."
        echo "Detected distribution does not appear to be Arch-based."
        return 1
    end
    
    # Check if expac is installed
    if not command -q expac
        echo "Error: expac is not installed."
        echo "Install it with: sudo pacman -S expac"
        return 1
    end
    
    # NOTE:
    # expac --timefmt=%s is REQUIRED here.
    # %l only becomes epoch seconds with this option.
    # Do NOT remove or change unless expac behavior changes.
    
    # Help
    if test (count $argv) -gt 0
        switch $argv[1]
            case '-h' '--help'
                echo "Usage: list_installed_packages_expac [today|yesterday|last-week]"
                echo "Aliases: td yd lw"
                echo "No arguments: interactive prompt"
                return
        end
    end
    
    # Resolve period
    set -l period ""
    if test (count $argv) -gt 0
        switch $argv[1]
            case today td
                set period today
            case yesterday yd
                set period yesterday
            case last-week lw
                set period last-week
            case '*'
                echo "Unknown period: $argv[1]"
                return
        end
    end
    
    if test -z "$period"
        echo "Choose period:"
        echo "  1) today"
        echo "  2) yesterday"
        echo "  3) last week"
        read -P "Choice> " choice
        switch $choice
            case 1; set period today
            case 2; set period yesterday
            case 3; set period last-week
            case '*'
                echo "Invalid choice."
                return
        end
    end
    
    # Time bounds
    set -l now (date +%s)
    set -l from
    set -l header
    switch $period
        case today
            set from (date -d "00:00" +%s)
            set header "📦 List of packages installed today"
        case yesterday
            set from (date -d "yesterday 00:00" +%s)
            set now  (date -d "today 00:00" +%s)
            set header "📦 List of packages installed yesterday"
        case last-week
            set from (date -d "7 days ago" +%s)
            set header "📦 List of packages installed in the last 7 days"
    end
    
    # IMPORTANT:
    # --timefmt=%s makes %l epoch seconds
    set -l output (
        expac --timefmt=%s '%l %n %v' |
        awk -v FROM="$from" -v NOW="$now" '
            {
                t=$1; name=$2; ver=$3
                if (t >= FROM && t <= NOW) {
                    cmd="date -d @" t " \"+%Y-%m-%d %T\""
                    cmd | getline d
                    close(cmd)
                    print d, name, ver
                }
            }
        ' |
        sort -k2,2
    )
    
    if test -n "$output"
        echo
        echo "═══════════════════════════════════════════════════════════"
        echo "  $header"
        echo "═══════════════════════════════════════════════════════════"
        echo
        printf '%s\n' $output
        echo
        echo "Total: "(count $output)" package(s)"
    else
        echo
        echo "📦 No packages installed $period"
    end
end
