# Global helpers defined ONCE outside the main function — fixes scope leak

set -g __rpm_summary_threshold 25

function __deb_installed_help
    echo "deb_installed — list installed packages (Debian/Ubuntu)"
    echo
    echo "USAGE:"
    echo "  deb_installed [OPTION]"
    echo "  deb_installed since DATE [until DATE]"
    echo "  deb_installed count [OPTION]"
    echo "  deb_installed --refresh"
end

function __instlist_deb
    set -l files (ls /var/log/dpkg.log* 2>/dev/null | sort -r)
    for f in $files
        if string match -q "*.gz" -- $f
            zcat $f
        else
            cat $f
        end
    end | awk '
        $3=="install" {
            split($1,d,"-")
            split($2,t,":")
            ts=mktime(d[1]" "d[2]" "d[3]" "t[1]" "t[2]" "t[3])
            pkg=$4
            sub(/:.*/,"",pkg)
            print ts, pkg
        }
    '
end

function __display_packages
    set -l title $argv[1]
    set -l pkgs $argv[2..-1]
    set -l pkg_count (count $pkgs)

    if test $pkg_count -eq 0
        echo
        echo " 📭 No packages installed: $title"
        echo
        return
    end

    echo
    echo " 📦 Installed packages: $title"
    echo " ─────────────────────────────────────────────"

    for line in $pkgs
        set -l parts (string split -m1 ' ' $line)
        set -l ts $parts[1]
        set -l pkg $parts[2]
        set -l datestr (date -d @$ts "+%Y-%m-%d %T")
        echo " $datestr: $pkg"
    end

    echo
    echo " 🔢 Total: $pkg_count"
    if test $pkg_count -gt $__rpm_summary_threshold
        echo " ↑  Showing $pkg_count package(s) installed: $title"
    end
    echo
end
