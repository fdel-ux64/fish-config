# ---- Global helpers — defined once, outside main function ----

set -g __rpm_summary_threshold 25

function __arch_installed_help
    echo "arch_installed — list installed Arch packages by install date"
    echo
    echo "USAGE:"
    echo "  arch_installed [OPTION]"
    echo "  arch_installed since DATE [until DATE]"
    echo "  arch_installed count [OPTION]"
    echo "  arch_installed --refresh"
    echo
    echo "OPTIONS:"
    echo "  today        Packages installed today"
    echo "  yesterday    Packages installed yesterday"
    echo "  last-week    Packages installed in the last 7 days"
    echo "  this-month   Packages installed this calendar month"
    echo "  last-month   Packages installed in the previous calendar month"
    echo
    echo "ALIASES:"
    echo "  td  → today"
    echo "  yd  → yesterday"
    echo "  lw  → last-week"
    echo "  tm  → this-month"
    echo "  lm  → last-month"
    echo
    echo "COUNT / STATS:"
    echo "  arch_installed count today"
    echo "  arch_installed count per-day"
    echo "  arch_installed count per-week"
    echo "  arch_installed count since DATE [until DATE]"
end

function __instlist_arch
    expac --timefmt=%s '%l %n-%v'
end

function __display_arch_packages
    set -l title $argv[1]
    set -l pkgs $argv[2..-1]
    set -l pkg_count (count $pkgs)

    if test $pkg_count -eq 0
        echo
        echo "     📭 No packages installed: $title"
        echo "        Try: arch_installed last-week or arch_installed this-month"
        echo
        return
    end

    echo
    echo "       📦 List of installed package(s): $title"
    echo "       ╰─────────────────────────────────────────────────────────"
    echo

    for line in $pkgs
        set -l parts (string split -m1 ' ' $line)
        set -l ts $parts[1]
        set -l pkg $parts[2]
        set -l datestr (date -d @$ts "+%Y-%m-%d %T")
        echo " $datestr: $pkg"
    end

    echo
    echo " ────────────────────────────────────"
    echo " 🔢 Total number of package(s): $pkg_count"
    if test $pkg_count -gt $__rpm_summary_threshold
        echo " ↑  Showing $pkg_count package(s) installed: $title"
    end
    echo
end
