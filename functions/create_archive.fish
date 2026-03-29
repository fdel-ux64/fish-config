function create_archive --description "Create archive with smart format detection"

    function _archive_help
        echo "Usage:"
        echo "  create_archive [OPTIONS] <source> [output]"
        echo
        echo "Options:"
        echo "  -f/--type TYPE    tar | tar.gz | tgz | tar.zst (default: tar.zst)"
        echo "  -F/--force        Overwrite existing archive (no prompt)"
        echo "  -h/--help         Show help"
        echo
        echo "Examples:"
        echo "  create_archive project"
        echo "  create_archive project backup.tar.gz"
        echo "  create_archive -f tar.gz project"
        echo "  create_archive --force project"
    end

    argparse 'f/type=' F/force h/help -- $argv
    or return

    if set -q _flag_help
        _archive_help
        return 0
    end

    # -------------------------
    # Require at least one argument
    # -------------------------
    if test (count $argv) -eq 0
        echo "Error: source required"
        _archive_help
        return 1
    end

    # -------------------------
    # Source / output
    # Strip trailing slash from both to avoid hidden file bug
    # -------------------------
    set source (string replace -r '/$' '' $argv[1])

    if test (count $argv) -ge 2
        set raw $argv[2]
        if string match -qr '/$' "$raw"
            # trailing slash — it's a destination directory
            set output (string replace -r '/$' '' "$raw")/(basename "$source")
        else
            set output $raw
        end
    end

    # -------------------------
    # Resolve output to absolute path early
    # so it survives any directory changes
    # -------------------------
    if not set -q output
        set output (dirname "$source")/(basename "$source")
    end

    if not string match -qr '^/' "$output"
        set output (pwd)/$output
    end

    # -------------------------
    # Determine archive type
    # -------------------------
    if set -q _flag_type
        set type $_flag_type

        # Validate type value first
        switch $type
            case tar tar.gz tgz tar.zst
                # valid
            case '*'
                echo "Error: unsupported type: $type"
                return 1
        end

        # Normalise tgz -> tar.gz for all further logic
        if test "$type" = tgz
            set type tar.gz
        end

        # Derive the canonical extension for this type
        switch $type
            case tar
                set expected_ext .tar
            case tar.gz
                set expected_ext .tar.gz
            case tar.zst
                set expected_ext .tar.zst
        end

        # If output already has a recognised archive extension, check it matches
        if string match -qr '\.(tar|tar\.gz|tgz|tar\.zst)$' "$output"
            # Normalise tgz extension to tar.gz for comparison
            set normalised_output (string replace -r '\.tgz$' '.tar.gz' "$output")
            if not string match -qr (string escape --style=regex "$expected_ext")'$' "$normalised_output"
                echo "Error: -f $type conflicts with output extension: $output"
                echo "Either drop -f and let the extension decide, or rename the output to end in $expected_ext"
                return 1
            end
        else
            # No recognised extension — append the correct one
            set output "$output$expected_ext"
        end
    else
        switch $output
            case '*.tar'
                set type tar
            case '*.tar.gz' '*.tgz'
                set type tar.gz
            case '*.tar.zst'
                set type tar.zst
            case '*'
                set type tar.zst
                set output "$output.tar.zst"
        end
    end

    # -------------------------
    # Overwrite protection
    # -------------------------
    if test -e "$output"
        if set -q _flag_force
            rm -f "$output"
        else if isatty stdin
            echo "Archive already exists: $output"
            read --prompt-str "Overwrite? [y/N] " confirm
            if string match -qri 'y' "$confirm"
                rm -f "$output"
            else
                echo "Aborted"
                return 1
            end
        else
            echo "Error: archive already exists: $output"
            echo "Use --force to overwrite in non-interactive mode"
            return 1
        end
    end

    # -------------------------
    # Normalize source paths
    # -------------------------
    set srcdir (dirname "$source")
    set srcbase (basename "$source")

    # -------------------------
    # Create archive
    # -------------------------
    switch $type
        case tar
            tar -C "$srcdir" -cf "$output" "$srcbase"
            if test $status -ne 0
                echo "Error: archive creation failed"
                rm -f "$output"
                return 1
            end

        case tar.gz
            if command -sq pigz
                tar -C "$srcdir" -cf - "$srcbase" | pigz >"$output"
                if test $pipestatus[1] -ne 0 -o $pipestatus[2] -ne 0
                    echo "Error: archive creation failed"
                    rm -f "$output"
                    return 1
                end
            else
                tar -C "$srcdir" -czf "$output" "$srcbase"
                if test $status -ne 0
                    echo "Error: archive creation failed"
                    rm -f "$output"
                    return 1
                end
            end

        case tar.zst
            if command -sq zstd
                tar -C "$srcdir" -cf - "$srcbase" | zstd -T0 -o "$output"
                if test $pipestatus[1] -ne 0 -o $pipestatus[2] -ne 0
                    echo "Error: archive creation failed"
                    rm -f "$output"
                    return 1
                end
            else
                echo "Error: zstd not installed"
                return 1
            end
    end

    echo "Created: $output"
end
