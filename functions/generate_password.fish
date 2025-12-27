function generate_password --description "Generate secure passwords using pwgen"
    set -l length $argv[1]
    set -l count  $argv[2]
    set -l arg    $argv[1]

    # ---- Help flag ----
    if test "$arg" = "-h" -o "$arg" = "--help"
        echo "generate_password — generate secure random passwords using pwgen"
        echo
        echo "USAGE:"
        echo "  generate_password [LENGTH] [COUNT]"
        echo
        echo "ARGUMENTS:"
        echo "  LENGTH   Length of each password (default: 16)"
        echo "  COUNT    Number of passwords to generate (default: 1)"
        echo
        echo "EXAMPLES:"
        echo "  generate_password         # prompts for length and count"
        echo "  generate_password 20 5    # generate 5 passwords of length 20"
        return 0
    end

    # ---- Ensure pwgen is available ----
    if not type -q pwgen
        echo "❌ Error: 'pwgen' is required but not installed."
        return 1
    end

    # ---- Prompt for length if missing ----
    if test -z "$length"
        read --prompt-str "Enter password length [16]: " length
    end
    set -l length (or $length 16)

    # Validate length is a positive integer
    if not string match -qr '^[0-9]+$' "$length"
        echo "❌ Invalid length: '$length'. Must be a positive number."
        return 1
    end

    # ---- Prompt for count if missing ----
    if test -z "$count"
        read --prompt-str "Enter number of passwords [1]: " count
    end
    set -l count (or $count 1)

    # Validate count is a positive integer
    if not string match -qr '^[0-9]+$' "$count"
        echo "❌ Invalid count: '$count'. Must be a positive number."
        return 1
    end

    # ---- Generate passwords ----
    pwgen -1 -s -y -c "$length" "$count"
end
