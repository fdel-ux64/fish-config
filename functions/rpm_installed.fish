# ---- Global helpers — defined once, outside main function ----

set -g __rpm_summary_threshold 75
set -g __rpm_use_cache 1

function __rpm_installed_help
    echo "rpm_installed — list installed RPM packages by install date"
    echo
    echo "USAGE:"
    echo "  rpm_installed [OPTION]"
    echo "  rpm_installed days N         # last N days (rolling window)"
    echo "  rpm_installed since DATE [until DATE]"
    echo "  rpm_installed count [OPTION] (including 'since … until …')"
    echo "  rpm_installed --refresh      # rebuild cache"
    echo "  rpm_installed --cache on     # enable caching (default)"
    echo "  rpm_installed --cache off    # always query RPM live"
    echo "  rpm_installed --cache        # show current cache status"
    echo
    echo "OPTIONS:"
    echo "  today        Packages installed today"
    echo "  yesterday    Packages installed yesterday"
    echo "  days N       Packages installed in the last N days (today included)"
    echo "  last-week    Packages installed in the last 7 days (excludes today)"
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
    echo "  rpm_installed count days 5"
    echo "  rpm_installed count last-week"
    echo "  rpm_installed count per-day"
    echo "  rpm_installed count per-week"
    echo "  rpm_installed count since DATE [until DATE]"
end

function __instlist_rpm
    rpm -qa --qf '%{INSTALLTIME} %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'
end

