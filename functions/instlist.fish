function instlist
    set arg $argv[1]

    # ---- Help flag ----
    if test "$arg" = "--help" -o "$arg" = "-h"
        echo "instlist — list installed RPM packages by install date"
        echo
        echo "USAGE:"
        echo "  instlist [OPTION]"
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
        echo "EXAMPLES:"
        echo "  instlist td"
        echo "  instlist this-month"
        echo "  instlist --help"
        return 0
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

    # ---- Heading label ----
    switch $arg
        case today
            set heading "today"
        case yesterday
            set heading "yesterday"
        case last-week
            set heading "in the last week"
        case this-month
            set heading "this month"
        case last-month
            set heading "last month"
        case ''
            set heading ""
        case '*'
            set heading ""
    end

    set rpm_cmd rpm -qa --qf '%{INSTALLTIME} (%{INSTALLTIME:date}): %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'

    # ---- Time boundaries (epoch) ----
    set today_start       (date -d 'today 00:00' +%s)
    set tomorrow_start    (date -d 'tomorrow 00:00' +%s)

    set yesterday_start   (date -d 'yesterday 00:00' +%s)

    set last_week_start   (date -d '7 days ago 00:00' +%s)

    set this_month_start  (date -d "$(date +%Y-%m-01)" +%s)
    set last_month_start  (date -d "$(date +%Y-%m-01) -1 month" +%s)

    switch $arg
        case ''
            $rpm_cmd | sort -n
            return

        case today
            set result ($rpm_cmd | awk -v s="$today_start" -v e="$tomorrow_start" '$1 >= s && $1 < e' | sort -n)

        case yesterday
            set result ($rpm_cmd | awk -v s="$yesterday_start" -v e="$today_start" '$1 >= s && $1 < e' | sort -n)

        case last-week
            set result ($rpm_cmd | awk -v s="$last_week_start" '$1 >= s' | sort -n)

        case this-month
            set result ($rpm_cmd | awk -v s="$this_month_start" '$1 >= s' | sort -n)

        case last-month
            set result ($rpm_cmd | awk -v s="$last_month_start" -v e="$this_month_start" '$1 >= s && $1 < e' | sort -n)

        case '*'
            echo "❌ Invalid option: '$arg'"
            echo "Run 'instlist --help' for usage."
            return 1
    end

    if test (count $result) -eq 0
        read -P "No packages found. Show full list? (y/N) " reply
        if test "$reply" = y -o "$reply" = Y
            $rpm_cmd | sort -n
        end
    else
        if test -n "$heading"
            echo
            echo "📦 Packages installed $heading"
            echo
        end
        printf "%s\n" $result
    end
end
