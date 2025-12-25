function kver
    # Get the current kernel version
    set current_kernel (uname -r)

    # Display the current kernel version
    echo "Current Kernel Version: $current_kernel"

    # Use printf for precise cursor control and avoid prompt issues
    printf "visit kernel.org? (y/n): "
    read -p "" answer  # Use the -p flag to suppress the read> prompt

    # Handle the response from the user
    if test $answer = 'y' -o $answer = 'Y'
        nohup firefox https://kernel.org >/dev/null 2>&1 &
    end
end
