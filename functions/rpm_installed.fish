function rpm_installed --description "List RPM packages installed within a time period"
    # ---- Distro check ----
    if not command -q rpm
        echo "❌ This function requires RPM package manager"
        echo "   Current system does not appear to be RPM-based"
        return 1
    end
    
    # Parse arguments
    set -l period ""
    set -l period_desc ""
    
    if test (count $argv) -eq 0
        echo "Usage: rpm_installed [td|yd|lw|lm]"
        echo "  td  - today"
        echo "  yd  - yesterday"
        echo "  lw  - last 7 days"
        echo "  lm  - last 30 days"
        return 1
    end
    
    set period $argv[1]
    
    # Calculate time boundaries
    set -l start_time 0
    set -l current_time (date +%s)
    
    switch $period
        case td
            set start_time (date -d "00:00:00" +%s)
            set period_desc "today"
        case yd
            set start_time (date -d "yesterday 00:00:00" +%s)
            set -l end_time (date -d "yesterday 23:59:59" +%s)
            set period_desc "yesterday"
        case lw
            set start_time (date -d "7 days ago 00:00:00" +%s)
            set period_desc "in the last 7 days"
        case lm
            set start_time (date -d "30 days ago 00:00:00" +%s)
            set period_desc "in the last 30 days"
        case '*'
            echo "Invalid period: $period"
            echo "Use: td (today), yd (yesterday), lw (last week), lm (last month)"
            return 1
    end
    
    # Print section title
    echo -e "\n       📦 List of installed packages $period_desc"
    echo -e "       ╰─────────────────────────────────────────────────────────╯\n"
    
    # Query RPM database and filter by time
    set -l packages (rpm -qa --queryformat "%{INSTALLTIME} %{INSTALLTID} %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n" | sort -rn)
    set -l filtered_packages
    set -l count 0
    
    for pkg in $packages
        set -l install_time (echo $pkg | awk '{print $1}')
        
        # Check if package was installed in the specified period
        if test $install_time -ge $start_time
            # For yesterday, also check upper bound
            if test "$period" = "yd"
                if test $install_time -le $end_time
                    set -a filtered_packages $pkg
                    set count (math $count + 1)
                end
            else
                set -a filtered_packages $pkg
                set count (math $count + 1)
            end
        else
            # Since packages are sorted by install time (newest first), we can break early
            break
        end
    end
    
    # Display the filtered packages
    if test $count -gt 0
        for pkg in $filtered_packages
            set -l timestamp (echo $pkg | awk '{print $1}')
            set -l package_info (echo $pkg | awk '{$1=""; print $0}' | string trim)
            set -l formatted_date (date -d @$timestamp "+%a %d %b %Y %I:%M:%S %p %Z")
            echo "$timestamp ($formatted_date): $package_info"
        end
    else
        echo "No packages installed $period_desc"
    end
    
    # Print total count
    echo -e "\n🔢 Total number of package(s): $count\n"
end
