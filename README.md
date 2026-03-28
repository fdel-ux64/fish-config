# 🐟 Personal Fish configuration

A curated Fish shell toolkit with cross-distro utilities and reusable helpers.

Primarily maintained for personal use, but many utilities are **cross-distro compatible**, working on Arch, Debian/Ubuntu, and RPM-based Linux systems.

Not intended as a fully stable public plugin suite, yet mature tools are documented and may be useful to others.

Interfaces and behavior may evolve over time as the repository grows.

> 🐧 Works on Arch, Debian/Ubuntu, and RPM-based Linux distributions

---

## ✨ Highlights

- **Multi-distro package inspection**: unified `installed_packages` for Arch, Debian/Ubuntu, and RPM systems
- **Consistent package history** across distributions
- **Interactive Fish shell helpers**: search & cleanup history, inspect functions
- **Secure password generation** with environment-aware clipboard handling
- **Cross-platform kernel version checks**
- **Fisher-compatible** functions, completions, and keybindings

---

## 📥 Installation

### 🎣 Using Fisher (recommended)

Install all functions, completions, and keybindings automatically:

```
fisher install fdel-ux64/fish-config
```

---

> 🛠️ Cross-distro tools: Works on Arch, Debian/Ubuntu, and RPM-based Linux distributions

### 📦 installed_packages (Unified dispatcher)

Automatically lists installed packages using the appropriate backend for the current distribution.

This function detects your system and transparently calls:

- rpm_installed on RPM-based systems (Fedora, RHEL, CentOS…)
- deb_installed on Debian-based systems (Debian, Ubuntu, Mint, Pop!_OS…)
- arch_installed on Arch-based systems (Arch, Manjaro, EndeavourOS…)

It provides a single portable entry point while preserving full feature parity with the backend functions.

**Usage:**

- installed_packages [OPTION]
- installed_packages count [OPTION]
- installed_packages since DATE [until DATE]
- installed_packages --refresh
- installed_packages --backend

**Options**

All options supported by the backend functions are available, including:

| Option       | Description                              |
| ------------ | ---------------------------------------- |
| `today`      | Packages installed today                 |
| `yesterday`  | Packages installed yesterday             |
| `last-week`  | Packages installed in the last 7 days    |
| `this-month` | Packages installed this calendar month   |
| `last-month` | Packages installed in the previous month |
| `per-day`    | Count packages per day                   |
| `per-week`   | Count packages per week                  |


**Aliases**

| Alias | Expands to |
| ----- | ---------- |
| `td`  | today      |
| `yd`  | yesterday  |
| `lw`  | last-week  |
| `tm`  | this-month |
| `lm`  | last-month |

Aliases are case-insensitive (TD, Td, etc.).

**Extra flags**

| Flag        | Description                          |
| ----------- | ------------------------------------ |
| `--backend` | Show detected backend                |
| `--refresh` | Refresh cache (delegated to backend) |


**Examples**
```
installed_packages today
installed_packages td
installed_packages count last-week
installed_packages since 2026-02-01
installed_packages --backend
```

---

### 📦 `rpm_installed`

Backend implementation used by `installed_packages` on RPM-based systems.

This function is also available as a standalone Fish plugin:
<https://github.com/fdel-ux64/fish-rpm-installed>

List installed RPM packages by installation date, grouped by day, with caching for faster repeated queries.
This function only supports RPM-based distributions (e.g., Fedora, RHEL, CentOS), and ensures consistent date parsing by using the US English locale.
RPM availability check is done before execution.

**Scope:** RPM-based distributions

**Usage:**

* rpm\_installed [OPTION]
* rpm\_installed count [OPTION]
* rpm\_installed since DATE [until DATE]
* rpm\_installed --refresh
* rpm\_installed --cache on|off
* rpm\_installed --cache
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

| Flag | Description |
| --- | --- |
| `--refresh` | Clear and rebuild the cache on next call (caching stays enabled) |
| `--cache on` | Enable caching (default) |
| `--cache off` | Disable caching — RPM is queried live on every call |
| `--cache` | Show current cache status (enabled/disabled, populated or empty) |

**Output:**

Packages are grouped by installation date. Each date group shows a header with the package count, followed by the package names:

