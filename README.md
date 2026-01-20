# 🐟 Personal Fish configuration

This repository contains my personal Fish shell configuration and helper
functions. While some functions may be useful to others, this repository
is not intended to be a stable or supported public plugin collection.

Interfaces and behavior may change without notice.

---

# 🔧 Fish Various Config Functions

A collection of custom Fish shell functions, completions, and keybindings
used in my personal Fish setup and shared across my own machines.

All functions are Fisher-compatible, but this repository is primarily
maintained for personal use.

The functions below are documented for reference; interfaces and behavior
may change without notice.

## 📥 Installation

### 🎣 Using Fisher (recommended)

You can install all functions, completions, and keybindings automatically using Fisher:

```
fisher install fdel-ux64/fish-config
```

---

### 📦 `rpm_installed`

Formerly known as `instlist`. The old name is still supported as a wrapper.

This function is also available as a standalone Fish plugin:
<https://github.com/fdel-ux64/fish-rpm-installed>

List installed RPM packages by installation date, with caching for faster repeated queries.
This function only supports RPM-based distributions (e.g., Fedora, RHEL, CentOS), and ensures consistent date parsing by using the US English locale.
RPM availability check is done before execution.

**Scope:** RPM-based distributions

**Usage:**

* rpm\_installed [OPTION]
* rpm\_installed count [OPTION]
* rpm\_installed since DATE [until DATE]
* rpm\_installed --refresh
* rpm\_installed --help

| Option | Description |
| --- | --- |
| `today` | Packages installed today |
| `yesterday` | Packages installed yesterday |
| `last-week` | Packages installed in the last 7 days |
| `this-month` | Packages installed this calendar month |
| `last-month` | Packages installed in the previous month |
| `per-day` | Count packages per day |
| `per-week` | Count packages per week |



| Alias | Expands to |
| --- | --- |
| `td` | today |
| `yd` | yesterday |
| `lw` | last-week |
| `tm` | this-month |
| `lm` | last-month |

**Examples:**

* rpm\_installed td
* rpm\_installed last-week
* rpm\_installed count this-month
* rpm\_installed since 2025-12-16 until 2025-12-22
* rpm\_installed --refresh
* rpm\_installed --help

---

### 🚀 `advanced_install_package`

A versatile package installer that supports multiple Linux distributions (Fedora, Manjaro/Arch, or Ubuntu/Debian) and provides informative feedback.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Optional Dependencies:**

* sudo (for package installation)
* Internet connection

**Usage:**

advanced\_install\_package [package\_name]

**Behavior:**

* Auto-detects your distro and installs the package.
* If the package is already installed, it shows a message without reinstalling.
* If no package name is provided, prompts interactively.
* Provides error messages if installation fails.

**Example:**

* advanced\_install\_package vim
* advanced\_install\_package vim htop curl
* advanced\_install\_package # interactive prompt

---

### 📋 `list_installed_packages_expac`

Interactive Fish shell function that displays packages installed today, yesterday, or in the last week, with installation timestamps using `expac`.

**Scope:** Arch based distributions (Manjaro / Arch). Check the distro and provide information if not Arch based.

**Optional Dependencies:**

* `expac` package (usually pre-installed)
* Fish shell

**Usage:**

list\_installed\_packages\_expac [PERIOD]

Valid periods:

* today
* yesterday
* last-week

**Note:**
This function relies on GNU `date` for timestamp conversion. If no PERIOD is provided, the function prompts interactively.

**Behavior:**

* 📅 Filter by time period (today/yesterday/last 7 days)
* 🕐 Shows exact installation timestamp
* 📊 Displays package count
* 🎨 Clean, formatted output with Unicode borders
* ⚡ Fast execution using `expac`

**Example:**

* list\_installed\_packages\_expac
* list\_installed\_packages\_expac today
* list\_installed\_packages\_expac -h

---

### 🔄 `fisher_update_select`

Interactive **and non-interactive** helper to update Fisher plugins selectively or in bulk.

Instead of always updating all plugins, this function presents a numbered, alphabetically
sorted list of installed Fisher plugins and allows selecting one or multiple plugins to update.
It also supports fully non-interactive usage for scripting and automation.

**Scope:** Fish shell with Fisher plugin manager

**Requirements:**

* Fish shell
* Fisher (the `fisher` command must be available)

**Usage:**

```
fisher_update_select
fisher_update_select --all
fisher_update_select --all --yes
```

**Behavior:**

**Interactive mode (default):**

* Displays installed Fisher plugins as a numbered, sorted list
* Allows selecting:
  + one plugin
  + multiple plugins (space-separated numbers)
  + all plugins (`a`)
* Confirmation prompt before performing updates
* Safe exit without changes (n or q)
* Input validation to prevent accidental updates

