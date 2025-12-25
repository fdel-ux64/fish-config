function generate_password
    # Prompt for the password length
    read --prompt-str "Enter password length: " xx

    # Prompt for the number of passwords
    read --prompt-str "Enter number of passwords: " zz

    # Generate the password using pwgen
    pwgen -syc $xx $zz
end
