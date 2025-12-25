function kver
    # Get the current kernel version
    set current_kernel (uname -r)

    # Display the current kernel version
    echo "Current Kernel Version: $current_kernel"

    # Prompt to visit kernel.org 
     read --prompt-str "visit kernel.org? (y/n): " x

    # Handle the response from the user
    if test $x = 'y' -o $x = 'Y'
        nohup firefox https://kernel.org >/dev/null 2>&1 &
    end
end
