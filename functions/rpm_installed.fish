# ---- Global helpers — defined once, outside main function ----

function __rpm_installed_help
    echo "rpm_installed — list installed RPM packages by install date"
    echo
    echo "USAGE:"
    echo "  rpm_installed [OPTION]"
    echo "  rpm_installed since DATE [until DATE]"
    echo "  rpm_installed count [OPTION] (including 'since … until …')"
    echo "  rpm_installed --refresh  # rebuild cache"
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
    echo "  rpm_installed count today"
    echo "  rpm_installed count last-week"
    echo "  rpm_installed count per-day"
    echo "  rpm_installed count per-week"
    echo "  rpm_installed count since DATE [until DATE]"
end

function __instlist_rpm
    rpm -qa --qf '%{INSTALLTIME} (%{INSTALLTIME:date}): %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'
end

function __display_rpm_packages
    set -l title $argv[1]
    set -l packages $argv[2..-1]
    set -l pkg_count (count $packages)

    if test $pkg_count -eq 0
        echo
        echo "     📭 No packages installed: $title"
        echo "        Try: rpm_installed last-week or rpm_installed this-month"  # FIX: correct function name
        echo
        return
    end

    if test -n "$title"
        echo
        echo "    📦 List of installed package(s): $title"
        echo "    ╰─────────────────────────────────────────────────────────"
        echo
    end

    for pkg in $packages
        echo $pkg
    end

    if test -n "$title"
        echo
        echo " ────────────────────────────────────"
        echo " 🔢 Total number of package(s): $pkg_count"
        echo
    end
end


function rpm_installed --description "List installed RPM packages by install date with caching"

    # ---- Distro check ----
    if not command -q rpm
        echo "❌ This function requires RPM package manager"
        echo "   Current system does not appear to be RPM-based"
        return 1
    end

    set -l arg (string lower -- $argv[1])

    # ---- Help ----
    switch $arg
        case -h --help
            __rpm_installed_help
            return 0
    end

    # ---- Refresh cache ----
    if test "$arg" = --refresh
        set -e __rpm_instlist_cache                      # FIX: renamed, no collision
        echo "♻️  Cache cleared. Will rebuild on next call."
        return 0
    end

    # ---- Build cache if missing ----
    # FIX: was ($backend_func) — indirect call doesn't work in Fish,
    # cache was always empty. Now calls __instlist_rpm directly.
    if not set -q __rpm_instlist_cache                   # FIX: renamed
        set -g __rpm_instlist_cache (__instlist_rpm)
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
    set -l today_start      (env LC_ALL=en_US.UTF-8 date -d 'today 00:00'      +%s)
    set -l tomorrow_start   (env LC_ALL=en_US.UTF-8 date -d 'tomorrow 00:00'   +%s)
    set -l yesterday_start  (env LC_ALL=en_US.UTF-8 date -d 'yesterday 00:00'  +%s)
    set -l last_week_start  (env LC_ALL=en_US.UTF-8 date -d '7 days ago 00:00' +%s)
    set -l this_month_start (env LC_ALL=en_US.UTF-8 date -d (date +%Y-%m-01)   +%s)
    set -l last_month_start (env LC_ALL=en_US.UTF-8 date -d (date +%Y-%m-01)' -1 month' +%s)

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
            printf "%s\n" $__rpm_instlist_cache |
                awk '{count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            return
        case per-week
            if test $count_mode -eq 1
                echo "❌ 'count per-week' is redundant — per-week already counts by week" >&2
                return 1
            end
            printf "%s\n" $__rpm_instlist_cache |
                awk '{count[strftime("%Y-W%V",$1)]++} END{for(w in count) printf "%s  %d\n", w, count[w]}' | sort
            return
        case ''
            set s 0
        case '*'
            echo "❌ Invalid option: '$arg'"
            echo
            __rpm_installed_help
            return 1
    end

    # ---- since / until override — writes directly into s and e ----
    # FIX: until-only queries now work; previously ignored if since was absent.
    # FIX: until now uses +1 day to be inclusive of the specified date,
    #      consistent with deb and arch versions.
    for i in (seq (count $argv))
        set -l token (string lower -- $argv[$i])
        switch $token
            case since
                set -l next (math $i + 1)
                if test $next -gt (count $argv)          # FIX: explicit bounds check
                    echo "❌ 'since' requires a date argument" >&2
                    return 1
                end
                set -l parsed (env LC_ALL=en_US.UTF-8 date -d "$argv[$next] 00:00" +%s 2>/dev/null)
                if test -z "$parsed"
                    echo "❌ Invalid date for 'since': $argv[$next]" >&2
                    echo "   Expected a format understood by 'date -d' (e.g. YYYY-MM-DD)"
                    return 1
                end
                set s $parsed
            case until
                set -l next (math $i + 1)
                if test $next -gt (count $argv)          # FIX: explicit bounds check
                    echo "❌ 'until' requires a date argument" >&2
                    return 1
                end
                set -l parsed (env LC_ALL=en_US.UTF-8 date -d "$argv[$next] +1 day 00:00" +%s 2>/dev/null) # FIX: inclusive
                if test -z "$parsed"
                    echo "❌ Invalid date for 'until': $argv[$next]" >&2
                    echo "   Expected a format understood by 'date -d' (e.g. YYYY-MM-DD)"
                    return 1
                end
                set e $parsed
        end
    end

    # ---- Execute ----
    if test $count_mode -eq 1
        printf "%s\n" $__rpm_instlist_cache |
            awk -v s="$s" -v e="$e" '
                $1>=s && (e=="" || $1<e) {
                    count[strftime("%Y-%m-%d",$1)]++
                }
                END { for (d in count) printf "%s  %d\n", d, count[d] }
            ' | sort
    else
        set -l res (
            printf "%s\n" $__rpm_instlist_cache |
            awk -v s="$s" -v e="$e" '$1>=s && (e=="" || $1<e)' |
            sort -n
        )
        # FIX: build heading here instead of pre-computing above,
        # since/until heading now handled uniformly
        set -l heading "$arg"
        if test -n (printf "%s" $s) -a $s -gt 0
            set heading "since "(env LC_ALL=en_US.UTF-8 date -d @$s +%Y-%m-%d)
            if test -n "$e"
                set heading "$heading until "(env LC_ALL=en_US.UTF-8 date -d @$e +%Y-%m-%d)
            end
        end
        __display_rpm_packages "$heading" $res
    end
end
