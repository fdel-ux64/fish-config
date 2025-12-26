function generate_password
    # If arguments are given, use them instead of prompting
    set -l xx $argv[1]
    set -l zz $argv[2]

    # Check if pwgen is available
    if not type -q pwgen
        echo "Error: The package 'pwgen' is required to generate passwords, but it is not installed."
        return 1
    end

    # If length not provided, prompt for it
    if test -z "$xx"
        read --prompt-str "Enter password length: " xx
    end

    # If count not provided, prompt for it
    if test -z "$zz"
        read --prompt-str "Enter number of passwords: " zz
    end

    # Generate passwords, one per line
    pwgen -1 -s -y -c $xx $zz
end

