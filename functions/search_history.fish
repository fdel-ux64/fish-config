function search_history --description "Search fish command history with optional cleanup"
    # ---- Help flag ----
    if test (count $argv) -gt 0
        switch $argv[1]
            case -h --help
                echo "search_history — search fish command history with optional cleanup"
                echo
                echo "USAGE:"
                echo "  search_history [OPTIONS] [PATTERN]"
                echo "  search_history              # interactive prompt mode"
                echo "  search_history PATTERN      # search for pattern"
                echo "  search_history -c PATTERN   # search and offer cleanup"
                echo
                echo "OPTIONS:"
                echo "  -c, --cleanup    Offer to clean up matching entries after search"
                echo "  -h, --help       Show this help"
                echo
                echo "FEATURES:"
                echo "  • Uses ripgrep (rg) if available, falls back to grep"
                echo "  • Case-insensitive search by default"
                echo "  • Can be bound to CTRL+H for quick access"
                echo "  • Optional interactive cleanup of search results"
                echo
                echo "EXAMPLES:"
                echo "  search_history git              # find all git commands"
                echo "  search_history -c 'git push'    # search and offer cleanup"
                echo "  search_history rpm install      # find rpm install commands"
                echo "  search_history                  # interactive prompt"
                return 0
        end
    end
    
    # ---- Parse options ----
    set -l cleanup_mode 0
    set -l pattern_args
    
    for arg in $argv
        switch $arg
            case -c --cleanup
                set cleanup_mode 1
            case '-*'
                echo "Unknown option: $arg"
                echo "Run 'search_history --help' for usage."
                return 1
            case '*'
                set -a pattern_args $arg
        end
    end
    
    # ---- Interactive prompt mode (no arguments) ----
    if test (count $pattern_args) -eq 0
        read --prompt-str "🔍 History search > " query
        if test -z "$query"
            # Empty input - show recent history
            history | tail -20
            return 0
        end
        set pattern_args $query
        
        # Ask if user wants cleanup option in interactive mode
        read -l -P "Enable cleanup mode? [y/N]: " enable_cleanup
        if string match -qi 'y*' $enable_cleanup
            set cleanup_mode 1
        end
    end
    
    # ---- Search with pattern ----
    set -l query (string join ' ' -- $pattern_args)
    
    echo -e "\n   🔍 Searching history for: \"$query\""
    echo "  ╰──────────────────────────────────────────"
    echo
    
    # Use Fish's built-in history search for exact matching (needed for cleanup)
    set -l matches (history search --contains $query --max 100)
    
    # Display results
    if test (count $matches) -eq 0
        echo "No matches found for \"$query\""
        echo
        return 0
    end
    
    # Show numbered results if cleanup mode, otherwise just list
    if test $cleanup_mode -eq 1
        for i in (seq (count $matches))
            echo "  $i: $matches[$i]"
        end
    else
        for line in $matches
            echo "  $line"
        end
    end
    
    echo -e " \n ─────────────────────────────────"
    echo -e " 🔢 Total matches: "(count $matches)"\n"
    
    # ---- Cleanup integration ----
    if test $cleanup_mode -eq 1
        read -l -P "🧹 Clean up entries? [all/select/N]: " cleanup_choice
        
        switch $cleanup_choice
            case '' 'n' 'N' 'no' 'quit' 'q' 'Q'
                echo "Skipped cleanup."
                return 0
            case 'all' 'ALL' 'a' 'A'
                for cmd in $matches
                    history delete --exact --case-sensitive "$cmd"
                end
                echo "✅ Deleted all "(count $matches)" matching entries."
                echo "Done."
                return 0
            case 'select' 'SELECT' 's' 'S' 'sel'
                # Continue to interactive selection
            case '*'
                echo "Invalid choice. Use 'all', 'select', or 'n' to skip."
                return 0
        end
        
        # Interactive cleanup loop for selective deletion
        while true
            echo "Enter numbers (space-separated) or 'q' to quit:"
            read -l selection
            
            # Check quit
            switch $selection
                case '' 'n' 'N' 'q' 'Q' 'quit' 'exit'
                    echo "Cleanup finished."
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
                    history delete --exact --case-sensitive $cmd
                    echo "  ✅ Deleted: $cmd"
                end
                echo "Deleted "(count $valid_nums)" entries."
                
                read -l -P "Continue deleting more? [y/N]: " continue
                if not string match -qi 'y*' $continue
                    break
                end
            else
                if test (count $invalid_nums) -gt 0
                    echo "  ⚠️  Ignored invalid entries: "(string join ", " $invalid_nums)
                end
                echo "Enter valid numbers or 'q' to quit."
            end
        end
        
        echo "Done."
    end
end
