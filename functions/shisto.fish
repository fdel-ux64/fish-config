function shisto --description "Search fish history (optionally with a query)"
    if test (count $argv) -eq 0
        history
    else
        set -l query (string join ' ' -- $argv)
        history | rg -i -- "$query"
    end
end

