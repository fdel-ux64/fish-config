function generate_password
    set -l length $argv[1]
    set -l count  $argv[2]

    # Character set
    set -l charset "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-+;:,!&'({*?|}%"
    set -l charset_len (string length $charset)

    # Clipboard timeout (seconds)
    set -l clipboard_timeout 30

    # Help
    if contains -- '--help' $argv || contains -- '-h' $argv
        echo "generate_password — generate secure random passwords"
        echo
        echo "USAGE: generate_password [LENGTH] [COUNT]"
        echo "Defaults: LENGTH=16, COUNT=1"
        echo
        echo "Wayland extra: if wl-clipboard is installed,"
        echo "the first password is copied to clipboard for $clipboard_timeout seconds."
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

    # Validate
    if not string match -qr '^[0-9]+$' "$length"
        echo "❌ Invalid length: $length"
        return 1
    end
    if not string match -qr '^[0-9]+$' "$count"
        echo "❌ Invalid count: $count"
        return 1
    end

    set -l first_password ""

    # Generate passwords
    for i in (seq $count)
        set -l password ""

        for j in (seq $length)
            set -l idx (random 1 $charset_len)
            set password "$password"(string sub -s $idx -l 1 "$charset")
        end

        if test $i -eq 1
            set first_password $password
        end

        echo $password
    end

    # Wayland clipboard handling (polite & informative)
    if test -n "$first_password"
        if type -q wl-copy
            echo -n "$first_password" | wl-copy
            echo "📋 First password copied to clipboard (clears in $clipboard_timeout s)"

            # Auto-clear clipboard
            fish -c "sleep $clipboard_timeout; echo -n '' | wl-copy" >/dev/null 2>&1 &
        else
            echo "ℹ️  Tip: install wl-clipboard to auto-copy the first password to clipboard for $clipboard_timeout seconds"
        end
    end
end