function __display_rpm_packages
    set -l title $argv[1]
    set -l packages $argv[2..-1]
    set -l pkg_count (count $packages)

    if test $pkg_count -eq 0
        echo
        echo "     📭 No packages installed: $title"
        echo "        Try: rpm_installed last-week or rpm_installed this-month"
        echo
        return
    end

    # Build output into a temp file so we can decide whether to page it.
    set -l tmpfile (mktemp /tmp/rpm_installed.XXXXXX)

    # Group packages by date.
    # Each line arriving here is: "<epoch> <name-ver-rel.arch>"
    set -l current_date ""
    set -l dates
    set -l names
    for pkg in $packages
        set -l ts   (string split --max 1 ' ' -- $pkg)[1]
        set -l name (string split --max 1 ' ' -- $pkg)[2]
        set -l day  (env LC_ALL=en_US.UTF-8 date -d @$ts '+%a %Y-%m-%d' 2>/dev/null)
        if test -z "$day"
            set day unknown
        end
        set -a dates $day
        set -a names $name
    end

    begin
        echo
        echo "    📦 Installed packages — $title"
        echo

        set -l i 1
        set -l total (count $names)
        while test $i -le $total
            set -l day  $dates[$i]
            set -l name $names[$i]

            if test "$day" != "$current_date"
                set -l run 0
                set -l j $i
                while test $j -le $total; and test $dates[$j] = $day
                    set run (math $run + 1)
                    set j   (math $j + 1)
                end
                set current_date $day
                printf " 📆 %s  \e[2m(%d package%s)\e[0m\n" \
                    $day $run (test $run -eq 1 && echo "" || echo "s")
            end

            printf "    %s\n" $name
            set i (math $i + 1)
        end

        echo
        echo " ────────────────────────────────────"
        # Title always repeated in footer so it's visible without scrolling up
        printf " 🔢 Total: %d package%s — %s\n" \
            $pkg_count (test $pkg_count -eq 1 && echo "" || echo "s") "$title"
        echo
    end >$tmpfile

    # Auto-page when output would overflow the terminal; skip when piped.
    set -l term_lines $LINES
    test -z "$term_lines"; and set term_lines 24
    set -l file_lines (wc -l <$tmpfile)
    if test $file_lines -gt $term_lines; and isatty stdout
        cat $tmpfile | less -R
    else
        cat $tmpfile
    end

    rm -f $tmpfile
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

    # ---- Cache toggle ----
    if test "$arg" = --cache
        set -l subcmd (string lower -- $argv[2])
        switch $subcmd
            case on
                set -g __rpm_use_cache 1
                echo "✅ Cache enabled."
            case off
                set -g __rpm_use_cache 0
                set -e __rpm_instlist_cache
                echo "⚡ Cache disabled. RPM will be queried live on every call."
            case ''
                if test $__rpm_use_cache -eq 1
                    if set -q __rpm_instlist_cache
                        echo "Cache: enabled (populated)"
                    else
                        echo "Cache: enabled (empty — will build on next call)"
                    end
                else
                    echo "Cache: disabled (live RPM queries)"
                end
            case '*'
                echo "❌ Unknown cache option: '$subcmd'. Use on or off." >&2
                return 1
        end
        return 0
    end

    # ---- Refresh cache ----
    if test "$arg" = --refresh
        set -e __rpm_instlist_cache
        echo "♻️  Cache cleared. Will rebuild on next call."
        return 0
    end

    # ---- Build cache if missing or disabled ----
    if test $__rpm_use_cache -eq 1
        if not set -q __rpm_instlist_cache
            set -g __rpm_instlist_cache (__instlist_rpm)
        end
    else
        set -g __rpm_instlist_cache (__instlist_rpm)
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
    set -l today_start      (env LC_ALL=en_US.UTF-8 date -d 'today 00:00'      +%s)
    set -l tomorrow_start   (env LC_ALL=en_US.UTF-8 date -d 'tomorrow 00:00'   +%s)
    set -l yesterday_start  (env LC_ALL=en_US.UTF-8 date -d 'yesterday 00:00'  +%s)
    set -l last_week_start  (env LC_ALL=en_US.UTF-8 date -d '7 days ago 00:00' +%s)
    set -l this_month_start (env LC_ALL=en_US.UTF-8 date -d (date +%Y-%m-01)   +%s)
    set -l last_month_start (env LC_ALL=en_US.UTF-8 date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Resolve s/e from $arg ----
    set -l s 0
    set -l e ""
    set -l n_days 0   # >0 when 'days N' was used; drives heading

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
        case days
            # Next positional arg shifts by 1 in count mode
            set -l raw_n $argv[(math $count_mode + 2)]
            if test -z "$raw_n"
                echo "❌ 'days' requires a number  →  rpm_installed days 3" >&2
                return 1
            end
            if not string match -qr '^[1-9][0-9]*$' -- "$raw_n"
                echo "❌ 'days' expects a positive integer, got: '$raw_n'" >&2
                return 1
            end
            set n_days $raw_n
            set s (env LC_ALL=en_US.UTF-8 date -d "$n_days days ago 00:00" +%s)
            set e $tomorrow_start
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
        case since until
        case ''
            set s 0
        case '*'
            echo "❌ Invalid option: '$arg'"
            echo
            __rpm_installed_help
            return 1
    end

    # ---- since / until override ----
    set -l freeform_date 0
    for i in (seq (count $argv))
        set -l token (string lower -- $argv[$i])
        switch $token
            case since
                set -l next (math $i + 1)
                if test $next -gt (count $argv)
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
                set freeform_date 1
            case until
                set -l next (math $i + 1)
                if test $next -gt (count $argv)
                    echo "❌ 'until' requires a date argument" >&2
                    return 1
                end
                set -l parsed (env LC_ALL=en_US.UTF-8 date -d "$argv[$next] +1 day 00:00" +%s 2>/dev/null)
                if test -z "$parsed"
                    echo "❌ Invalid date for 'until': $argv[$next]" >&2
                    echo "   Expected a format understood by 'date -d' (e.g. YYYY-MM-DD)"
                    return 1
                end
                set e $parsed
                set freeform_date 1
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
        set -l heading "$arg"
        if test $n_days -gt 0
            set heading "last $n_days days"
        else if test $freeform_date -eq 1
            set heading "since "(env LC_ALL=en_US.UTF-8 date -d @$s +%Y-%m-%d)
            if test -n "$e"
                set heading "$heading until "(env LC_ALL=en_US.UTF-8 date -d @$e +%Y-%m-%d)
            end
        end
        __display_rpm_packages "$heading" $res
    end
end
