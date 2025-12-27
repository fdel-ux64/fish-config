function showfunc --description "Search, display, and optionally edit fish functions"
    # Prompt for function name or pattern
    read --prompt-str "Function name or pattern: " query
    test -z "$query"; and return 1

    # Add wildcard if needed
    string match -q '*\**' -- "$query"
    or set query "*$query*"

    # Find matches
    set -l matches (functions -a | string match "$query")
    test (count $matches) -gt 0
    or begin
        echo "No matching functions found."
        return 1
    end

    # Select function
    if test (count $matches) -gt 1
        if type -q fzf
            set -l fname (printf "%s\n" $matches | fzf --prompt="Pick function> " --height 40% --border)
            test -n "$fname"; or return 1
        else
            for i in (seq (count $matches))
                printf "%2d) %s\n" $i $matches[$i]
            end
            read --prompt-str "Pick a number: " choice
            string match -qr '^[0-9]+$' -- "$choice"; or return 1
            test $choice -ge 1 -a $choice -le (count $matches); or return 1
            set -l fname $matches[$choice]
        end
    else
        set -l fname $matches[1]
    end

    # Resolve function file
    set -l funcfile (status fish-path)/functions/$fname.fish

    echo ""
    echo "Function: $fname"
    echo "────────────────────────────"

    if test -f "$funcfile"
        echo "Origin: User-defined ($funcfile)"
    else
        echo "Origin: Plugin or autoloaded"
    end
    echo ""

    # Show content
    if type -q bat
        functions $fname | bat --language fish --style=plain
    else
        functions $fname
    end

    # Edit if allowed
    if test -f "$funcfile"
        read -P "Edit this function? (y/N) " answer
        switch $answer
            case y Y
                command $EDITOR "$funcfile"
                source "$funcfile"
                echo "Function '$fname' reloaded."
        end
    end
end
