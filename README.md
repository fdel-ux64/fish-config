# Fish Config Functions
A collection of custom [Fish shell](https://fishshell.com/) functions and completions, designed to be easily shared across machines.

## Current Functions

### `instlist`
List installed RPM packages by install date.

**Usage:**

fish
instlist [OPTION]

**OPTIONS are:
today	-> Packages installed today
yesterday	-> Packages installed yesterday
last-week	-> Packages installed in the last 7 days
this-month ->	Packages installed this calendar month
last-month ->	Packages installed in the previous month

**Aliases:
Alias Expands to
td	  today
yd	  yesterday
lw	  last-week
tm	  this-month
lm	  last-month

**Examples:
instlist td
instlist this-month
instlist --help

**Behavior:
If no option is provided, lists all installed packages.
If no packages are found for a selected time range, it will prompt to show the full list.

