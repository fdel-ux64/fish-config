function inspect_function --description "Search, display, and optionally edit fish functions"
    # Accept optional argument as initial query
    if test (count $argv) -ge 1
        set query $argv[1]
    else
        set query ""
    end

    # Prompt for function name or pattern if not provided
    if test -z "$query"
        echo ""
        commandline -f repaint
        read --prompt-str "Function name or pattern: " query
        if test -z "$query"
            echo "No input provided."
            return 1
        end
    end

    # Add wildcard if no * present
    if not string match -q '*\**' "$query"
        set pattern "*$query*"
    else
        set pattern "$query"
    end

    # Find matching functions
    set matches (functions -a | string match "$pattern")

    if test (count $matches) -eq 0
        echo "No matching functions found."
        return 1
    end

    # Handle multiple matches
    if test (count $matches) -gt 1
        if type -q fzf
            echo "Multiple matches found. Use fuzzy search to pick one:"
            set fname (printf "%s\n" $matches | fzf --prompt="Pick function> " --height 40% --border --ansi)
            if test -z "$fname"
                echo "No function selected."
                return 1
            end
        else
            echo "Multiple matches found. Choose a number:"
            for i in (seq (count $matches))
                printf "%2d) %s\n" $i $matches[$i]
            end
            echo ""
            commandline -f repaint
            read --prompt-str "Pick a number: " choice
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

    # Show function header and origin
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

    # Display function content with pager logic
    set func_content (functions $fname)
    if type -q bat
        # Bat handles paging internally
        printf "%s\n" $func_content | bat --language fish --style=plain --paging=never
    else
        # Use less only if content exceeds terminal height
        if test (count (string split \n $func_content)) -gt (tput lines)
            printf "%s\n" $func_content | less
        else
            printf "%s\n" $func_content
        end
    end

    # Optional editing for user-defined functions
    if test -f $funcfile
        echo ""
        commandline -f repaint
        read --prompt-str "Edit this function? (y/N) " answer
        if string match -qi 'y' "$answer"
            $EDITOR $funcfile
            source $funcfile
            echo "Function '$fname' reloaded from file."
        end
    else
        echo "Function is managed by plugin or autoload; editing skipped."
    end
end
