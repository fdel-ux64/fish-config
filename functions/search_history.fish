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
                echo "  • Range selection support (e.g. 2-5, or mixed: 2-5 7 9)"
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
        read -l -P "🧹 Clean up entries? [all/select/NUMBERS/RANGE(e.g.2-5)/N]: " cleanup_choice
        
        # Parse numbers and/or ranges from a token list into a deduplicated sorted list.
        # Tokens can be plain numbers ("3") or ranges ("2-5"). Reversed ranges ("5-2")
        # are normalised automatically. Out-of-bound values are silently dropped here;
        # callers report invalids separately.
        #
        # Usage: _parse_tokens_to_indices TOTAL_COUNT TOKEN …
        #   Prints one index per line, sorted, unique, within [1, TOTAL_COUNT].
        function _parse_tokens_to_indices
            set -l total $argv[1]
            set -l raw_indices
            for token in $argv[2..]
                if string match -qr '^[0-9]+-[0-9]+$' -- $token
                    # Range token  e.g. "2-5"
                    set -l parts (string split '-' $token)
                    set -l lo $parts[1]
                    set -l hi $parts[2]
                    # Normalise reversed ranges
                    if test $lo -gt $hi
                        set -l tmp $lo; set lo $hi; set hi $tmp
                    end
                    for n in (seq $lo $hi)
                        set -a raw_indices $n
                    end
                else if string match -qr '^[0-9]+$' -- $token
                    set -a raw_indices $token
                end
            end
            # Filter to valid range, sort, deduplicate
            printf '%s\n' $raw_indices \
                | awk -v max=$total '$1>=1 && $1<=max' \
                | sort -n \
                | uniq
        end

        # Check if input is 'all'
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
                # Enter interactive selection mode (original workflow)
                set cleanup_choice ""  # Reset for the loop
        end
        
        # Check if direct numbers/ranges were provided
        set -l initial_nums
        if test -n "$cleanup_choice"
            set -l tokens (string split " " $cleanup_choice)
            set initial_nums (_parse_tokens_to_indices (count $matches) $tokens)
            # Warn about unrecognised tokens
            set -l invalid_tokens
            for token in $tokens
                if not string match -qr '^[0-9]+$|^[0-9]+-[0-9]+$' -- $token
                    set -a invalid_tokens $token
                end
            end
            if test (count $invalid_tokens) -gt 0
                echo "  ⚠️  Ignored unrecognised tokens: "(string join ", " $invalid_tokens)
            end
        end
        
        # If valid numbers were provided directly, process them
        if test (count $initial_nums) -gt 0
            for num in $initial_nums
                set -l cmd $matches[$num]
                history delete --exact --case-sensitive "$cmd"
                echo "  ✅ Deleted: $cmd"
            end
            echo "Deleted "(count $initial_nums)" entries."
            
            read -l -P "Continue deleting more? [y/N]: " continue
            if not string match -qi 'y*' $continue
                echo "Done."
                return 0
            end
            # If yes, continue to interactive loop below
        end
        
        # Interactive cleanup loop for selective deletion
        while true
            echo "Enter numbers, ranges (e.g. 2-5), or mixed (e.g. 2-5 7), or 'q' to quit:"
            read -l selection
            
            # Check quit
            switch $selection
                case '' 'n' 'N' 'q' 'Q' 'quit' 'exit'
                    echo "Cleanup finished."
                    break
            end
            
            # Parse numbers and ranges, deduplicated
            set -l tokens (string split " " $selection)
            set -l valid_nums (_parse_tokens_to_indices (count $matches) $tokens)

            # Collect unrecognised tokens for warning
            set -l invalid_tokens
            for token in $tokens
                if not string match -qr '^[0-9]+$|^[0-9]+-[0-9]+$' -- $token
                    set -a invalid_tokens $token
                end
            end
            # Out-of-bound numbers (recognised format but outside list)
            for token in $tokens
                if string match -qr '^[0-9]+$' -- $token
                    if test $token -lt 1 -o $token -gt (count $matches)
                        set -a invalid_tokens $token
                    end
                else if string match -qr '^[0-9]+-[0-9]+$' -- $token
                    set -l parts (string split '-' $token)
                    set -l lo $parts[1]; set -l hi $parts[2]
                    if test $lo -gt $hi; set -l tmp $lo; set lo $hi; set hi $tmp; end
                    if test $lo -lt 1 -o $hi -gt (count $matches)
                        set -a invalid_tokens $token
                    end
                end
            end
            
            if test (count $valid_nums) -gt 0
                for num in $valid_nums
                    set -l cmd $matches[$num]
                    history delete --exact --case-sensitive "$cmd"
                    echo "  ✅ Deleted: $cmd"
                end
                echo "Deleted "(count $valid_nums)" entries."
                
                read -l -P "Continue deleting more? [y/N]: " continue
                if not string match -qi 'y*' $continue
                    break
                end
            else
                if test (count $invalid_tokens) -gt 0
                    echo "  ⚠️  Ignored invalid entries: "(string join ", " $invalid_tokens)
                end
                echo "Enter valid numbers/ranges or 'q' to quit."
            end
        end
        
        echo "Done."
    end
end