**Non-interactive mode:**

* `--all`
  Update all installed plugins, with confirmation

**Additional flags:**

* `--yes`
  Automatically confirm update prompts (useful for scripting)

**Selection examples:**

* `1 3 5` → update selected plugins
* `a` → update all plugins
* `q` / `n` → quit without updating

**Notes:**

* Plugin list is retrieved using `fisher list` and sorted alphabetically
* No version or commit information is shown, as Fisher installs may not reliably expose version metadata
* Acts as a thin, safe wrapper around `fisher update`
* Designed for intentional plugin maintenance in larger Fish setups

---

### 🔐 `generate_password`

Generate secure random passwords using **Fish shell only** — no external generators required.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Environment-aware:** Desktop-friendly, server-safe

**Features:**

* Cryptographically secure randomness (Fish built-in `random`)
* Customizable length and count
* Mixed character set:
  + lowercase & uppercase letters
  + digits
  + symbols (`/-+;:,!&'({*?|}%`)
* Interactive prompts with sensible defaults
* Environment-aware clipboard handling
  + Automatically copies the first password on Wayland desktops
  + Auto-clears clipboard after a configurable timeout
  + Gracefully skips clipboard logic on servers / SSH sessions
* Zero required dependencies (clipboard support is optional)

**Usage:**

* generate\_password [OPTIONS] [LENGTH] [COUNT]
* generate\_password # interactive mode

  **Options:**

  + --no-clipboard
    Disable clipboard auto-copy entirely
  + --clipboard-timeout
    Set clipboard clear timeout (default: 30)
  + -h, --help
    Show help

**Example:**

```
 generate_password
 generate_password 20
 generate_password 15 5
 generate_password --no-clipboard
 generate_password --clipboard-timeout 10
 generate_password 32 2 --clipboard-timeout 5
```

Designed to behave sensibly across desktops, servers, and SSH sessions without configuration.

---

## 📜 History & Shell UX Helpers

### 🔍 `search_history`

Search command history with optional interactive cleanup.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**

* `search_history [OPTIONS] [PATTERN]`
* `search_history` # interactive prompt mode
* `search_history PATTERN` # search for pattern
* `search_history -c PATTERN` # search and offer cleanup

**Options:**

* `-c, --cleanup` - Offer to clean up matching entries after search
* `-h, --help` - Show help

**Features:**

* Uses ripgrep (rg) if available, falls back to grep
* Case-insensitive search by default
* Can be triggered using CTRL+H
* Optional interactive cleanup of search results
* Choose to delete all matches or select specific entries

**Behavior:**

* If no pattern is provided, displays recent history
* If a pattern is provided, filters history entries
* With `-c` flag, offers cleanup options after displaying results:
  + `all` - Delete all matching entries
  + `select` - Choose specific entries by number (e.g., `1 3 5`)
  + `N` - Skip cleanup

**Examples:**

* `search_history git` # find all git commands
* `search_history -c 'git push'` # search and offer cleanup
* `search_history rpm install` # find rpm install commands
* `search_history` # interactive prompt

---

### 🧹 `cleanup_history`

Standalone interactive history cleanup tool.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**

* `cleanup_history [PATTERN]`
* `cleanup_history` # prompt for pattern

**Behavior:**

* Displays matching history entries with numeric indexes
* Supports deleting:
  + selected entries (space-separated numbers)
  + all matches (`all`)
* Safe quit without changes (`n`, `q`, empty input)
* Uses exact, case-sensitive deletion to avoid accidental removals

**Example:**

* `cleanup_history git push`
* `cleanup_history rpm_installed`

**Note:** For integrated search and cleanup workflow, use `search_history -c` instead.

---

### 🔎 `inspect_function`

Search, display, and optionally edit Fish shell functions.

**Optional dependencies:**

bat for paging, fzf for fuzzy selection.

**Usage:**

showfunc [FUNCTION_NAME or PATTERN]

**Behavior:**

* Displays the content of a function matching the given name or pattern.
* If multiple matches are found:
  + Uses fzf for fuzzy selection if installed
  + Falls back to numbered selection
* Long functions are displayed in a pager (bat or less)
* Can edit user-defined functions with $EDITOR.

**Key Binding:**

* Trigger with CTRL+F in the terminal.

**Example:**

* `inspect_function kver`
* `inspect_function generate_password`

---

### 🐧 `kver`

Display the current kernel version.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**

kver

**Behavior:**

* Prints the current kernel version.
* Prompts to visit kernel.org

---

**⌨️ Keybindings Summary:**

| Keybinding | Function |
| --- | --- |
| CTRL+F | inspect_function |
| CTRL+H | search_history   |
