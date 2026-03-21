# ---- Global helpers — defined once, outside main function ----

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

    if test (count $pkgs) -eq 0
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
    echo " 🔢 Total number of package(s): "(count $pkgs)
    echo
end


function arch_installed --description "List installed Arch packages by install date with caching using expac"

    # ---- Distro check ----
    if not test -f /etc/arch-release
        echo "❌ This function requires an Arch-based distribution"
        return 1
    end

    # ---- Dependency check ----
    if not command -q expac
        echo "❌ Missing dependency: expac"
        echo "   Install with: sudo pacman -S expac"
        return 1
    end

    set -l arg (string lower -- $argv[1])

    # ---- Help ----
    switch $arg
        case -h --help
            __arch_installed_help
            return 0
    end

    # ---- Refresh cache ----
    if test "$arg" = --refresh
        set -e __arch_instlist_cache                     # FIX: renamed, no collision with deb cache
        echo "♻️  Cache cleared. Will rebuild on next call."
        return 0
    end

    # ---- Build cache if missing ----
    if not set -q __arch_instlist_cache                  # FIX: renamed
        set -g __arch_instlist_cache (__instlist_arch)
    end

    # ---- Alias normalization ----
    switch $arg
        case td; set arg today
        case yd; set arg yesterday
        case lw; set arg last-week
        case tm; set arg this-month
        case lm; set arg last-month
    end

    # ---- count/stats mode: shift args ----
    set -l count_mode 0
    if test "$arg" = count; or test "$arg" = stats
        set count_mode 1
        set arg (string lower -- $argv[2])
        # re-normalize alias after shift
        switch $arg
            case td; set arg today
            case yd; set arg yesterday
            case lw; set arg last-week
            case tm; set arg this-month
            case lm; set arg last-month
        end
    end

    # ---- Time boundaries ----
    set -l today_start      (date -d 'today 00:00'      +%s)
    set -l tomorrow_start   (date -d 'tomorrow 00:00'   +%s)
    set -l yesterday_start  (date -d 'yesterday 00:00'  +%s)
    set -l last_week_start  (date -d '7 days ago 00:00' +%s)
    set -l this_month_start (date -d (date +%Y-%m-01)   +%s)
    set -l last_month_start (date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Resolve s/e from $arg ----
    set -l s 0
    set -l e ""

    switch $arg
        case today
            set s $today_start;      set e $tomorrow_start
        case yesterday
            set s $yesterday_start;  set e $today_start
        case last-week
            set s $last_week_start;  set e $today_start   # FIX: added upper bound
        case this-month
            set s $this_month_start; set e $tomorrow_start # FIX: added upper bound
        case last-month
            set s $last_month_start; set e $this_month_start
        case per-day
            if test $count_mode -eq 1
                echo "❌ 'count per-day' is redundant — per-day already counts by day" >&2
                return 1
            end
            printf "%s\n" $__arch_instlist_cache |
                awk '{d=strftime("%Y-%m-%d",$1);c[d]++} END{for(d in c) print d,c[d]}' | sort
            return
        case per-week
            if test $count_mode -eq 1
                echo "❌ 'count per-week' is redundant — per-week already counts by week" >&2
                return 1
            end
            printf "%s\n" $__arch_instlist_cache |
                awk '{w=strftime("%Y-W%V",$1);c[w]++} END{for(w in c) print w,c[w]}' | sort
            return
        case ''
            set s 0
        case '*'
            echo "❌ Invalid option: $arg"
            __arch_installed_help
            return 1
    end

    # ---- since / until override — writes directly into s and e ----
    # FIX: previously since_epoch/until_epoch were set but never applied to
    # the filter. Now parsed directly into s/e. Also handles until-only queries.
    for i in (seq (count $argv))
        set -l token (string lower -- $argv[$i])
        switch $token
            case since
                set -l next (math $i + 1)
                if test $next -gt (count $argv)          # FIX: bounds check
                    echo "❌ 'since' requires a date argument" >&2
                    return 1
                end
                set -l parsed (date -d "$argv[$next] 00:00" +%s 2>/dev/null)
                if test -z "$parsed"                      # FIX: validate date
                    echo "❌ Invalid date for 'since': $argv[$next]" >&2
                    return 1
                end
                set s $parsed
            case until                                    # FIX: removed 'untill' typo alias
                set -l next (math $i + 1)
                if test $next -gt (count $argv)          # FIX: bounds check
                    echo "❌ 'until' requires a date argument" >&2
                    return 1
                end
                set -l parsed (date -d "$argv[$next] +1 day 00:00" +%s 2>/dev/null)
                if test -z "$parsed"                      # FIX: validate date
                    echo "❌ Invalid date for 'until': $argv[$next]" >&2
                    return 1
                end
                set e $parsed
        end
    end

    # ---- Execute ----
    if test $count_mode -eq 1
        printf "%s\n" $__arch_instlist_cache |
            awk -v s="$s" -v e="$e" '
                $1>=s && (e=="" || $1<e) {
                    d=strftime("%Y-%m-%d",$1); c[d]++
                }
                END { for (d in c) print d, c[d] }
            ' | sort
    else
        set -l res (
            printf "%s\n" $__arch_instlist_cache |
            awk -v s="$s" -v e="$e" '$1>=s && (e=="" || $1<e)' |
            sort -n
        )
        __display_arch_packages "$arg" $res
    end
end
