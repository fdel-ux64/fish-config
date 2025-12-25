function showfunc --description "Search, display, and optionally edit fish functions"
    # Ensure a clean line at start
    echo ""
    commandline -f repaint

    # Prompt for function name or pattern
    read -P "Function name or pattern: " query

    if test -z "$query"
        echo "No input provided."
        return 1
    end

    # Add wildcard if no * present
    if not string match -q '*\**' "$query"
        set pattern "*$query*"
    else
        set pattern "$query"
    end

    # Find matches
    set matches (functions -a | string match "$pattern")

    if test (count $matches) -eq 0
        echo "No matching functions found."
        return 1
    end

    # Handle multiple matches
    if test (count $matches) -gt 1
        if type -q fzf
            # Use fuzzy search
            echo "Multiple matches found. Use fuzzy search to pick one:"
            set fname (printf "%s\n" $matches | fzf --prompt="Pick function> " --height 40% --border --ansi)
            if test -z "$fname"
                echo "No function selected."
                return 1
            end
        else
            # Fallback to numbered selection
            echo "Multiple matches found. fzf not available, falling back to numbered selection:"
            for i in (seq (count $matches))
                printf "%2d) %s\n" $i $matches[$i]
            end
            echo ""
            commandline -f repaint
            read -P "Pick a number: " choice
            if not string match -qr '^[0-9]+$' "$choice"
                echo "Invalid selection."
                return 1
            end
            if test $choice -lt 1 -o $choice -gt (count $matches)
                echo "Choice out of range."
                return 1
            end
            set fname $matches[$choice]
        end
    else
        set fname $matches[1]
    end

    # Show the function and its origin
    echo ""
    echo "Function: $fname"
    echo "────────────────────────────"

    set funcfile ~/.config/fish/functions/$fname.fish

    if test -f $funcfile
        set origin "User-defined: $funcfile"
    else if functions -q $fname
        set origin "Defined via plugin or autoload (not in user file)"
    else
        set origin "Unknown source"
    end

    echo "Origin: $origin"
    echo ""

    # Show content with syntax highlighting
    if type -q bat
        functions $fname | bat --language fish --style=plain
    else
        functions $fname
    end

    # Ask for editing (only for user-defined functions)
    echo ""
    commandline -f repaint
    if test -f $funcfile
        read -P "Edit this function? (y/N) " answer
        if string match -qi 'y' "$answer"
            $EDITOR $funcfile
            source $funcfile
            echo "Function '$fname' reloaded from file."
        end
    else
        echo "Function is managed by plugin or autoload; editing skipped."
    end
end
