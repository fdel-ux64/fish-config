# 🐟 Personal Fish configuration

A curated Fish shell toolkit with cross-distro utilities and reusable helpers.

Primarily maintained for personal use, but many utilities are **cross-distro compatible**, working on Arch, Debian/Ubuntu, and RPM-based Linux systems.

Not intended as a fully stable public plugin suite, yet mature tools are documented and may be useful to others.

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

```
fisher install fdel-ux64/fish-config
```

---

> 🛠️ Cross-distro tools: Works on Arch, Debian/Ubuntu, and RPM-based Linux distributions

### 📦 `installed_packages` (Unified dispatcher)

Automatically detects your distribution and calls the appropriate backend:

- `rpm_installed` — RPM-based systems (Fedora, RHEL, CentOS…)
- `deb_installed` — Debian-based systems (Debian, Ubuntu, Mint, Pop!_OS…)
- `arch_installed` — Arch-based systems (Arch, Manjaro, EndeavourOS…)

Single portable entry point with full feature parity across backends.

**Usage:**

```
installed_packages [OPTION]
installed_packages count [OPTION]
installed_packages since DATE [until DATE]
installed_packages --refresh
installed_packages --backend
```

| Option | Alias | Description |
| --- | --- | --- |
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `last-week` | `lw` | Packages installed in the last 7 days |
| `this-month` | `tm` | Packages installed this calendar month |
| `last-month` | `lm` | Packages installed in the previous month |
| `per-day` | | Count packages per day |
| `per-week` | | Count packages per week |

Aliases are case-insensitive (TD, Td, etc.).

| Flag | Description |
| --- | --- |
| `--backend` | Show detected backend |
| `--refresh` | Refresh cache (delegated to backend) |

**Examples:**
```
installed_packages today
installed_packages lw
installed_packages count last-week
installed_packages since 2026-02-01
installed_packages --backend
```

---

### 📦 `rpm_installed`

Backend for RPM-based systems. Also available as a standalone plugin:
<https://github.com/fdel-ux64/fish-rpm-installed>

Lists installed RPM packages by installation date, grouped by day, with caching for faster repeated queries. Ensures consistent date parsing using the US English locale.

**Scope:** RPM-based distributions (Fedora, RHEL, CentOS…)

**Usage:**

```
rpm_installed [OPTION]
rpm_installed count [OPTION]
rpm_installed since DATE [until DATE]
rpm_installed --refresh | --cache on|off | --cache | --help
```

| Option | Alias | Description |
| --- | --- | --- |
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `last-week` | `lw` | Packages installed in the last 7 days |
| `this-month` | `tm` | Packages installed this calendar month |
| `last-month` | `lm` | Packages installed in the previous month |
| `per-day` | | Count packages per day |
| `per-week` | | Count packages per week |

| Flag | Description |
| --- | --- |
| `--refresh` | Clear and rebuild the cache on next call (caching stays enabled) |
| `--cache on` | Enable caching (default) |
| `--cache off` | Disable caching — RPM is queried live on every call |
| `--cache` | Show current cache status |

**Output:**

```
    📦 Installed packages — last-week
 📆 Wed 2026-03-18  (5 packages)
    onnx-libs-1.17.0-12.fc43.x86_64
    zlib-ng-2.3.3-2.fc43.x86_64
 📆 Thu 2026-03-19  (9 packages)
    firefox-148.0.2-2.fc43.x86_64
    libtasn1-4.21.0-1.fc43.x86_64
    ...
 ────────────────────────────────────
 🔢 Total: 14 packages
```

The footer repeats the filter label when the total exceeds 100 packages (`__rpm_summary_threshold`).

**Examples:**
```
rpm_installed lw
rpm_installed count this-month
rpm_installed since 2025-12-16 until 2025-12-22
rpm_installed --cache off
```

---

### 📦 `arch_installed`

Backend for Arch-based systems. Equivalent of `rpm_installed`, using `expac` as the data source.

**Scope:** Arch-based distributions (Arch Linux, Manjaro, EndeavourOS…)

**Dependencies:** `expac`, Fish shell, GNU date

**Usage:**

```
arch_installed [OPTION]
arch_installed count [OPTION]
arch_installed since DATE [until DATE]
arch_installed --refresh | --cache on|off | --cache | --help
```

