function resize_image --description "Resize image(s) by percentage or max dimension"
    # Help flag
    if test (count $argv) -ge 1
        switch $argv[1]
            case -h --help
                echo "Usage:"
                echo "  resize_image <image|dir> [size]"
                echo
                echo "Examples:"
                echo "  resize_image photo.jpg          # interactive"
                echo "  resize_image photo.jpg 50       # 50%"
                echo "  resize_image photo.jpg 1200     # max 1200px"
                echo "  resize_image ./photos           # batch, interactive"
                echo "  resize_image ./photos 75        # batch, 75%"
                echo
                echo "Notes:"
                echo "  - size ≤ 100  → percentage"
                echo "  - size > 100  → max dimension"
                echo "  - Supported: jpg, jpeg, png, gif, webp, tiff, bmp"
                return 0
        end
    end

    set target $argv[1]
    set size $argv[2]

    # Prompt if nothing given
    if test -z "$target"
        read -P "Image or directory path: " target
    end

    # Resolve mode: single file or directory
    if test -d "$target"
        set files (command find "$target" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
       -o -iname "*.gif" -o -iname "*.webp" \
       -o -iname "*.tiff" -o -iname "*.bmp" \) \
    ! -iname "*-resized.*" | sort)

        if test (count $files) -eq 0
            echo "❌ No supported images found in: $target"
            return 1
        end

        echo "📁 Found "(count $files)" image(s) in $target"
        set batch 1

    else if test -f "$target"
        set files $target
        set batch 0

    else
        echo "❌ Not a file or directory: $target"
        return 1
    end

    # Resolve size — once, for all files
    set resize_arg ""

    if test -n "$size"
        if not string match -rq '^[0-9]+$' "$size"
            echo "❌ Size must be a number"
            return 1
        end
        if test $size -le 100
            set resize_arg "percent:$size"
        else
            set resize_arg "dim:$size"
        end
    else
        echo "Resize mode:"
        echo "  1) Percentage (e.g. 50%)"
        echo "  2) Max dimension (e.g. 1200px)"
        read -P "Choose [1/2]: " mode
        switch $mode
            case 1
                read -P "Percentage: " pct
                if not string match -rq '^[0-9]+$' "$pct"
                    echo "❌ Percentage must be a number"
                    return 1
                end
                set resize_arg "percent:$pct"
            case 2
                read -P "Max size (px): " px
                if not string match -rq '^[0-9]+$' "$px"
                    echo "❌ Dimension must be a number"
                    return 1
                end
                set resize_arg "dim:$px"
            case '*'
                echo "❌ Invalid choice"
                return 1
        end
    end

    # Process files
    set ok 0
    set fail 0

    for img in $files
        set dir (path dirname "$img")
        set base (path basename "$img")
        set name (string replace -r '\.[^.]+$' '' "$base")
        set ext (string match -r '\.[^.]+$' "$base")
        set out "$dir/$name-resized$ext"

        switch $resize_arg
            case "percent:*"
                set pct (string replace "percent:" "" "$resize_arg")
                magick "$img" -resize "$pct%" "$out"
            case "dim:*"
                set px (string replace "dim:" "" "$resize_arg")
                magick "$img" -resize "$px"x"$px"\> "$out"
        end

        if test $status -eq 0
            if test $batch -eq 1
                echo "  ✅ $base → $name-resized$ext"
            else
                echo "✅ Resized → $out"
            end
            set ok (math $ok + 1)
        else
            echo "  ❌ Failed: $base"
            set fail (math $fail + 1)
        end
    end

    # Batch summary
    if test $batch -eq 1
        echo "─────────────────────────────"
        echo "Done: $ok succeeded, $fail failed"
    end
end
