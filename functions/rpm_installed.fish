function rpm_installed --description "List installed RPM packages by install date with caching"
    set -l arg $argv[1]

    # ---- Refresh cache ----
    if test "$arg" = "--refresh"
        set -e __instlist_cache
        echo "♻️ Cache cleared and will be rebuilt on next command."
        return 0
    end

    # ---- Help flag ----
    switch $arg
        case -h --help
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
            return 0
    end

    # ---- Alias normalization ----
    switch $arg
        case td; set arg today
        case yd; set arg yesterday
        case lw; set arg last-week
        case tm; set arg this-month
        case lm; set arg last-month
    end

    # ---- Heading ----
    set -l heading
    switch $arg
        case today;       set heading "today"
        case yesterday;   set heading "yesterday"
        case last-week;   set heading "in the last week"
        case this-month;  set heading "this month"
        case last-month;  set heading "last month"
    end

    # ---- Backend helper ----
    function __instlist_rpm
        rpm -qa --qf '%{INSTALLTIME} (%{INSTALLTIME:date}): %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'
    end

    set backend_func __instlist_rpm

    # ---- Caching ----
    if not set -q __instlist_cache
        set -g __instlist_cache ($backend_func)
    end

    # ---- Count / Stats mode & custom ranges ----
    set -l count_mode 0
    set -l since_epoch ""
    set -l until_epoch ""

    if test -n "$arg"
        if test "$arg" = count; or test "$arg" = stats
            set count_mode 1
            set arg $argv[2]
        end
    end

    # ---- Detect since/until ----
    for i in (seq (count $argv))
        if test $argv[$i] = since
            set idx (math $i + 1)
            set since_epoch (env LC_ALL=en_US.UTF-8 date -d "$argv[$idx] 00:00" +%s 2>/dev/null)
            if test -z "$since_epoch"
                echo "❌ Invalid date: $argv[$idx]"
                return 1
            end
        else if test $argv[$i] = until
            set idx (math $i + 1)
            set until_epoch (env LC_ALL=en_US.UTF-8 date -d "$argv[$idx] 00:00" +%s 2>/dev/null)
            if test -z "$until_epoch"
                echo "❌ Invalid date: $argv[$idx]"
                return 1
            end
        end
    end

    # ---- Time boundaries ----
    set -l today_start      (env LC_ALL=en_US.UTF-8 date -d 'today 00:00' +%s)
    set -l tomorrow_start   (env LC_ALL=en_US.UTF-8 date -d 'tomorrow 00:00' +%s)
    set -l yesterday_start  (env LC_ALL=en_US.UTF-8 date -d 'yesterday 00:00' +%s)
    set -l last_week_start  (env LC_ALL=en_US.UTF-8 date -d '7 days ago 00:00' +%s)
    set -l this_month_start (env LC_ALL=en_US.UTF-8 date -d (date +%Y-%m-01) +%s)
    set -l last_month_start (env LC_ALL=en_US.UTF-8 date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Execute with caching for since/until ----
    if test -n "$since_epoch"
        if test $count_mode -eq 1
            if test -n "$until_epoch"
                printf "%s\n" $__instlist_cache | awk -v s="$since_epoch" -v e="$until_epoch" '{if($1>=s && $1<e) count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | awk -v s="$since_epoch" '{if($1>=s) count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            end
        else
            if test -n "$until_epoch"
                printf "%s\n" $__instlist_cache | awk -v s="$since_epoch" -v e="$until_epoch" '$1>=s && $1<e' | sort -n
            else
                printf "%s\n" $__instlist_cache | awk -v s="$since_epoch" '$1>=s' | sort -n
            end
        end
        return
    end

    # ---- Predefined ranges & counts ----
    switch $arg
        case ''
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache | awk '{count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | sort -n
            end

        case today
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache | awk -v s="$today_start" -v e="$tomorrow_start" '$1>=s && $1<e {count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | awk -v s="$today_start" -v e="$tomorrow_start" '$1>=s && $1<e' | sort -n
            end

        case yesterday
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache | awk -v s="$yesterday_start" -v e="$today_start" '$1>=s && $1<e {count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | awk -v s="$yesterday_start" -v e="$today_start" '$1>=s && $1<e' | sort -n
            end

        case last-week
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache | awk -v s="$last_week_start" '$1>=s {count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | awk -v s="$last_week_start" '$1>=s' | sort -n
            end

        case this-month
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache | awk -v s="$this_month_start" '$1>=s {count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | awk -v s="$this_month_start" '$1>=s' | sort -n
            end

        case last-month
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache | awk -v s="$last_month_start" -v e="$this_month_start" '$1>=s && $1<e {count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort
            else
                printf "%s\n" $__instlist_cache | awk -v s="$last_month_start" -v e="$this_month_start" '$1>=s && $1<e' | sort -n
            end

        case per-day
            printf "%s\n" $__instlist_cache | awk '{count[strftime("%Y-%m-%d",$1)]++} END{for(d in count) printf "%s  %d\n", d, count[d]}' | sort

        case per-week
            printf "%s\n" $__instlist_cache | awk '{count[strftime("%Y-W%V",$1)]++} END{for(w in count) printf "%s  %d\n", w, count[w]}' | sort

        case '*'
            echo "❌ Invalid option: '$arg'"
            echo "Run 'rpm_installed --help' for usage."
    end
end
