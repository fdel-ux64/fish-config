function generate_password
    # Clipboard defaults
    set -l no_clipboard 0
    set -l clipboard_timeout 30

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

    set argv $clean_argv

    set -l length $argv[1]
    set -l count  $argv[2]

    # Character set
    set -l charset "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-+;:,!&'({*?|}%"
    set -l charset_len (string length $charset)

    # Help
    if contains -- '--help' $argv || contains -- '-h' $argv
        echo "generate_password — generate secure random passwords"
        echo
        echo "USAGE: generate_password [OPTIONS] [LENGTH] [COUNT]"
        echo
        echo "Options:"
        echo "  --no-clipboard              Disable clipboard auto-copy"
        echo "  --clipboard-timeout <sec>   Clipboard clear timeout (default: 30)"
        echo "  -h, --help                  Show this help"
        echo
        echo "Defaults: LENGTH=16, COUNT=1"
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

    # Validate
    if not string match -qr '^[0-9]+$' -- "$length"
        echo "❌ Invalid length: $length"
        return 1
    end
    if not string match -qr '^[0-9]+$' -- "$count"
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

    # Clipboard handling
    if test -n "$first_password"
        if test $no_clipboard -eq 1
            echo "ℹ️  Clipboard copy disabled (--no-clipboard)"
        else if set -q WAYLAND_DISPLAY
            if type -q wl-copy
                echo -n "$first_password" | wl-copy
                echo "📋 First password copied to clipboard (clears in $clipboard_timeout s)"

                # Auto-clear clipboard
                fish -c "sleep $clipboard_timeout; echo -n '' | wl-copy" >/dev/null 2>&1 &
            else
                echo "ℹ️  Tip: install wl-clipboard to auto-copy the first password to clipboard"
            end
        else
            echo "ℹ️  Clipboard copy skipped (no Wayland session detected)"
        end
    end
end