```
    📦 Installed packages — last-week
 📆 Wed 2026-03-18  (5 packages)
    onnx-libs-1.17.0-12.fc43.x86_64
    zlib-ng-2.3.3-2.fc43.x86_64
    zlib-ng-compat-2.3.3-2.fc43.x86_64
 📆 Thu 2026-03-19  (9 packages)
    firefox-148.0.2-2.fc43.x86_64
    libtasn1-4.21.0-1.fc43.x86_64
    ...
 ────────────────────────────────────
 🔢 Total: 14 packages
```

When the result exceeds 100 packages, the filter criteria is repeated in the footer alongside the total count, so context is preserved after scrolling:

```
 ────────────────────────────────────
 🔢 Total: 111 packages
 ↑  Showing 111 packages installed: last-month
```

The threshold is controlled by the global variable `__rpm_summary_threshold` (default: `100`).

**Examples:**

* rpm\_installed td
* rpm\_installed last-week
* rpm\_installed count this-month
* rpm\_installed since 2025-12-16 until 2025-12-22
* rpm\_installed --refresh
* rpm\_installed --cache off
* rpm\_installed --cache
* rpm\_installed --help

---

### 📦 `arch_installed`

Arch Linux equivalent of rpm_installed.

Backend implementation used by `installed_packages` on Arch-based systems.

Lists installed Arch packages by installation date, with caching for faster repeated queries.
Designed to provide **feature parity with** rpm_installed, using expac as the backend.

**Note:**
Formerly known as list_installed_packages_expac.
The old name is kept as a compatibility wrapper and may be removed in a future release.

**Scope:** Arch-based distributions (Arch Linux, Manjaro, EndeavourOS, etc.)

**Dependencies:**

* `expac` package (usually pre-installed)
* Fish shell
* GNU date (for date parsing and epoch conversion)

**Usage:**

* arch_installed [OPTION]
* arch_installed count [OPTION]
* arch_installed since DATE [until DATE]
* arch_installed per-day
* arch_installed per-week
* arch_installed --refresh
* arch_installed --help

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

**Output:**

When the result contains more than 25 packages, the filter criteria is repeated in the footer alongside the total count, so context is preserved after scrolling:
```
 ────────────────────────────────────
 🔢 Total number of package(s): 310
 ↑  Showing 310 package(s) installed: last-month
```
The threshold is controlled by the global variable `__arch_summary_threshold` (default: `25`).

**Example:**

* arch_installed td
* arch_installed last-week
* arch_installed count this-month
* arch_installed since 2024-01-01 until 2024-02-01
* arch_installed --refresh
* arch_installed --help

---

### 📦 `deb_installed`

Debian/Ubuntu equivalent of rpm_installed and arch_installed.

Backend implementation used by `installed_packages` on Debian-based systems.

Lists installed packages by installation date using dpkg logs, with caching for fast repeated queries.
Designed to provide **feature parity with** rpm_installed and arch_installed.

**Scope:** Debian-based distributions (Ubuntu, Debian, Linux Mint, Pop!_OS, etc.)

**Backend details:**

Uses dpkg installation logs:
* /var/log/dpkg.log
* Rotated logs (dpkg.log.*, including .gz)
Install timestamps are reconstructed from log entries.

**Dependencies:**

* Fish shell
* awk
* GNU date
* zcat (for rotated logs)

**Limitations:**

- Does **not include**:
* Snap packages
* Flatpak packages
* Very old installs may be missing if logs were rotated or deleted

**Usage:**

* deb_installed [OPTION]
* deb_installed count [OPTION]
* deb_installed since DATE [until DATE]
* deb_installed --refresh
* deb_installed --help

| Option       | Description                              |
| ------------ | ---------------------------------------- |
| `today`      | Packages installed today                 |
| `yesterday`  | Packages installed yesterday             |
| `last-week`  | Packages installed in the last 7 days    |
| `this-month` | Packages installed this calendar month   |
| `last-month` | Packages installed in the previous month |


| Alias | Expands to |
| ----- | ---------- |
| `td`  | today      |
| `yd`  | yesterday  |
| `lw`  | last-week  |
| `tm`  | this-month |
| `lm`  | last-month |

**Output:**

