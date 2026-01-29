function clean_session_history --description "Clear fish session history with confirmation and countdown"
    # ---- Defaults ----
    set -l immediate 0
    set -l wait_time 10
    # ---- Argument parsing ----
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: cleanh [OPTIONS]"
                echo
                echo "Clear the current fish session history."
                echo
                echo "Options:"
                echo "  -y, --yes           Clear immediately (no prompt, no delay)"
                echo "  -w, --wait SECONDS  Wait time before clearing (default: 10)"
                echo "  -h, --help          Show this help message"
                return 0
            case -y --yes
                set immediate 1
            case -w --wait
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "Error: --wait requires a value."
                    return 1
                end
                set wait_time $argv[$i]
                if not string match -qr '^[0-9]+$' $wait_time
                    echo "Error: --wait must be a number."
                    return 1
                end
            case '*'
                echo "Unknown option: $argv[$i]"
                echo "Use --help to see available options."
                return 1
        end
        set i (math $i + 1)
    end
    # ---- Non-interactive safety ----
    if not status is-interactive; and test $immediate -eq 0
        echo "Non-interactive shell detected."
        echo "Use --yes to proceed."
        return 1
    end
    # ---- Immediate mode ----
    if test $immediate -eq 1
        history clear-session
        echo "Session history cleared."
        return 0
    end
    # ---- Confirmation ----
    read --prompt-str "Clear session history in $wait_time seconds? [y/N] " answer
    if not string match -qr '^(y|yes)$' (string lower $answer)
        echo "Aborted."
        return 0
    end
    # ---- Countdown progress bar ----
    echo "Clearing session history..."
    set -l width 30
    for elapsed in (seq 0 (math $wait_time - 1))
        set percent (math --scale=0 "($elapsed * 100) / $wait_time")
        set filled (math --scale=0 "($elapsed * $width) / $wait_time")
        set empty (math --scale=0 "$width - $filled")
        printf "\r[%s%s] %3d%%" \
            (string repeat -n $filled "=") \
            (string repeat -n $empty " ") \
            $percent
        sleep 1
    end
    printf "\r[%s] 100%%\n" (string repeat -n $width "=")
    # ---- Clear history ----
    history clear-session
    echo "Session history cleared."
end
