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

function deb_installed --description "List installed Debian/Ubuntu packages by install date with caching"

    # ---- Distro check ----
    if not test -f /etc/debian_version
        echo "❌ This function requires a Debian-based distribution"
        return 1
    end

    # ---- Help ----
    set -l arg (string lower -- $argv[1])
    switch $arg
        case -h --help
            __deb_installed_help
            return 0
    end

    # ---- Refresh cache ----
    if test "$arg" = --refresh
        set -e __deb_instlist_cache
        echo "♻️  Cache cleared. Will rebuild on next call."
        return 0
    end

    # ---- Build cache if missing ----
    if not set -q __deb_instlist_cache
        set -g __deb_instlist_cache (__instlist_deb)
    end

    # ---- Alias normalization ----
    switch $arg
        case td
            set arg today
        case yd
            set arg yesterday
        case lw
            set arg last-week
        case tm
            set arg this-month
        case lm
            set arg last-month
    end

    # ---- count/stats mode: shift args ----
    set -l count_mode 0
    if test "$arg" = count; or test "$arg" = stats
        set count_mode 1
        set arg (string lower -- $argv[2])
        switch $arg
            case td
                set arg today
            case yd
                set arg yesterday
            case lw
                set arg last-week
            case tm
                set arg this-month
            case lm
                set arg last-month
        end
    end

    # ---- Time boundaries ----
    set -l today_start      (date -d 'today 00:00'      +%s)
    set -l tomorrow_start   (date -d 'tomorrow 00:00'   +%s)
    set -l yesterday_start  (date -d 'yesterday 00:00'  +%s)
    set -l last_week_start  (date -d '7 days ago 00:00' +%s)
    set -l this_month_start (date -d (date +%Y-%m-01)   +%s)
    set -l last_month_start (date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Resolve s/e from $arg first ----
    set -l s 0
    set -l e ""

    switch $arg
        case today
            set s $today_start
            set e $tomorrow_start
        case yesterday
            set s $yesterday_start
            set e $today_start
        case last-week
            set s $last_week_start
            set e $today_start
        case this-month
            set s $this_month_start
            set e $tomorrow_start
        case last-month
            set s $last_month_start
            set e $this_month_start
        case since
            # handled below
        case ''
            set s 0
    end

    # ---- since / until override ----
    for i in (seq (count $argv))
        set -l token (string lower -- $argv[$i])
        switch $token
            case since
                set -l next (math $i + 1)
                if test $next -gt (count $argv)
                    echo "❌ 'since' requires a date argument" >&2
                    return 1
                end
                set -l parsed (date -d "$argv[$next] 00:00" +%s 2>/dev/null)
                if test -z "$parsed"
                    echo "❌ Invalid date for 'since': $argv[$next]" >&2
                    return 1
                end
                set s $parsed
            case until
                set -l next (math $i + 1)
                if test $next -gt (count $argv)
                    echo "❌ 'until' requires a date argument" >&2
                    return 1
                end
                set -l parsed (date -d "$argv[$next] +1 day 00:00" +%s 2>/dev/null)
                if test -z "$parsed"
                    echo "❌ Invalid date for 'until': $argv[$next]" >&2
                    return 1
                end
                set e $parsed
        end
    end

    # ---- Execute ----
    if test $count_mode -eq 1
        printf "%s\n" $__deb_instlist_cache |
            awk -v s="$s" -v e="$e" '
                $1>=s && (e=="" || $1<e) {
                    d=strftime("%Y-%m-%d",$1); c[d]++
                }
                END { for (d in c) print d, c[d] }
            ' | sort
    else
        set -l res (
            printf "%s\n" $__deb_instlist_cache |
            awk -v s="$s" -v e="$e" '$1>=s && (e=="" || $1<e)' |
            sort -n
        )
        __display_packages "$arg" $res
    end
end
