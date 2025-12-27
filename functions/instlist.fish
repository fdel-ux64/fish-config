function instlist --description "List installed RPM packages by install date"
    set -l arg $argv[1]

    # ---- Help flag ----
    switch $arg
        case -h --help
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

    # ---- RPM helper ----
    function __instlist_rpm
        rpm -qa --qf '%{INSTALLTIME} (%{INSTALLTIME:date}): %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'
    end

    # ---- Time boundaries ----
    set -l today_start      (date -d 'today 00:00' +%s)
    set -l tomorrow_start   (date -d 'tomorrow 00:00' +%s)
    set -l yesterday_start  (date -d 'yesterday 00:00' +%s)
    set -l last_week_start  (date -d '7 days ago 00:00' +%s)
    set -l this_month_start (date -d (date +%Y-%m-01) +%s)
    set -l last_month_start (date -d (date +%Y-%m-01)' -1 month' +%s)

    # ---- Selection ----
    set -l result
    switch $arg
        case ''
            __instlist_rpm | sort -n
            return

        case today
            set result (__instlist_rpm | awk -v s="$today_start" -v e="$tomorrow_start" '$1 >= s && $1 < e' | sort -n)

        case yesterday
            set result (__instlist_rpm | awk -v s="$yesterday_start" -v e="$today_start" '$1 >= s && $1 < e' | sort -n)

        case last-week
            set result (__instlist_rpm | awk -v s="$last_week_start" '$1 >= s' | sort -n)

        case this-month
            set result (__instlist_rpm | awk -v s="$this_month_start" '$1 >= s' | sort -n)

        case last-month
            set result (__instlist_rpm | awk -v s="$last_month_start" -v e="$this_month_start" '$1 >= s && $1 < e' | sort -n)

        case '*'
            echo "❌ Invalid option: '$arg'"
            echo "Run 'instlist --help' for usage."
            return 1
    end

    # ---- Output ----
    if test (count $result) -eq 0
        read --prompt-str "No packages found. Show full list? (y/N) " reply
        switch $reply
            case y Y
                __instlist_rpm | sort -n
        end
    else
        test -n "$heading"; and begin
            echo
            echo "📦 Packages installed $heading"
            echo
        end
        printf "%s\n" $result
    end
end
