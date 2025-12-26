function shisto_prompt
    read -P "History search > " query

    if test -n "$query"
        shisto $query
    else
        history
    end

    commandline -f repaint
end
