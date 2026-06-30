function resize_image --description "Resize image(s) by percentage or max dimension"
    # Help flag
    if test (count $argv) -ge 1
        switch $argv[1]
            case -h --help
                echo "Usage:"
                echo "  resize_image [--strip-meta] <image|dir> [size]"
                echo
                echo "Examples:"
                echo "  resize_image photo.jpg                    # interactive"
                echo "  resize_image photo.jpg 50                 # 50%"
                echo "  resize_image photo.jpg 1200               # max 1200px"
                echo "  resize_image --strip-meta photo.jpg 75    # strip EXIF/XMP metadata"
                echo "  resize_image ./photos                     # batch, interactive"
                echo "  resize_image ./photos 75                  # batch, 75%"
                echo "  resize_image --strip-meta ./photos 1200   # batch, strip metadata"
                echo
                echo "Options:"
                echo "  --strip-meta  Remove EXIF/XMP/IPTC metadata from output (default: preserve)"
                echo
                echo "Notes:"
                echo "  - size ≤ 100  → percentage"
                echo "  - size > 100  → max dimension"
                echo "  - Supported: jpg, jpeg, png, gif, webp, tiff, bmp"
                return 0
        end
    end

    # Parse --strip-meta flag (may appear before the target)
    set strip_meta 0
    set _args $argv
    if contains -- --strip-meta $_args
        set strip_meta 1
        set _args (string match -rv '^--strip-meta$' $_args)
    end

    set target $_args[1]
    set size $_args[2]

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
    set bytes_orig 0
    set bytes_resized 0

    for img in $files
        set dir (path dirname "$img")
        set base (path basename "$img")
        set name (string replace -r '\.[^.]+$' '' "$base")
        set ext (string match -r '\.[^.]+$' "$base")
        set out "$dir/$name-resized$ext"

        set strip_flag
        if test $strip_meta -eq 1
            set strip_flag -strip
        end

        switch $resize_arg
            case "percent:*"
                set pct (string replace "percent:" "" "$resize_arg")
                magick "$img" -resize "$pct%" $strip_flag "$out"
            case "dim:*"
                set px (string replace "dim:" "" "$resize_arg")
                magick "$img" -resize "$px"x"$px"\> $strip_flag "$out"
        end
        set magick_status $status

        if test $magick_status -eq 0
            set bytes_orig (math $bytes_orig + (stat --format='%s' "$img"))
            set bytes_resized (math $bytes_resized + (stat --format='%s' "$out"))
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

    # Human-readable byte formatter
    function _fmt_bytes
        set b $argv[1]
        if test $b -ge 1073741824
            printf "%.1f GB" (math "$b / 1073741824")
        else if test $b -ge 1048576
            printf "%.1f MB" (math "$b / 1048576")
        else if test $b -ge 1024
            printf "%.1f KB" (math "$b / 1024")
        else
            printf "%d B" $b
        end
    end

    # Summary
    if test $ok -ge 1
        set saved_pct (math --scale=1 "100 - ($bytes_resized * 100 / $bytes_orig)")
        if test $batch -eq 1
            echo "─────────────────────────────"
            echo "Done:     $ok succeeded, $fail failed"
        end
        echo "Original: "(_fmt_bytes $bytes_orig)
        echo "Resized:  "(_fmt_bytes $bytes_resized)
        echo "Saved:    $saved_pct%"
    else if test $batch -eq 1
        echo "─────────────────────────────"
        echo "Done: $ok succeeded, $fail failed"
    end

    functions --erase _fmt_bytes
end
