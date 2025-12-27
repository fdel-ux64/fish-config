function shisto --description "Search fish history (optionally with a query)"
    if test (count $argv) -eq 0
        history
        return
    end

    set -l query (string join ' ' -- $argv)

    if type -q rg
        history | rg -i -- "$query"
    else
        history | grep -i -- "$query"
    end
end
