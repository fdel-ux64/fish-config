function shisto
    if test (count $argv) -eq 0
        history
    else
        history | rg -i -- $argv
    end
end

