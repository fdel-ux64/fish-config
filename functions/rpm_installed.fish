# ---- Global helpers — defined once, outside main function ----

set -g __rpm_summary_threshold 75
set -g __rpm_use_cache 1

function __rpm_installed_help
    echo "rpm_installed — list installed RPM packages by install date"
    echo
    echo "USAGE:"
    echo "  rpm_installed [OPTION]"
    echo "  rpm_installed days N             # last N days (rolling window)"
    echo "  rpm_installed on DATE            # exact date, e.g. on 2026-05-15"
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
    echo "PACKAGE SEARCH:"
    echo "  rpm_installed package NAME        # exact name match"
    echo "  rpm_installed package 'PATTERN'   # glob, e.g. 'kern*' or '*lib*'"
    echo "  Note: always quote patterns containing * to prevent shell expansion"
    echo
    echo "COUNT / STATS:"
    echo "  rpm_installed count today"
    echo "  rpm_installed count days 5"
    echo "  rpm_installed count last-week"
    echo "  rpm_installed count on DATE"
    echo "  rpm_installed count per-day"
    echo "  rpm_installed count per-week"
    echo "  rpm_installed count since DATE [until DATE]"
end

function __instlist_rpm
    rpm -qa --qf '%{INSTALLTIME} %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'
end

function __display_rpm_packages
    set -l cache_status $argv[1]
    set -l title $argv[2]
    set -l packages $argv[3..-1]
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