When the result contains more than 25 packages, the filter criteria is repeated in the footer alongside the total count, so context is preserved after scrolling:
```
 ────────────────────────────────────
 🔢 Total number of package(s): 50
 ↑  Showing 50 package(s) installed: last-week
```
The threshold is controlled by the global variable `__deb_summary_threshold` (default: `25`).


**Example:**

* deb_installed td
* deb_installed last-week
* deb_installed count this-month
* deb_installed since 2024-01-01 until 2024-02-01
* deb_installed --refresh
* deb_installed --help

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

### 🐧 `kver`
Display the current kernel version and optionally compare with the latest stable release.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
```
kver [-c|--compare] [-h|--help]
```

**Options:**
- `-c, --compare` — Fetch and compare with the latest stable kernel from kernel.org
- `-h, --help` — Display help information

**Behavior:**
* Prints the current kernel version (from `uname -r`)
* With `-c` flag: Fetches the latest stable kernel version from kernel.org and compares
* Version comparison is numeric per segment (avoids lexicographic issues e.g. `6.9` vs `6.10`)
* Fetch has a 5s timeout — falls back gracefully if kernel.org is unreachable
* Prompts to visit kernel.org only if the fetch succeeded

**Examples:**
```
$ kver
Current Kernel Version: 6.19.7-200.fc43.x86_64
Visit kernel.org? (y/N):

$ kver -c
Current Kernel Version: 6.19.7-200.fc43.x86_64
Fetching latest kernel version from kernel.org...
Latest Stable Kernel:   6.19.8
ℹ️  A newer kernel is available.
Visit kernel.org? (y/N):
````

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
* Cryptographically secure randomness via `/dev/urandom` (replaces Fish built-in `random`)
* Customizable length and count
* Entropy warning when length is below the recommended minimum of 12
* Guaranteed character class coverage — every password contains at least one digit and one special character, shuffled into random positions
* Expanded mixed character set:
  + lowercase & uppercase letters
  + digits
  + symbols: `/-+;:,!&'({*?|}%@#$^~=_.<>[])`
* Optional ambiguous character exclusion (`--no-ambiguous`) for passwords meant to be typed manually — removes visually similar characters (`0`, `O`, `l`, `1`, `|`, `I`)
* Interactive prompts with sensible defaults
* Environment-aware clipboard handling
  + Automatically copies the first password on Wayland desktops
  + Auto-clears clipboard after a configurable timeout
  + Clear job is handed to `systemd` when available — survives terminal close
  + Falls back to `nohup` if `systemd-run` is not present
  + Gracefully skips clipboard logic on servers / SSH sessions
* Zero required dependencies (clipboard support is optional)

**Usage:**
* `generate_password [OPTIONS] [LENGTH] [COUNT]`
* `generate_password` — interactive mode

**Options:**

| Flag | Description |
|---|---|
| `--no-clipboard` | Disable clipboard auto-copy entirely |
| `--clipboard-timeout <sec>` | Set clipboard clear timeout (default: 30) |
| `--no-ambiguous` | Exclude visually similar characters (`0`,`O`,`l`,`1`,`\|`,`I`) |
| `-h, --help` | Show help |

**Examples:**
```
generate_password
generate_password 20
generate_password 15 5
generate_password --no-clipboard
generate_password --no-ambiguous
generate_password --clipboard-timeout 10
generate_password 32 2 --clipboard-timeout 5
generate_password 16 3 --no-ambiguous --no-clipboard
```

Designed to behave sensibly across desktops, servers, and SSH sessions without configuration.

---

## 🖼️  Image Utilities

### 🖼️ `resize_image`
Resize a single image or a batch of images in a directory by percentage or max dimension.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Dependencies:**
* `ImageMagick` (`magick` command, v7+)

**Usage:**
* `resize_image <image|dir> [size]`
* `resize_image` — interactive prompt for path and size
* `resize_image photo.jpg` — interactive size selection
* `resize_image photo.jpg 50` — resize to 50%
* `resize_image photo.jpg 1200` — resize to max 1200px
* `resize_image ./photos` — batch resize, interactive size
* `resize_image ./photos 75` — batch resize to 75%

**Notes:**
* size ≤ 100 → percentage resize
* size > 100 → max dimension (preserves aspect ratio, never upscales)
* Output files are saved alongside the originals with a `-resized` suffix
* In batch mode, files already named `*-resized.*` are skipped automatically
* Supported formats: jpg, jpeg, png, gif, webp, tiff, bmp

