function fishfmt --description "Format .fish files using fish_indent"
    if not command -q fish_indent
        echo " ❌ fish_indent not found — is Fish shell installed correctly?"
        return 1
    end

    set -l recursive 0
    set -l paths

    for arg in $argv
        switch $arg
            case -r --recursive
                set recursive 1
            case -h --help
                echo "Usage: fishfmt [OPTIONS] FILE|DIR [...]"
                echo ""
                echo "Format Fish scripts using fish_indent."
                echo "  FILE  Format a single .fish file"
                echo "  DIR   Format all .fish files in the directory (one level deep by default)"
                echo ""
                echo "Options:"
                echo "  -r, --recursive  Recurse into subdirectories when a DIR is given"
                echo "  -h, --help       Show this help"
                echo ""
                echo "Examples:"
                echo "  fishfmt myfunc.fish"
                echo "  fishfmt ~/.config/fish/functions"
                echo "  fishfmt -r ~/.config/fish/functions"
                return 0
            case '*'
                set paths $paths $arg
        end
    end

    if test (count $paths) -eq 0
        echo "Usage: fishfmt [OPTIONS] FILE|DIR [...]"
        echo "Run 'fishfmt --help' for more information."
        return 1
    end

    set -l formatted 0
    set -l skipped 0

    for path in $paths
        if test -f $path
            if not string match -q "*.fish" $path
                echo " ❌ Not a .fish file: $path"
                set skipped (math $skipped + 1)
            else if not test -w $path
                echo " ❌ Permission denied: $path"
                set skipped (math $skipped + 1)
            else if not fish_indent -w $path
                echo " ❌ Failed to format: $path"
                set skipped (math $skipped + 1)
            else
                echo " ✔ Formatted: $path"
                set formatted (math $formatted + 1)
            end
        else if test -d $path
            set -l find_args $path -name "*.fish" -type f
            if test $recursive -eq 0
                set find_args $path -maxdepth 1 -name "*.fish" -type f
            end
            set -l files (find $find_args)
            if test (count $files) -eq 0
                echo " ⚠ No .fish files found in: $path"
                continue
            end
            for file in $files
                if not test -w $file
                    echo " ❌ Permission denied: $file"
                    set skipped (math $skipped + 1)
                else if not fish_indent -w $file
                    echo " ❌ Failed to format: $file"
                    set skipped (math $skipped + 1)
                else
                    echo " ✔ Formatted: $file"
                    set formatted (math $formatted + 1)
                end
            end
        else
            echo " ❌ Not a file or directory: $path"
            set skipped (math $skipped + 1)
        end
    end

    echo ""
    echo " Done — $formatted formatted, $skipped skipped"
end