| Option | Alias | Description |
| --- | --- | --- |
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `last-week` | `lw` | Packages installed in the last 7 days |
| `this-month` | `tm` | Packages installed this calendar month |
| `last-month` | `lm` | Packages installed in the previous month |
| `per-day` | | Count packages per day |
| `per-week` | | Count packages per week |

| Flag | Description |
| --- | --- |
| `--refresh` | Clear and rebuild the cache on next call (caching stays enabled) |
| `--cache on` | Enable caching (default) |
| `--cache off` | Disable caching — expac is queried live on every call |
| `--cache` | Show current cache status |

The footer repeats the filter label when the total exceeds 100 packages (`__arch_summary_threshold`).

**Examples:**
```
arch_installed lw
arch_installed count this-month
arch_installed since 2024-01-01 until 2024-02-01
arch_installed --cache off
```

---

### 📦 `deb_installed`

Backend for Debian-based systems. Equivalent of `rpm_installed`, reconstructing install timestamps from dpkg logs.

**Scope:** Debian-based distributions (Ubuntu, Debian, Linux Mint, Pop!_OS…)

**Dependencies:** Fish shell, awk, GNU date, zcat (for rotated logs)

**Backend details:** Reads `/var/log/dpkg.log` and rotated logs (`dpkg.log.*`, including `.gz`).

**Limitations:** Does not include Snap or Flatpak packages. Very old installs may be missing if logs were rotated or deleted.

**Usage:**

```
deb_installed [OPTION]
deb_installed count [OPTION]
deb_installed since DATE [until DATE]
deb_installed --refresh | --cache on|off | --cache | --help
```

| Option | Alias | Description |
| --- | --- | --- |
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `last-week` | `lw` | Packages installed in the last 7 days |
| `this-month` | `tm` | Packages installed this calendar month |
| `last-month` | `lm` | Packages installed in the previous month |
| `per-day` | | Count packages per day |
| `per-week` | | Count packages per week |

| Flag | Description |
| --- | --- |
| `--refresh` | Clear and rebuild the cache on next call (caching stays enabled) |
| `--cache on` | Enable caching (default) |
| `--cache off` | Disable caching — dpkg logs are queried live on every call |
| `--cache` | Show current cache status |

The footer repeats the filter label when the total exceeds 100 packages (`__deb_summary_threshold`).

**Examples:**
```
deb_installed lw
deb_installed count this-month
deb_installed since 2024-01-01 until 2024-02-01
deb_installed --cache off
```

---

### 🚀 `advanced_install_package`

A versatile package installer that supports multiple Linux distributions (Fedora, Manjaro/Arch, or Ubuntu/Debian) and provides informative feedback.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Optional Dependencies:** sudo, Internet connection

**Usage:**

```
advanced_install_package [package_name]
```

- Auto-detects your distro and installs the package
- If the package is already installed, shows a message without reinstalling
- If no package name is provided, prompts interactively

**Examples:**
```
advanced_install_package vim
advanced_install_package vim htop curl
advanced_install_package
```

---

### 🐧 `kver`

Display the current kernel version and optionally compare with the latest stable release.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
```
kver [-c|--compare] [-h|--help]
```

| Flag | Description |
| --- | --- |
| `-c, --compare` | Fetch and compare with the latest stable kernel from kernel.org |
| `-h, --help` | Display help information |

- Version comparison is numeric per segment (avoids lexicographic issues e.g. `6.9` vs `6.10`)
- Fetch has a 5s timeout — falls back gracefully if kernel.org is unreachable

**Examples:**
```
$ kver
Current Kernel Version: 6.19.7-200.fc43.x86_64

$ kver -c
Current Kernel Version: 6.19.7-200.fc43.x86_64
Latest Stable Kernel:   6.19.8
ℹ️  A newer kernel is available.
```

---

### 🔄 `fisher_update_select`

Interactive and non-interactive helper to update Fisher plugins selectively or in bulk.

**Scope:** Fish shell with Fisher plugin manager

**Requirements:** Fish shell, Fisher

**Usage:**
```
fisher_update_select
fisher_update_select --all
fisher_update_select --all --yes
```

| Flag | Description |
| --- | --- |
| `--all` | Update all installed plugins, with confirmation |
| `--yes` | Skip confirmation prompt (useful for scripting) |

