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

### `install_package`

Install a package using the correct package manager by auto-detecting your Linux distro (Fedora, Manjaro/Arch, or Ubuntu/Debian).

**Usage:**

- install_package [package_name]

**Behavior:**

- Auto-detects Fedora, Manjaro/Arch, or Ubuntu/Debian
- If auto-detection fails, it prompts for your distro.
- If the package name is not provided, it prompts interactively.

**Example:**

install_package vim

---

### `advanced_install_package`

A versatile package installer that supports multiple Linux distributions and provides informative feedback.

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

### `instlist`

List installed RPM packages by installation date, with caching for faster repeated queries.
This function only supports RPM-based distributions (e.g., Fedora, RHEL, CentOS), and ensures consistent date parsing by using the US English locale.

**Usage:**

- instlist [OPTION]
- instlist count [OPTION]
- instlist since DATE [until DATE]
- instlist --refresh
- instlist --help



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

- instlist td
- instlist last-week
- instlist count this-month
- instlist since 2025-12-16 until 2025-12-22
- instlist --refresh
- instlist --help

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

### `kver`
Display the current kernel version.

**Usage:**

kver

**behavior:**

- Prints the current kernel version.
- Prompts to visit kernel.org

---

### `generate_password`
Generate secure passwords using fish random.

**Usage:**

- generate_password [LENGTH] [COUNT]
- generate_password  # prompts interactively

**Example:**

- generate_password
- generate_password 15 5

----

**Keybindings Summary:**

| Keybinding | Function
|------------|-----------------------|
| CTRL+F     | showfunc              |
| CTRL+H	   | shisto/search_history |





