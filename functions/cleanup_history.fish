function cleanup_history -d "Interactive history cleanup with pattern argument"
    # Show help if no args, help flag, or empty first arg
    if test (count $argv) -eq 0; or string match -q -r '^-h|--help$' -- $argv[1]
        echo "Usage: cleanup_history PATTERN"
        echo ""
        echo "Interactive history cleanup tool."
        echo ""
        echo "Arguments:"
        echo "  PATTERN    Search pattern (required)"
        echo ""
        echo "Examples:"
        echo "  cleanup_history rpm_installed    # Search for 'rpm_installed'"
        echo "  cleanup_history 'git push'        # Use quotes for spaces"
        echo "  cleanup_history -h                # Show this help"
        echo ""
        echo "During cleanup:"
        echo "  Enter numbers (space-separated), 'all', or 'n/q' to quit."
        return
    end
    
    set -l pattern $argv[1]
    
    # Additional check for empty pattern
    if test -z "$pattern"
        echo "Error: Pattern cannot be empty."
        echo "Run 'cleanup_history -h' for usage."
        return 1
    end
    
    # Get matching entries
    set -l all_matches (history search --contains $pattern --max 100)
    set -l matches
    
    for match in $all_matches
        # Skip if this is a cleanup_history command with the same pattern
        if not string match -q "cleanup_history *$pattern*" -- $match
            set -a matches $match
        end
    end
    
    if test (count $matches) -eq 0
        echo "No matching entries found for: $pattern"
        return
    end
    
    echo "Matching entries for '$pattern':"
    for i in (seq (count $matches))
        echo "$i: $matches[$i]"
    end
    echo ""
    
    while true
        echo "Enter numbers (space-separated), 'all', or 'n/q' to quit:"
        read -l selection
        
        # Check quit FIRST
        switch $selection
            case '' n N q Q quit exit
                echo "Aborted."
                break
            case all ALL
                read -l -P "Delete ALL "(count $matches)" matching entries? [y/N]: " confirm
                if string match -qi 'y*' $confirm
                    # Direct deletion - pipe 'all' to bypass interactive prompt
                    echo all | history delete --contains $pattern >/dev/null 2>&1
                    echo "Deleted all matching entries."
                else
                    echo "Aborted."
                end
                break
        end
        
        # Process numbers
        set -l valid_nums
        set -l invalid_nums
        for num in (string split " " $selection)
            if string match -qr '^[0-9]+$' -- $num
                if test $num -ge 1 -a $num -le (count $matches)
                    set valid_nums $valid_nums $num
                else
                    set invalid_nums $invalid_nums $num
                end
            else
                set invalid_nums $invalid_nums $num
            end
        end
        
        if test (count $valid_nums) -gt 0
            for num in $valid_nums
                set -l cmd $matches[$num]
                # Extract first 50 chars to use as unique identifier for prefix deletion
                set -l prefix (string sub -l 50 -- $cmd)
                # Pipe 'all' to bypass Fish's interactive prompt
                echo all | history delete --prefix "$prefix" >/dev/null 2>&1
                echo "Deleted entry $num: "(string sub -l 60 -- $cmd)"..."
            end
            echo "Deleted "(count $valid_nums)" entries."
            read -l -P "Continue deleting more? [y/N]: " continue
            if not string match -qi 'y*' $continue
                break
            end
        else
            if test (count $invalid_nums) -gt 0
                echo "Ignored invalid entries: "(string join ", " $invalid_nums)"."
            end
            echo "Enter valid numbers, 'all', or 'n/q' to quit."
        end
    end
    
    echo "Done."
end