- Presents a numbered, alphabetically sorted list of installed plugins
- Accepts single, multiple (space-separated), or all (`a`) selections
- Safe exit without changes (`n` or `q`)

---

### 🔐 `generate_password`

Generate secure random passwords using Fish shell only — no external generators required.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)
**Environment-aware:** Desktop-friendly, server-safe

**Features:**
- Cryptographically secure randomness via `/dev/urandom`
- Guaranteed character class coverage (digit + special character in every password)
- Optional ambiguous character exclusion (`--no-ambiguous`) for passwords meant to be typed manually
- Environment-aware clipboard handling on Wayland desktops — auto-clears after timeout, survives terminal close via systemd

**Usage:**
```
generate_password [OPTIONS] [LENGTH] [COUNT]
generate_password
```

| Flag | Description |
| --- | --- |
| `--no-clipboard` | Disable clipboard auto-copy entirely |
| `--clipboard-timeout <sec>` | Set clipboard clear timeout (default: 30) |
| `--no-ambiguous` | Exclude visually similar characters (`0`,`O`,`l`,`1`,`\|`,`I`) |
| `-h, --help` | Show help |

**Examples:**
```
generate_password 20
generate_password 15 5
generate_password 32 2 --clipboard-timeout 5
generate_password 16 3 --no-ambiguous --no-clipboard
```

---

## 🖼️ Image Utilities

### 🖼️ `resize_image`

Resize a single image or a batch of images in a directory by percentage or max dimension.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Dependencies:** `ImageMagick` (`magick` command, v7+)

**Usage:**
```
resize_image <image|dir> [size]
```

- `size ≤ 100` → percentage resize
- `size > 100` → max dimension (preserves aspect ratio, never upscales)
- Output saved alongside originals with a `-resized` suffix
- Batch mode skips files already named `*-resized.*`
- Supported formats: jpg, jpeg, png, gif, webp, tiff, bmp

**Examples:**
```
resize_image photo.jpg 50
resize_image photo.jpg 1200
resize_image ~/Pictures/trip/ 800
```

---

## 📜 History & Shell UX Helpers

### 🔍 `search_history`

Search command history with optional interactive cleanup.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
```
search_history [OPTIONS] [PATTERN]
```

| Flag | Description |
| --- | --- |
| `-c, --cleanup` | Offer to clean up matching entries after search |
| `-h, --help` | Show help |

- Uses ripgrep if available, falls back to grep
- Can be triggered with `CTRL+H`
- With `-c`: accepts `all`, `select`, direct numbers (e.g. `1 3 5`), or `n`/`q` to skip

**Examples:**
```fish
search_history git
search_history -c 'git push'
search_history -c rpm
```

---

### 🧹 `cleanup_history`

Standalone interactive history cleanup tool.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
```
cleanup_history PATTERN
```

- Displays matching entries with numeric indexes
- Accepts space-separated numbers, `all`, or `n`/`q` to quit safely
- Uses exact, case-sensitive deletion to avoid accidental removals

**Note:** For an integrated search + cleanup workflow, use `search_history -c` instead.

---

### 🧹 `clean_session_history`

Clear the current Fish shell session history with confirmation and visual countdown.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
```
clean_session_history [OPTIONS]
```

| Flag | Description |
| --- | --- |
| `-y, --yes` | Clear immediately without prompt or delay |
| `-w, --wait SECONDS` | Set countdown duration (default: 10 seconds) |
| `-h, --help` | Show help |

- Requires confirmation in interactive mode with a progress bar countdown
- Requires `--yes` in non-interactive shells to prevent accidental clearing
- Only clears the current session — use `history clear` for all saved history

---

### 🔎 `inspect_function`

Search, display, and optionally edit Fish shell functions.

**Optional dependencies:** `bat` for paging, `fzf` for fuzzy selection

**Usage:**
```
inspect_function [FUNCTION_NAME or PATTERN]
```

- Uses fzf for selection when multiple matches are found, falls back to numbered list
- Long functions are displayed in a pager (`bat` or `less`)
- Can edit user-defined functions with `$EDITOR`

**Examples:**
```
inspect_function kver
inspect_function generate_password
```

---

**⌨️ Keybindings Summary:**

| Keybinding | Function |
| --- | --- |
| `CTRL+H` | `search_history` |
