function list_installed_packages_expac --description "List installed Arch packages by install date with caching using expac"

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

    set -l arg $argv[1]

    # ---- Refresh cache ----
    if test "$arg" = "--refresh"
        set -e __instlist_cache
        echo " ♻️ Cache cleared and will be rebuilt on next command."
        return 0
    end

    # ---- Help ----
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

    switch $arg
        case -h --help
            __arch_installed_help
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

    # ---- Backend helper ----
    function __instlist_arch
        # %l = install time, requires --timefmt=%s
        expac --timefmt=%s '%l (%l:date): %n-%v'
    end

    # ---- Cache ----
    if not set -q __instlist_cache
        set -g __instlist_cache (__instlist_arch)
    end

    # ---- Count / stats mode ----
    set -l count_mode 0
    if test "$arg" = count -o "$arg" = stats
        set count_mode 1
        set arg $argv[2]
    end

    # ---- Detect since / until ----
    set -l since_epoch ""
    set -l until_epoch ""

    for i in (seq (count $argv))
        switch $argv[$i]
            case since
                set idx (math $i + 1)
                set since_epoch (date -d "$argv[$idx] 00:00" +%s 2>/dev/null)
            case until
                set idx (math $i + 1)
                set until_epoch (date -d "$argv[$idx] 00:00" +%s 2>/dev/null)
        end
    end

    # ---- Time boundaries ----
    set -l today_start      (date -d 'today 00:00' +%s)
    set -l tomorrow_start   (date -d 'tomorrow 00:00' +%s)
    set -l yesterday_start  (date -d 'yesterday 00:00' +%s)
    set -l last_week_start  (date -d '7 days ago 00:00' +%s)
    set -l this_month_start (date -d (date +%Y-%m-01) +%s)
    set -l last_month_start (date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Display helper (shared UX) ----
    function __display_packages
        set -l title $argv[1]
        set -l pkgs  $argv[2..-1]

        echo -e "\n       📦 List of installed package(s): $title"
        echo "     ╰─────────────────────────────────────────────────────────"
        echo
        printf " %s\n" $pkgs
        echo -e "\n ────────────────────────────────────"
        echo " 🔢 Total number of package(s): "(count $pkgs)
        echo
    end

    # ---- Custom ranges ----
    if test -n "$since_epoch"
        if test $count_mode -eq 1
            printf " %s\n" $__instlist_cache |
                awk -v s="$since_epoch" -v e="$until_epoch" '
                    $1>=s && (!e || $1<e) {
                        d=strftime("%Y-%m-%d",$1); c[d]++
                    }
                    END{for(d in c) print d,c[d]}
                ' | sort
        else
            set -l res (
                printf " %s\n" $__instlist_cache |
                awk -v s="$since_epoch" -v e="$until_epoch" '$1>=s && (!e || $1<e)' |
                sort -n
            )
            __display_packages "custom range" $res
        end
        return
    end

    # ---- Predefined ranges ----
    switch $arg
        case ''
            if test $count_mode -eq 1
                printf "%s\n" $__instlist_cache |
                    awk '{d=strftime("%Y-%m-%d",$1);c[d]++} END{for(d in c) print d,c[d]}' | sort
            else
                __display_packages "all time" (printf "%s\n" $__instlist_cache | sort -n)
            end

        case today
            set s $today_start; set e $tomorrow_start
        case yesterday
            set s $yesterday_start; set e $today_start
        case last-week
            set s $last_week_start
        case this-month
            set s $this_month_start
        case last-month
            set s $last_month_start; set e $this_month_start
        case per-day
            printf "%s\n" $__instlist_cache |
                awk '{d=strftime("%Y-%m-%d",$1);c[d]++} END{for(d in c) print d,c[d]}' | sort
            return
        case per-week
            printf "%s\n" $__instlist_cache |
                awk '{w=strftime("%Y-W%V",$1);c[w]++} END{for(w in c) print w,c[w]}' | sort
            return
        case '*'
            echo "❌ Invalid option: $arg"
            __arch_installed_help
            return 1
    end

    if test $count_mode -eq 1
        printf "%s\n" $__instlist_cache |
            awk -v s="$s" -v e="$e" '$1>=s && (!e || $1<e){d=strftime("%Y-%m-%d",$1);c[d]++} END{for(d in c) print d,c[d]}' | sort
    else
        set -l res (
            printf "%s\n" $__instlist_cache |
            awk -v s="$s" -v e="$e" '$1>=s && (!e || $1<e)' |
            sort -n
        )
        __display_packages "$arg" $res
    end
end