# ---- Package search display — shows time-to-the-minute, grouped by date ----
function __display_rpm_package_search
    set -l pattern      $argv[1]
    set -l cache_status $argv[2]
    set -l packages     $argv[3..-1]   # "<epoch> <nevra>" lines

    if test (count $packages) -eq 0
        echo
        echo "     📭 No install history found for '$pattern'"
        echo "        The package may not be installed, or the name/pattern doesn't match."
        echo "        Tip: quote glob patterns — rpm_installed package 'kern*'"
        echo
        return
    end

    # Separate timestamps and names; build date labels
    set -l dates
    set -l times
    set -l names
    for pkg in $packages
        set -l ts   (string split --max 1 ' ' -- $pkg)[1]
        set -l name (string split --max 1 ' ' -- $pkg)[2]
        set -l day  (env LC_ALL=en_US.UTF-8 date -d @$ts '+%a %Y-%m-%d'  2>/dev/null)
        set -l hm   (env LC_ALL=en_US.UTF-8 date -d @$ts '+%H:%M %Z'     2>/dev/null)
        test -z "$day"; and set day unknown
        test -z "$hm";  and set hm "??:??"
        set -a dates $day
        set -a times $hm
        set -a names $name
    end

    set -l pkg_count (count $names)
    set -l tmpfile (mktemp /tmp/rpm_installed.XXXXXX)

    begin
        echo
        printf "    📦 Package history — %s\n" $pattern
        echo

        set -l current_date ""
        set -l i 1
        set -l total (count $names)
        while test $i -le $total
            set -l day  $dates[$i]
            set -l hm   $times[$i]
            set -l name $names[$i]

            if test "$day" != "$current_date"
                # Count how many entries share this date
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

            printf "    %s  %s\n" $hm $name
            set i (math $i + 1)
        end

        echo
        echo " ────────────────────────────────────"
        printf " 🔢 %d install record%s matching '%s'\n" \
            $pkg_count (test $pkg_count -eq 1 && echo "" || echo "s") $pattern
        printf " 💾 Cache: %s\n" "$cache_status"
        echo
    end >$tmpfile

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

    # ---- Warn on future-dated entries ----
    # RPM INSTALLTIME can be stamped with a wrong clock (e.g. NTP stepped the
    # clock backward after zypper ran). Those packages exceed the current epoch
    # and will never appear under 'today', 'yesterday', etc.
    set -l __rpm_now (date +%s)
    set -l __rpm_future (
        printf "%s\n" $__rpm_instlist_cache |
        awk -v now=$__rpm_now '$1 > now {count++} END {print count+0}'
    )
    if test "$__rpm_future" -gt 0
        set -l __rpm_future_oldest (
            printf "%s\n" $__rpm_instlist_cache |
            awk -v now=$__rpm_now '$1 > now {print $1}' |
            sort -n | head -1 |
            xargs -I{} date -d @{} '+%Y-%m-%d %H:%M %Z'
        )
        echo "⚠️  $__rpm_future package(s) have future timestamps in the RPM database." >&2
        echo "   Earliest affected: $__rpm_future_oldest" >&2
        echo "   Likely cause: system clock was corrected by NTP after a zypper transaction." >&2
        echo "   These packages won't appear under 'today' or 'yesterday'." >&2
        echo "   Use: rpm_installed since YYYY-MM-DD  to find them." >&2
        echo >&2
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

    # ---- package search mode ----
    if test "$arg" = package
        set -l raw_pattern $argv[2]
        if test -z "$raw_pattern"
            echo "❌ 'package' requires a name or pattern" >&2
            echo "   Usage: rpm_installed package cups" >&2
            echo "          rpm_installed package 'kern*'" >&2
            return 1
        end

        # Extract NAME from NEVRA (everything before the first '-' that precedes a digit,
        # i.e. strip -VERSION-RELEASE.ARCH).  We match the full NEVRA field with fnmatch
        # against the user pattern appended with '*' only when no glob chars are present,
        # so 'cups' matches 'cups-2.4.17-1.1.x86_64' without the user needing to type cups*.
        set -l has_glob 0
        string match -qr '[*?\[]' -- "$raw_pattern"; and set has_glob 1

        set -l matched
        for line in $__rpm_instlist_cache
            # line format: "<epoch> <nevra>"
            set -l ts   (string split --max 1 ' ' -- $line)[1]
            set -l nevra (string split --max 1 ' ' -- $line)[2]
            # Extract package NAME: capture everything before the first -<digit>
            set -l pkg_name (string match -r '^(.+?)-[0-9]' -- $nevra)[2]
            # Fallback for oddly-named entries (e.g. gpg-pubkey)
            test -z "$pkg_name"; and set pkg_name $nevra

            if test "$has_glob" = 1
                # User provided a glob — match against NAME only
                if string match -q -- $raw_pattern $pkg_name
                    set -a matched $line
                end
            else
                # Exact match against NAME
                if test "$pkg_name" = $raw_pattern
                    set -a matched $line
                end
            end
        end

        # Sort by timestamp ascending (already numeric first field)
        set -l sorted (printf "%s\n" $matched | sort -n)

        set -l cache_status "session cache"
        test $__rpm_use_cache -eq 0; and set cache_status "live query"

        __display_rpm_package_search "$raw_pattern" "$cache_status" $sorted
        return 0
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
    set -l on_date "" # non-empty when 'on DATE' was used; drives heading

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
        case on
            # Next positional arg shifts by 1 in count mode
            set -l raw_date $argv[(math $count_mode + 2)]
            if test -z "$raw_date"
                echo "❌ 'on' requires a date  →  rpm_installed on 2026-05-15" >&2
                return 1
            end
            set -l parsed_on (env LC_ALL=en_US.UTF-8 date -d "$raw_date 00:00" +%s 2>/dev/null)
            if test -z "$parsed_on"
                echo "❌ Invalid date for 'on': $raw_date" >&2
                echo "   Expected a format understood by 'date -d' (e.g. YYYY-MM-DD)" >&2
                return 1
            end
            set s $parsed_on
            set e (env LC_ALL=en_US.UTF-8 date -d "$raw_date +1 day 00:00" +%s)
            set on_date $raw_date
        case per-day
            printf "%s\n" $__rpm_instlist_cache |
                awk '{count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            return
        case per-week
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
        if test -n "$on_date"
            set heading "$on_date"
        else if test $n_days -gt 0
            set heading "last $n_days days"
        else if test $freeform_date -eq 1
            set heading "since "(env LC_ALL=en_US.UTF-8 date -d @$s +%Y-%m-%d)
            if test -n "$e"
                # Subtract one day (86400s) from e to show the inclusive end date as typed
                set -l e_display (math $e - 86400)
                set heading "$heading until "(env LC_ALL=en_US.UTF-8 date -d @$e_display +%Y-%m-%d)
            end
        end
        # Determine cache status label for footer
        set -l cache_status "session cache"
        if test $__rpm_use_cache -eq 0
            set cache_status "live query"
        end
        __display_rpm_packages "$cache_status" "$heading" $res
    end
end
