function generate_password
    set -l xx $argv[1]
    set -l zz $argv[2]

    # ---- Help flag ----
    if contains -- '--help' $argv || contains -- '-h' $argv
        echo "generate_password — generate secure random passwords using Fish random"
        echo
        echo "USAGE:"
        echo "  generate_password [LENGTH] [COUNT]"
        echo
        echo "If LENGTH or COUNT are not provided, you will be prompted."
        echo "Defaults: LENGTH=16, COUNT=1"
        echo
        echo "EXAMPLES:"
        echo "  generate_password          # prompts for length and count"
        echo "  generate_password 20 5     # generate 5 passwords of length 20"
        return 0
    end

    # Prompt for password length if not provided
    if test -z "$xx"
        read --prompt-str "Enter password length [16]: " xx
        if test -z "$xx"
            set xx 16
        end
    end

    # Prompt for number of passwords if not provided
    if test -z "$zz"
        read --prompt-str "Enter number of passwords [1]: " zz
        if test -z "$zz"
            set zz 1
        end
    end

    # Validate inputs
    if not string match -qr '^[0-9]+$' "$xx"
        echo "❌ Invalid length: '$xx'. Must be a positive number."
        return 1
    end
    if not string match -qr '^[0-9]+$' "$zz"
        echo "❌ Invalid count: '$zz'. Must be a positive number."
        return 1
    end

    # Generate passwords using Fish random (hex output)
    for i in (seq $zz)
        random hex $xx
        echo
    end
end
