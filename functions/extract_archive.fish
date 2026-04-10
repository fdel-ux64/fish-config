function extract_archive --description "Extract archive into its own directory"

    function __extract_archive_help
        echo "Usage:"
        echo "  extract_archive [OPTIONS] <archive>"
        echo
        echo "Options:"
        echo "  -F/--force    Overwrite existing output directory (no prompt)"
        echo "  -q/--quiet    Minimal output"
        echo "  -h/--help     Show help"
        echo
        echo "Supported formats:"
        echo "  tar, tar.gz, tgz, tar.bz2, tar.xz, tar.zst"
        echo "  zip, gz, bz2, xz, zst (single file)"
        echo "  rar (if unrar installed)"
        echo
        echo "Examples:"
        echo "  extract_archive archive.tar.gz"
        echo "  extract_archive --force archive.tar.zst"
        echo "  extract_archive -q archive.zip"
    end

    argparse 'F/force' 'q/quiet' 'h/help' -- $argv
    or return

    if set -q _flag_help
        __extract_archive_help
        return 0
    end

    # -------------------------
    # Require exactly one argument
    # -------------------------
    if test (count $argv) -eq 0
        echo "Error: archive required"
        __extract_archive_help
        return 1
    end

    set archive $argv[1]

    if not test -f "$archive"
        echo "Error: file not found: $archive"
        return 1
    end

    # -------------------------
    # Derive output directory name
    # resolve relative to archive location, not CWD
    # -------------------------
    set filename (basename "$archive")
    set archivedir (dirname "$archive")
    set basename (string replace -r '\.(tar\.(gz|bz2|xz|zst)|tar|tgz|zip|gz|bz2|xz|zst|rar)$' '' "$filename")

    if test "$basename" = "$filename"
        echo "Error: unrecognized archive format: $filename"
        return 1
    end

    # -------------------------
    # Derive format via regex — locale-safe, no glob matching
    # -------------------------
    if string match -qr '\.tar\.gz$|\.tgz$' "$filename"
        set format tar.gz
    else if string match -qr '\.tar\.bz2$' "$filename"
        set format tar.bz2
    else if string match -qr '\.tar\.xz$' "$filename"
        set format tar.xz
    else if string match -qr '\.tar\.zst$' "$filename"
        set format tar.zst
    else if string match -qr '\.tar$' "$filename"
        set format tar
    else if string match -qr '\.zip$' "$filename"
        set format zip
    else if string match -qr '\.gz$' "$filename"
        set format gz
    else if string match -qr '\.bz2$' "$filename"
        set format bz2
    else if string match -qr '\.xz$' "$filename"
        set format xz
    else if string match -qr '\.zst$' "$filename"
        set format zst
    else if string match -qr '\.rar$' "$filename"
        set format rar
    else
        echo "Error: unrecognized archive format: $filename"
        return 1
    end

    set outdir "$archivedir/$basename"

    # -------------------------
    # Overwrite protection
    # -------------------------
    if test -d "$outdir"
        if set -q _flag_force
            rm -rf "$outdir"
        else if isatty stdin
            echo "Directory already exists: $outdir"
            read --prompt-str "Overwrite? [y/N] " confirm
            if string match -qri 'y' "$confirm"
                rm -rf "$outdir"
            else
                echo "Aborted"
                return 1
            end
        else
            echo "Error: directory already exists: $outdir"
            echo "Use --force to overwrite in non-interactive mode"
            return 1
        end
    end

    set tmp (mktemp -d)

    mkdir -p "$outdir"

    # -------------------------
    # Extraction — switch on derived $format, not filename glob
    # -------------------------
    set failed 0

    switch $format
        case tar
            tar xf "$archive" -C "$tmp"
            if test $status -ne 0
                set failed 1
            end

        case tar.gz
            if command -sq pigz
                pigz -dc "$archive" | tar xf - -C "$tmp"
                if test $pipestatus[1] -ne 0 -o $pipestatus[2] -ne 0
                    set failed 1
                end
            else
                tar xzf "$archive" -C "$tmp"
                if test $status -ne 0
                    set failed 1
                end
            end

        case tar.bz2
            tar xjf "$archive" -C "$tmp"
            if test $status -ne 0
                set failed 1
            end

        case tar.xz
            tar xJf "$archive" -C "$tmp"
            if test $status -ne 0
                set failed 1
            end

        case tar.zst
            if command -sq zstd
                zstd -dc "$archive" | tar xf - -C "$tmp"
                if test $pipestatus[1] -ne 0 -o $pipestatus[2] -ne 0
                    set failed 1
                end
            else
                echo "Error: zstd not installed"
                set failed 1
            end

        case zip
            unzip -q "$archive" -d "$tmp"
            if test $status -ne 0
                set failed 1
            end

        case gz
            if command -sq pigz
                pigz -dc "$archive" >"$tmp/"(string replace -r '\.gz$' '' "$filename")
            else
                gunzip -c "$archive" >"$tmp/"(string replace -r '\.gz$' '' "$filename")
            end
            if test $status -ne 0
                set failed 1
            end

        case bz2
            bunzip2 -c "$archive" >"$tmp/"(string replace -r '\.bz2$' '' "$filename")
            if test $status -ne 0
                set failed 1
            end

        case xz
            unxz -c "$archive" >"$tmp/"(string replace -r '\.xz$' '' "$filename")
            if test $status -ne 0
                set failed 1
            end

        case zst
            if command -sq zstd
                zstd -dc "$archive" >"$tmp/"(string replace -r '\.zst$' '' "$filename")
                if test $status -ne 0
                    set failed 1
                end
            else
                echo "Error: zstd not installed"
                set failed 1
            end

        case rar
            if command -sq unrar
                unrar x "$archive" "$tmp/"
                if test $status -ne 0
                    set failed 1
                end
            else
                echo "Error: unrar not installed"
                set failed 1
            end
    end

    if test $failed -eq 1
        echo "Error: extraction failed"
        rm -rf "$tmp" "$outdir"
        return 1
    end

    # -------------------------
    # Guard: extraction produced nothing
    # -------------------------
    set items $tmp/*

    if not test -e "$items[1]"
        echo "Error: extraction produced no files"
        rm -rf "$tmp" "$outdir"
        return 1
    end

    # -------------------------
    # Flatten — only when single top-level dir
    # matches archive basename
    # -------------------------
    if test (count $items) -eq 1 -a -d "$items[1]"
        set topdir (basename "$items[1]")
        if test "$topdir" = "$basename"
            command cp -a "$items[1]"/. "$outdir"/
        else
            command cp -a "$tmp"/. "$outdir"/
        end
    else
        command cp -a "$tmp"/. "$outdir"/
    end

    rm -rf "$tmp"

    if not set -q _flag_quiet
        echo "Extracted → $outdir"
    end

end