**Examples:**
```
resize_image photo.jpg
resize_image photo.jpg 50
resize_image photo.jpg 1200
resize_image ~/Pictures/trip/
resize_image ~/Pictures/trip/ 800
```

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
* Flexible deletion: delete all matches, select interactively, or specify numbers directly

**Behavior:**
* If no pattern is provided, displays recent history
* If a pattern is provided, filters history entries
* With `-c` flag, offers cleanup options after displaying results:
  + `all` - Delete all matching entries immediately
  + `select` - Enter interactive mode to choose entries one batch at a time
  + Direct numbers (e.g., `6` or `2 5 8`) - Delete specific entries immediately
  + `N` or `q` - Skip cleanup

**Cleanup Workflows:**
1. **Quick delete:** Type numbers directly (e.g., `6 8 9`) to delete those entries right away
2. **Interactive mode:** Type `select` to enter a loop where you can delete multiple batches
3. **Delete all:** Type `all` to remove all matching entries at once

**Examples:**
```fish
# Find all git commands
search_history git

# Search and cleanup interactively
search_history -c 'git push'
# Then choose: all / select / 6 / 2 5 8 / N

# Quick cleanup of specific entries
search_history -c rpm
# Type: 1 3 5  (deletes entries 1, 3, and 5 immediately)

# Interactive prompt mode
search_history
```

---

### 🧹 `cleanup_history`

Standalone interactive history cleanup tool.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
* `cleanup_history PATTERN`
* `cleanup_history -h` # show help

**Behavior:**
* Displays matching history entries with numeric indexes
* Supports deleting:
  + Selected entries (space-separated numbers)
  + All matches (`all`)
* Safe quit without changes (`n`, `q`, empty input)
* Uses exact, case-sensitive deletion to avoid accidental removals

**Examples:**
* `cleanup_history 'git push'`
* `cleanup_history rpm_installed`
* `cleanup_history cd`

**Note:** For integrated search and cleanup workflow, use `search_history -c` instead.

---

### 🧹 `clean_session_history`

Clear the current Fish shell session history with safety features including confirmation prompts and visual countdown.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**

* `clean_session_history [OPTIONS]`
* `clean_session_history` # interactive mode with confirmation
* `clean_session_history --yes` # immediate clearing
* `clean_session_history --wait 5` # custom countdown time

**Options:**

* `-y, --yes` - Clear immediately without prompt or delay
* `-w, --wait SECONDS` - Set countdown duration (default: 10 seconds)
* `-h, --help` - Show help message

**Features:**

* **Safety first**: Requires confirmation before clearing
* **Visual feedback**: Progress bar countdown before deletion
* **Non-interactive protection**: Requires `--yes` flag in scripts
* **Customizable delay**: Adjust countdown time to your preference
* **Session-only**: Only clears current session, not saved history

**Behavior:**

* In interactive mode (default):
  + Prompts for confirmation
  + Shows 10-second countdown with progress bar
  + Allows cancellation before clearing
* With `--yes` flag:
  + Skips confirmation and countdown
  + Clears immediately (useful for scripts)
* In non-interactive shells:
  + Requires `--yes` flag to proceed
  + Prevents accidental clearing in scripts

**Examples:**

* `clean_session_history` # interactive with 10s countdown
* `clean_session_history -w 5` # 5-second countdown
* `clean_session_history --yes` # immediate clearing
* `clean_session_history -h` # show help

**Note:** This function only clears the current session history. To clear all saved history, use Fish's built-in `history clear` command.

---

### 🔎 `inspect_function`

Search, display, and optionally edit Fish shell functions.

**Optional dependencies:**

bat for paging, fzf for fuzzy selection.

**Usage:**

inspect_function [FUNCTION_NAME or PATTERN]

**Behavior:**

* Displays the content of a function matching the given name or pattern.
* If multiple matches are found:
  + Uses fzf for fuzzy selection if installed
  + Falls back to numbered selection
* Long functions are displayed in a pager (bat or less)
* Can edit user-defined functions with $EDITOR.

**Example:**

* `inspect_function kver`
* `inspect_function generate_password`

---

**⌨️ Keybindings Summary:**

| Keybinding | Function |
| --- | --- |
| CTRL+H | search_history   |
