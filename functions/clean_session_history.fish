function clean_session_history --description "Clear fish session history with confirmation and countdown"
    # ---- Defaults ----
    set -l immediate 0
    set -l wait_time 10
    # ---- Argument parsing ----
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -h --help
                echo "Usage: clean_session_history [OPTIONS]"
                echo
                echo "Clear the current fish session history."
                echo
                echo "Options:"
                echo "  -y, --yes           Clear immediately (no countdown, no prompt)"
                echo "  -w, --wait SECONDS  Countdown duration in seconds (default: 10, max: 60)"
                echo "  -h, --help          Show this help message"
                echo
                echo "Examples:"
                echo "  clean_session_history          # 10s countdown, then confirm"
                echo "  clean_session_history -y       # clear instantly"
                echo "  clean_session_history -w 5     # 5s countdown, then confirm"
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
                    echo "Error: --wait must be a non-negative integer."
                    return 1
                end
                if test $wait_time -gt 60
                    echo "Error: --wait maximum is 60 seconds."
                    return 1
                end
            case '*'
                echo "Unknown option: $argv[$i]"
                echo
                echo "Options:"
                echo "  -y, --yes           Clear immediately (no countdown, no prompt)"
                echo "  -w, --wait SECONDS  Countdown duration in seconds (default: 10, max: 60)"
                echo "  -h, --help          Show this help message"
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
        history clear-session 1>/dev/null; or begin
            echo "Error: failed to clear session history."
            return 1
        end
        echo "Session history cleared."
        return 0
    end
    # ---- Countdown progress bar ----
    echo "Counting down — press Ctrl-C at any time to abort."
    set -l width 30

    for elapsed in (seq 0 (math $wait_time - 1))
        set -l percent (math --scale=0 "($elapsed * 100) / $wait_time")
        set -l filled (math --scale=0 "($elapsed * $width) / $wait_time")
        set -l empty (math --scale=0 "$width - $filled")

        command printf "\r[%s%s] %3d%%\033[K" \
            (string repeat -n $filled "=") \
            (string repeat -n $empty " ") \
            $percent

        sleep 1
    end

    command printf "\r[%s] 100%%\033[K\n" (string repeat -n $width "=")
    # ---- Confirmation after countdown ----
    read -l --prompt-str "Clear session history now? [y/N] " answer
    if not string match -qr '^(y|yes)$' (string lower $answer)
        echo "Aborted."
        return 0
    end
    # ---- Clear history ----
    history clear-session 1>/dev/null; or begin
        echo "Error: failed to clear session history."
        return 1
    end
    echo "Session history cleared."
end
