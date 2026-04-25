# Global helpers defined ONCE outside the main function — fixes scope leak

set -g __deb_use_cache 1

function __deb_installed_help
    echo "deb_installed — list installed packages (Debian/Ubuntu)"
    echo
    echo "USAGE:"
    echo "  deb_installed [OPTION]"
    echo "  deb_installed days N             # last N days (rolling window)"
    echo "  deb_installed since DATE [until DATE]"
    echo "  deb_installed count [OPTION]"
    echo "  deb_installed --refresh     # rebuild cache"
    echo "  deb_installed --cache on    # enable caching (default)"
    echo "  deb_installed --cache off   # always query dpkg logs live"
    echo "  deb_installed --cache       # show current cache status"
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
    echo "  deb_installed count today"
    echo "  deb_installed count days 5"
    echo "  deb_installed count last-week"
    echo "  deb_installed count per-day"
    echo "  deb_installed count per-week"
    echo "  deb_installed count since DATE [until DATE]"
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
    set -l cache_status $argv[1]
    set -l title $argv[2]
    set -l packages $argv[3..-1]
    set -l pkg_count (count $packages)

    if test $pkg_count -eq 0
        echo
        echo "     📭 No packages installed: $title"
        echo "        Try: deb_installed last-week or deb_installed this-month"
        echo
        return
    end

    # Build output into a temp file so we can decide whether to page it.
    set -l tmpfile (mktemp /tmp/deb_installed.XXXXXX)

    # First pass: build parallel arrays of dates and names.
    set -l dates
    set -l names
    for pkg in $packages
        set -l ts (string split --max 1 ' ' -- $pkg)[1]
        set -l name (string split --max 1 ' ' -- $pkg)[2]
        set -l day (date -d @$ts '+%a %Y-%m-%d' 2>/dev/null)
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

        # Second pass: emit grouped output.
        set -l current_date ""
        set -l i 1
        set -l total (count $names)
        while test $i -le $total
            set -l day $dates[$i]
            set -l name $names[$i]

            if test "$day" != "$current_date"
                set -l run 0
                set -l j $i
                while test $j -le $total; and test $dates[$j] = $day
                    set run (math $run + 1)
                    set j (math $j + 1)
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
        printf " 💾 Cache: %s\n" "$cache_status"
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

function deb_installed --description "List installed Debian/Ubuntu packages by install date with caching"

    # ---- Distro check ----
    if not test -f /etc/debian_version
        echo "❌ This function requires a Debian-based distribution"
        return 1
    end

    set -l arg (string lower -- $argv[1])

    # ---- Help ----
    switch $arg
        case -h --help
            __deb_installed_help
            return 0
    end

    # ---- Cache toggle ----
    if test "$arg" = --cache
        set -l subcmd (string lower -- $argv[2])
        switch $subcmd
            case on
                set -g __deb_use_cache 1
                echo "✅ Cache enabled."
            case off
                set -g __deb_use_cache 0
                set -e __deb_instlist_cache
                echo "⚡ Cache disabled. dpkg logs will be queried live on every call."
            case ''
                if test $__deb_use_cache -eq 1
                    if set -q __deb_instlist_cache
                        echo "Cache: enabled (populated)"
                    else
                        echo "Cache: enabled (empty — will build on next call)"
                    end
                else
                    echo "Cache: disabled (live dpkg log queries)"
                end
            case '*'
                echo "❌ Unknown cache option: '$subcmd'. Use on or off." >&2
                return 1
        end
        return 0
    end

    # ---- Refresh cache ----
    if test "$arg" = --refresh
        set -e __deb_instlist_cache
        echo "♻️  Cache cleared. Will rebuild on next call."
        return 0
    end

    # ---- Build cache if missing or disabled ----
    if test $__deb_use_cache -eq 1
        if not set -q __deb_instlist_cache
            set -g __deb_instlist_cache (__instlist_deb)
        end
    else
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
    set -l today_start (date -d 'today 00:00'      +%s)
    set -l tomorrow_start (date -d 'tomorrow 00:00'   +%s)
    set -l yesterday_start (date -d 'yesterday 00:00'  +%s)
    set -l last_week_start (date -d '7 days ago 00:00' +%s)
    set -l this_month_start (date -d (date +%Y-%m-01)   +%s)
    set -l last_month_start (date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Resolve s/e from $arg ----
    set -l s 0
    set -l e ""
    set -l n_days 0 # >0 when 'days N' was used; drives heading

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
                echo "❌ 'days' requires a number  →  deb_installed days 3" >&2
                return 1
            end
            if not string match -qr '^[1-9][0-9]*$' -- "$raw_n"
                echo "❌ 'days' expects a positive integer, got: '$raw_n'" >&2
                return 1
            end
            set n_days $raw_n
            set s (date -d "$n_days days ago 00:00" +%s)
            set e $tomorrow_start
        case per-day
            printf "%s\n" $__deb_instlist_cache |
                awk '{d=strftime("%Y-%m-%d",$1);c[d]++} END{for(d in c) print d,c[d]}' | sort
            return
        case per-week
            printf "%s\n" $__deb_instlist_cache |
                awk '{w=strftime("%Y-W%V",$1);c[w]++} END{for(w in c) print w,c[w]}' | sort
            return
        case since until
        case ''
            set s 0
        case '*'
            echo "❌ Invalid option: '$arg'"
            echo
            __deb_installed_help
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
                set -l parsed (date -d "$argv[$next] 00:00" +%s 2>/dev/null)
                if test -z "$parsed"
                    echo "❌ Invalid date for 'since': $argv[$next]" >&2
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
                set -l parsed (date -d "$argv[$next] +1 day 00:00" +%s 2>/dev/null)
                if test -z "$parsed"
                    echo "❌ Invalid date for 'until': $argv[$next]" >&2
                    return 1
                end
                set e $parsed
                set freeform_date 1
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
        set -l heading "$arg"
        if test $n_days -gt 0
            set heading "last $n_days days"
        else if test $freeform_date -eq 1
            set heading "since "(date -d @$s +%Y-%m-%d)
            if test -n "$e"
                set heading "$heading until "(date -d @$e +%Y-%m-%d)
            end
        end
        # Determine cache status label for footer
        set -l cache_status "session cache"
        if test $__deb_use_cache -eq 0
            set cache_status "live query"
        end
        __display_packages "$cache_status" "$heading" $res
    end
end
