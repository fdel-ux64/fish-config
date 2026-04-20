# 🐟 Personal Fish configuration

A curated Fish shell toolkit with cross-distro utilities and reusable helpers.

Primarily maintained for personal use, but many utilities are **cross-distro compatible**, working on Arch, Debian/Ubuntu, and RPM-based Linux systems.

Not intended as a fully stable public plugin suite, yet mature tools are documented and may be useful to others.

> 🐧 Works on Arch, Debian/Ubuntu, and RPM-based Linux distributions

---

## ✨ Highlights

- **Multi-distro package inspection**: unified `installed_packages` for Arch, Debian/Ubuntu, and RPM systems
- **Consistent package history** across distributions
- **Interactive Fish shell helpers**: search & cleanup history with range selection, inspect functions
- **Secure password generation** with environment-aware clipboard handling
- **Cross-platform kernel version checks**
- **Archive creation and extraction**: smart format detection, overwrite protection, and pigz/zstd acceleration
- **Fish file formatting** via `fish_indent` with single-file and directory modes
- **Fisher-compatible** functions, completions, and keybindings

---

## 📥 Installation

### 🎣 Using [Fisher](https://github.com/jorgebucaran/fisher) (Recommended)

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
installed_packages days N
installed_packages count [OPTION]
installed_packages since DATE [until DATE]
installed_packages --refresh
installed_packages --backend
```

| Option | Alias | Description |
| --- | --- | --- |
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `days N` | | Packages installed in the last N days (today included) |
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
installed_packages days 3
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
rpm_installed days N
rpm_installed count [OPTION]
rpm_installed since DATE [until DATE]
rpm_installed --refresh | --cache on|off | --cache | --help
```

| Option | Alias | Description |
| --- | --- | --- |
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `days N` | | Packages installed in the last N days (today included) |
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
 🔢 Total: 14 packages — last-week
 💾 Cache: session cache
```

The filter label is always repeated in the footer, so it remains visible without scrolling up. Cache status is shown on every listing. Output is automatically paged with `less` when it exceeds the terminal height.

**Examples:**
```
rpm_installed lw
rpm_installed days 3
rpm_installed count days 5
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

The footer repeats the filter label when the total reaches or exceeds 75 packages (`__arch_summary_threshold`).

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

The footer repeats the filter label when the total reaches or exceeds 75 packages (`__deb_summary_threshold`).

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
- Optional clipboard copy on Wayland desktops via `--clipboard` — auto-clears after timeout, survives terminal close via systemd

**Usage:**
```
generate_password [OPTIONS] [LENGTH] [COUNT]
generate_password
```
| Flag | Description |
| --- | --- |
| `--clipboard` | Copy first password to clipboard (requires Wayland + wl-clipboard) |
| `--clipboard-timeout <sec>` | Set clipboard clear timeout in seconds (default: 30, min: 1) |
| `--no-ambiguous` | Exclude visually similar characters (`0`,`O`,`l`,`1`,`\|`,`I`) |
| `-h, --help` | Show help |

