## Personal Fish configuration

This repository contains my personal Fish shell configuration and helper
functions. While some functions may be useful to others, this repository
is not intended to be a stable or supported public plugin.

---

# Fish Various Config Functions

A collection of custom Fish shell functions, completions, and keybindings
used in my personal Fish setup and shared across my own machines.

All functions are Fisher-compatible, but this repository is primarily
maintained for personal use. 

The functions below are documented for reference; interfaces and behavior
may change without notice.



## Installation

### Using Fisher (recommended)

You can install all functions, completions, and keybindings automatically using Fisher:

fisher install fdel-ux64/fish-config

---

### `rpm_installed`

Formerly known as `instlist`. The old name is still supported as a wrapper.

This function is also available as a standalone Fish plugin:
https://github.com/fdel-ux64/fish-rpm-installed

List installed RPM packages by installation date, with caching for faster repeated queries.
This function only supports RPM-based distributions (e.g., Fedora, RHEL, CentOS), and ensures consistent date parsing by using the US English locale.

**Usage:**

- rpm_installed [OPTION]
- rpm_installed count [OPTION]
- rpm_installed since DATE [until DATE]
- rpm_installed --refresh
- rpm_installed --help



| Option       | Description                              |
| ------------ | ---------------------------------------- |
| `today`      | Packages installed today                 |
| `yesterday`  | Packages installed yesterday             |
| `last-week`  | Packages installed in the last 7 days    |
| `this-month` | Packages installed this calendar month   |
| `last-month` | Packages installed in the previous month |
| `per-day`    | Count packages per day                   |
| `per-week`   | Count packages per week                  |


| Alias | Expands to |
| ----- | ---------- |
| `td`  | today      |
| `yd`  | yesterday  |
| `lw`  | last-week  |
| `tm`  | this-month |
| `lm`  | last-month |


**Examples:**

- rpm_installed td
- rpm_installed last-week
- rpm_installed count this-month
- rpm_installed since 2025-12-16 until 2025-12-22
- rpm_installed --refresh
- rpm_installed --help

---

### `advanced_install_package`

A versatile package installer that supports multiple Linux distributions Fedora, Manjaro/Arch, or Ubuntu/Debian) and provides informative feedback.

**Optional Dependencies:**
- sudo (for package installation)
- Internet connection


**Usage:**

  advanced_install_package [package_name]

**Behavior:**

- Auto-detects your distro and installs the package.
- If the package is already installed, it shows a message without reinstalling.
- If no package name is provided, prompts interactively.
- Provides error messages if installation fails.

**Example:**

- advanced_install_package vim
- advanced_install_package vim htop curl
- advanced_install_package  # interactive prompt

---

### `list_installed_packages_expac`

Interactive Fish shell function that displays packages installed today, yesterday, or in the last week, with installation timestamps using `expac`.

**Optional Dependencies:**
- Arch-based Linux distribution (Manjaro, Arch)
- `expac` package (usually pre-installed)
- Fish shell


**Usage:**

  list_installed_packages_expac [PERIOD]
  
  Valid periods:
  - today
  - yesterday
  - last-week
  
**Note:**
This function relies on GNU `date` for timestamp conversion. If no PERIOD is provided, the function prompts interactively.

**Behavior:**

- 📅 Filter by time period (today/yesterday/last 7 days)
- 🕐 Shows exact installation timestamp
- 📊 Displays package count
- 🎨 Clean, formatted output with Unicode borders
- ⚡ Fast execution using `expac`

**Example:**

- list_installed_packages_expac
- list_installed_packages_expac today
- list_installed_packages_expac -h

---

## generate_password

Generate secure random passwords using **Fish shell only** — no external generators required.

### Features

- Cryptographically secure randomness (Fish built-in `random`)
- Customizable length and count
- Mixed character set:
  - lowercase & uppercase letters
  - digits
  - symbols (`/-+;:,!&'({*?|}%`)
- Interactive prompts with sensible defaults
- Optional **Wayland clipboard support**:
  - Automatically copies the first password to the clipboard
  - Auto-clears clipboard after 30 seconds (requires `wl-clipboard`)
  - Gracefully degrades if not installed
 
**Usage:**

- generate_password [LENGTH] [COUNT]
- generate_password            # interactive mode

**Example:**

- generate_password
- generate_password 20
- generate_password 15 5

---

### `search_history / shisto`

Search a pattern in command history and display results.
Optional dependency: fzf for interactive selection.

**Usage:**

search_history [PATTERN]

shisto [PATTERN]


**Behavior:**

- If no pattern is provided, displays recent history.
- If a pattern is provided, filters history entries.
- Can be triggered using CTRL+H.

---

### `showfunc`

Search, display, and optionally edit Fish shell functions. 

**Optional dependencies:** 

bat for paging, fzf for fuzzy selection.

**Usage:**

showfunc [FUNCTION_NAME or PATTERN]

**Behavior:**

- Displays the content of a function matching the given name or pattern.
- If multiple matches are found:
- Uses fzf for fuzzy selection if installed
- Falls back to numbered selection
- Long functions are displayed in a pager (bat or less)
- Can edit user-defined functions with $EDITOR.


**Key Binding:**
- Trigger with CTRL+F in the terminal.

**Example:**

- showfunc kver
- showfunc inst

---

### `kver`
Display the current kernel version.

**Usage:**

kver

**behavior:**

- Prints the current kernel version.
- Prompts to visit kernel.org

---

**Keybindings Summary:**

| Keybinding | Function
|------------|-----------------------|
| CTRL+F     | showfunc              |
| CTRL+H	   | shisto/search_history |




