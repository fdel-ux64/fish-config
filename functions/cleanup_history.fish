function cleanup_history -d "Interactive history cleanup with optional pattern argument"
    # Handle help
    if set -q argv[1]; and string match -q -r '^-h|--help$' $argv[1]
        echo "Usage: cleanup_history [PATTERN]"
        echo ""
        echo "Interactive history cleanup tool."
        echo ""
        echo "Examples:"
        echo "  cleanup_history rpm_installed    # Use pattern directly"
        echo "  cleanup_history                   # Prompt for pattern"
        echo "  cleanup_history 'git push'        # Quotes for spaces"
        echo "  cleanup_history -h                # Show this help"
        echo ""
        echo "Enter numbers (space-separated), 'all', or 'n/q' to quit."
        return
    end
    
    set -l pattern $argv[1]
    
    if test -z "$pattern"
        echo "Enter pattern to search in history:"
        read -l pattern
    end
    
    if test -z "$pattern"
        echo "No pattern provided. Aborted."
        return
    end
    
    set -l matches (history search --contains $pattern --max 100)
    if test (count $matches) -eq 0
        echo "No matching entries found."
        return
    end
    
    echo "Matching entries:"
    for i in (seq (count $matches))
        echo "$i: "$matches[$i]
    end
    
    while true
        echo "Enter numbers (space-separated), 'all', or 'n/q' to quit:"
        read -l selection
        
        # Check quit FIRST - before numeric processing
        switch $selection
            case '' 'n' 'N' 'q' 'Q' 'quit' 'exit'
                echo "Aborted."
                break
            case 'all' 'ALL'
                # Fixed: Use --exact to avoid interactive prompt from history delete
                for cmd in $matches
                    history delete --exact --case-sensitive "$cmd"
                end
                echo "Deleted all matching entries."
                break
        end
        
        # Only process numbers if not quit/all
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
                history delete --exact --case-sensitive $cmd
                echo "Deleted: $cmd"
            end
            echo "Deleted "(count $valid_nums)" entries."
            
            # Use read with prompt
            read -l -P "Continue deleting more? [y/N]: " continue
            if not string match -qi 'y*' $continue
                break
            end
        else
            echo "Ignored invalid entries: "(string join ", " $invalid_nums)"."
            echo "Enter valid numbers, 'all', or 'n/q' to quit."
        end
    end
    
    echo "Done."
end