**Examples:**
```
generate_password 20
generate_password 15 5
generate_password 32 2 --clipboard --clipboard-timeout 5
generate_password 16 3 --no-ambiguous
generate_password 16 1 --clipboard --no-ambiguous
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

## 📦 Archive Utilities

### 📦 `create_archive`

Create a compressed archive from a file or directory, with smart format detection and optional acceleration via `pigz` or `zstd`.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Dependencies:** `tar`; `zstd` for `.tar.zst` (default format); `pigz` optional for faster `.tar.gz`

**Usage:**
```
create_archive [OPTIONS] <source> [output]
create_archive [OPTIONS] <source> <dest-dir>/
```

| Option | Description |
| --- | --- |
| `-f/--type TYPE` | Archive format: `tar` \| `tar.gz` \| `tgz` \| `tar.zst` (default: `tar.zst`) |
| `-F/--force` | Overwrite existing archive without prompting |
| `-h/--help` | Show help |

- If `output` is omitted, the archive is named after the source
- If `output` ends with `/`, it is treated as a destination directory
- Format is inferred from the output filename when `-f` is not given; falls back to `tar.zst`
- If `-f` is given alongside an output filename that already has a recognised extension, they must agree — a mismatch is an error
- Uses `pigz` for parallel `.tar.gz` compression when available
- Uses `zstd -T0` for multi-threaded `.tar.zst` compression
- On failure, partial output is removed automatically
- If the archive already exists and `--force` is not set, prompts interactively in a terminal (default: N); errors in non-interactive mode

**Examples:**
```
create_archive project
create_archive project backup.tar.gz
create_archive -f tar.gz project
create_archive --force project
create_archive project ~/backups/
```

---

### 📦 `extract_archive`

Extract an archive into its own directory, with atomic extraction and overwrite protection.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Optional dependencies:** `pigz` (faster `.tar.gz`), `zstd` (`.tar.zst`, `.zst`), `unrar` (`.rar`)

**Supported formats:** `tar`, `tar.gz`, `tgz`, `tar.bz2`, `tar.xz`, `tar.zst`, `zip`, `gz`, `bz2`, `xz`, `zst`, `rar`

**Usage:**
```
extract_archive [OPTIONS] <archive>
```

| Option | Description |
| --- | --- |
| `-F/--force` | Overwrite existing output directory without prompting |
| `-q/--quiet` | Suppress output on success |
| `-h/--help` | Show help |

- Output directory is placed alongside the archive, named after it (extension stripped)
- Extraction is staged in a temp directory; the output directory only appears on success
- If the archive contains a single top-level directory with the same name as the archive, it is flattened to avoid double-nesting (e.g. `project.tar.gz` → `project/` not `project/project/`)
- On failure, both the temp directory and output directory are cleaned up
- If the output directory already exists and `--force` is not set, prompts interactively in a terminal (default: N); errors in non-interactive mode
- Format detection uses regex matching, not shell globs — works correctly with non-ASCII filenames regardless of locale

**Examples:**
```
extract_archive archive.tar.gz
extract_archive --force archive.tar.zst
extract_archive -q archive.zip
```

---

## 🐟 Fish Dev Utilities

### 🎨 `fishfmt`

Format `.fish` files using `fish_indent`.

**Scope:** Fish shell

**Dependencies:** `fish_indent` (bundled with Fish), `find`

**Usage:**
```
fishfmt [OPTIONS] FILE|DIR [...]
```

| Option | Description |
| --- | --- |
| `-r, --recursive` | Recurse into subdirectories when a DIR is given |
| `-h, --help` | Show this help |

- Formats a single `.fish` file, or all `.fish` files in a directory
- By default, directory mode is one level deep — use `-r` to recurse
- Rejects non-`.fish` files with a clear error rather than passing them to `fish_indent`
- Always prints a summary: files formatted and files skipped

**Examples:**
```
$ fishfmt myfunc.fish
 ✔ Formatted: myfunc.fish
 Done — 1 formatted, 0 skipped

$ fishfmt ~/.config/fish/functions
 ✔ Formatted: /home/user/.config/fish/functions/myfunc.fish
 ✔ Formatted: /home/user/.config/fish/functions/kver.fish
 Done — 2 formatted, 0 skipped

$ fishfmt -r ~/.config/fish/functions
 ✔ Formatted: /home/user/.config/fish/functions/myfunc.fish
 ✔ Formatted: /home/user/.config/fish/functions/subfolder/helper.fish
 Done — 2 formatted, 0 skipped

$ fishfmt func_a.fish func_b.fish
 ✔ Formatted: func_a.fish
 ✔ Formatted: func_b.fish
 Done — 2 formatted, 0 skipped
```

---

## 📜 History & Shell UX Helpers

### 🔍 `search_history`
Search command history with optional interactive cleanup.

**Scope:** Cross-distro (Fedora / Arch / Debian-based)

**Usage:**
```fish
search_history [OPTIONS] [PATTERN]
```

| Flag | Description |
| --- | --- |
| `-c, --cleanup` | Offer to clean up matching entries after search |
| `-h, --help` | Show help |

- Uses ripgrep if available, falls back to grep
- Can be triggered with `CTRL+H`
- With `-c`: accepts `all`, `select`, direct numbers (e.g. `1 3 5`), ranges (e.g. `2-5`), mixed (e.g. `2-5 7`), or `n`/`q` to skip
- Overlapping ranges and numbers are deduplicated (e.g. `2-5 3` removes only 4 entries)

**Examples:**
```fish
search_history git
search_history -c 'git push'
search_history -c rpm
search_history -c cd      # then: 2-5 7  to delete a range + extra entry
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
- Accepts space-separated numbers, ranges (e.g. `4-7`), or any mix of both (e.g. `1 4-7 12`)
- Duplicates are silently deduplicated — `4-7 5` deletes 4 entries, not 5
- Accepts `all` to remove every match, or `n`/`q` to quit safely
- Uses exact, case-sensitive deletion to avoid accidental removals

**Examples:**
```
cleanup_history 'git add'
cleanup_history rpm
```

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
