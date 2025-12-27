function shisto_prompt --description "Prompted history search"
    read --prompt-str "History search > " query

    if test -n "$query"
        shisto "$query"
    else
        history
    end
end
