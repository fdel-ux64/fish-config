function generate_password
    # Clipboard defaults
    set -l no_clipboard 0
    set -l clipboard_timeout 30
    set -l no_ambiguous 0

    # Parse flags
    set -l clean_argv
    set -l expect_timeout 0
    for arg in $argv
        if test $expect_timeout -eq 1
            if string match -qr '^[0-9]+$' "$arg"
                set clipboard_timeout $arg
                set expect_timeout 0
                continue
            else
                echo "❌ Invalid value for --clipboard-timeout: $arg"
                return 1
            end
        end
        switch $arg
            case '--no-clipboard'
                set no_clipboard 1
            case '--clipboard-timeout'
                set expect_timeout 1
            case '--no-ambiguous'
                set no_ambiguous 1
            case '--help' '-h'
                set clean_argv $clean_argv $arg
            case '*'
                set clean_argv $clean_argv $arg
        end
    end

    if test $expect_timeout -eq 1
        echo "❌ --clipboard-timeout requires a numeric value"
        return 1
    end

    # FIX: reject --clipboard-timeout 0
    if test $clipboard_timeout -lt 1
        echo "❌ --clipboard-timeout must be at least 1 second"
        return 1
    end

    set argv $clean_argv
    set -l length $argv[1]
    set -l count  $argv[2]

    # Help
    if contains -- '--help' $argv || contains -- '-h' $argv
        echo "generate_password — generate secure random passwords"
        echo
        echo "USAGE: generate_password [OPTIONS] [LENGTH] [COUNT]"
        echo
        echo "Options:"
        echo "  --no-clipboard              Disable clipboard auto-copy"
        echo "  --clipboard-timeout <sec>   Clipboard clear timeout in seconds (default: 30, min: 1)"
        echo "  --no-ambiguous              Exclude visually similar chars (0,O,l,1,|,I)"
        echo "  -h, --help                  Show this help"
        echo
        echo "Defaults: LENGTH=16, COUNT=1 — minimum length is 3, recommended minimum is 12"
        echo
        echo "Wayland extra:"
        echo "If wl-clipboard is installed and clipboard is enabled,"
        echo "the first password is copied to clipboard for the specified duration."
        return 0
    end

    # Prompt for length
    if test -z "$length"
        read --prompt-str "Enter password length [16]: " length
        test -z "$length"; and set length 16
    end

    # Prompt for count
    if test -z "$count"
        read --prompt-str "Enter number of passwords [1]: " count
        test -z "$count"; and set count 1
    end

    # Validate length
    if not string match -qr '^[0-9]+$' -- "$length"
        echo "❌ Invalid length: $length"
        return 1
    end
    if test $length -lt 3
        echo "❌ Length must be at least 3"
        return 1
    end

    # Validate count — FIX: reject 0
    if not string match -qr '^[0-9]+$' -- "$count"
        echo "❌ Invalid count: $count"
        return 1
    end
    if test $count -lt 1
        echo "❌ Count must be at least 1"
        return 1
    end

    # Entropy warning
    if test $length -lt 12
        echo "⚠️  Warning: length $length is below the recommended minimum of 12"
    end

    # Character sets
    set -l charset  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-+;:,!&'({*?|}%@#\$^~=_.<>[])\""
    set -l digits   "0123456789"
    set -l specials "/-+;:,!&'({*?|}%@#\$^~=_.<>[])\""

    if test $no_ambiguous -eq 1
        set charset  (string replace -a -r '[0Ol1|I]' "" $charset)
        set digits   (string replace -a -r '[01]'     "" $digits)
        set specials (string replace -a -r '[|I]'     "" $specials)
        echo "ℹ️  Ambiguous characters excluded (0,O,l,1,|,I)"
    end

    set -l charset_len  (string length $charset)
    set -l digits_len   (string length $digits)
    set -l specials_len (string length $specials)

    # FIX: rejection-sampling to eliminate modulo bias
    # Reads 2 bytes (0–65535) and rejects values that would cause bias.
    # The rejection threshold is (65536 % pool_len): values in that tail are dropped.
    function _secure_rand_char
        set -l pool $argv[1]
        set -l pool_len (string length $pool)
        set -l limit (math "65536 - (65536 % $pool_len)")
        while true
            set -l raw (od -A n -N 2 -t u2 /dev/urandom | string trim)
            if test $raw -lt $limit
                set -l idx (math "$raw % $pool_len + 1")
                string sub -s $idx -l 1 $pool
                return
            end
        end
    end

    set -l first_password ""

    for i in (seq $count)
        # Guarantee one digit + one special, fill rest from full charset
        set -l g_digit   (_secure_rand_char $digits)
        set -l g_special (_secure_rand_char $specials)

        set -l remaining (math $length - 2)
        set -l chars $g_digit $g_special
        for j in (seq $remaining)
            set chars $chars (_secure_rand_char $charset)
        end

        # Fisher-Yates shuffle
        set -l len (count $chars)
        for k in (seq $len -1 2)
            set -l pool_len $k
            set -l limit (math "65536 - (65536 % $pool_len)")
            while true
                set -l raw (od -A n -N 2 -t u2 /dev/urandom | string trim)
                if test $raw -lt $limit
                    set -l j_idx (math "$raw % $pool_len + 1")
                    set -l tmp $chars[$k]
                    set chars[$k] $chars[$j_idx]
                    set chars[$j_idx] $tmp
                    break
                end
            end
        end

        set -l password (string join "" $chars)

        if test $i -eq 1
            set first_password $password
        end
        echo $password
    end

    # FIX: clean up the internal helper so it doesn't leak into the global scope
    functions -e _secure_rand_char

    # Clipboard handling
    if test $no_clipboard -eq 1
        echo "ℹ️  Clipboard copy disabled (--no-clipboard)"
    else if set -q WAYLAND_DISPLAY
        if type -q wl-copy
            echo -n "$first_password" | wl-copy
            echo "📋 First password copied to clipboard (clears in $clipboard_timeout s)"
            if type -q systemd-run
                systemd-run --user --no-block -- \
                    sh -c "sleep $clipboard_timeout; echo -n '' | wl-copy" >/dev/null 2>&1
                # FIX: warn if systemd-run fails (non-zero exit)
                if test $status -ne 0
                    echo "⚠️  systemd-run failed — clipboard may not be cleared automatically"
                end
            else
                nohup fish -c "sleep $clipboard_timeout; echo -n '' | wl-copy" >/dev/null 2>&1 &
            end
        else
            echo "ℹ️  Tip: install wl-clipboard to auto-copy the first password to clipboard"
        end
    else
        echo "ℹ️  Clipboard copy skipped (no Wayland session detected)"
    end
end
