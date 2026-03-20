function inspect_function --description "Search, display, and optionally edit fish functions"
    # Guard: must be interactive
    if not isatty stdin
        echo "inspect_function requires an interactive terminal."
        return 1
    end

    # Accept optional argument as initial query
    if test (count $argv) -ge 1
        set query $argv[1]
    else
        set query ""
    end

    # Prompt for function name or pattern if not provided
    if test -z "$query"
        echo ""
        read --prompt-str "Function name or pattern: " query
        if test -z "$query"
            echo "No input provided."
            return 1
        end
    end

    # Add wildcard if no * present (use regex to check)
    if not string match -qr '\*' "$query"
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

    # Validate selected function (fzf could return anything)
    if not functions -q "$fname"
        echo "Invalid function: $fname"
        return 1
    end

    # Resolve actual source file via fish's own lookup
    set funcfile (functions --details $fname)

    # Show function header and origin
    echo ""
    echo "Function: $fname"
    echo "────────────────────────────"
    if test "$funcfile" = stdin
        set origin "Defined interactively (stdin)"
        set funcfile ""
    else if test -n "$funcfile" -a -f "$funcfile"
        set origin "User-defined: $funcfile"
    else
        set origin "Plugin or autoload (source not editable)"
        set funcfile ""
    end
    echo "Origin: $origin"
    echo ""

    # Display function content — pipe directly to avoid list/newline issues
    if type -q bat
        functions $fname | bat --language fish --style=plain --paging=never
    else
        set line_count (functions $fname | count)
        if test $line_count -gt (tput lines)
            functions $fname | less
        else
            functions $fname
        end
    end

    # Optional editing — only for real files we own
    if test -n "$funcfile"
        echo ""
        # Default $EDITOR if unset
        set -q EDITOR; or set -l EDITOR vim
        read --prompt-str "Edit this function? (y/N) " answer
        if string match -qi 'y' "$answer"
            $EDITOR $funcfile
            # Syntax-check before sourcing
            if fish --no-execute $funcfile 2>/dev/null
                source $funcfile
                echo "Function '$fname' reloaded from file."
            else
                echo "Syntax error detected in $funcfile — not reloaded. Fix and source manually."
                return 1
            end
        end
    else
        echo "Function is managed by plugin or autoload; editing skipped."
    end
end
