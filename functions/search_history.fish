function search_history --description "Search fish command history with optional pattern"
    # ---- Help flag ----
    if test (count $argv) -gt 0
        switch $argv[1]
            case -h --help
                echo "search_history — search fish command history"
                echo
                echo "USAGE:"
                echo "  search_history [PATTERN]"
                echo "  search_history              # interactive prompt mode"
                echo "  search_history PATTERN      # search for pattern"
                echo
                echo "FEATURES:"
                echo "  • Uses ripgrep (rg) if available, falls back to grep"
                echo "  • Case-insensitive search by default"
                echo "  • Can be bound to CTRL+H for quick access"
                echo
                echo "EXAMPLES:"
                echo "  search_history git          # find all git commands"
                echo "  search_history rpm install  # find rpm install commands"
                echo "  search_history              # interactive prompt"
                return 0
        end
    end
    
    # ---- Interactive prompt mode (no arguments) ----
    if test (count $argv) -eq 0
        read --prompt-str "🔍 History search > " query
        if test -z "$query"
            # Empty input - show recent history
            history | tail -20
            return 0
        end
        set argv $query
    end
    
    # ---- Search with pattern ----
    set -l query (string join ' ' -- $argv)
    
    echo -e "\n   🔍 Searching history for: \"$query\""
    echo "  ╰──────────────────────────────────────────"
    echo
    
    # Use ripgrep if available, otherwise fall back to grep
    set -l results
    if type -q rg
        set results (history | rg -i -- "$query")
    else
        set results (history | grep -i -- "$query")
    end
    
    # Display results
    if test (count $results) -gt 0
        for line in $results
            echo " " $line
        end
        echo -e " \n ─────────────────────────────────"
        echo -e " 🔢 Total matches: "(count $results)"\n"
    else
        echo "No matches found for \"$query\""
        echo
    end
end
