# 🐟 fish-rpm-installed

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Fish Shell](https://img.shields.io/badge/fish-v3.0+-blue.svg)](https://fishshell.com)

A powerful Fish shell function to **list and analyze RPM packages** by installation date, with intelligent caching for blazing-fast repeated queries.

> 🚀 **Ever wondered what packages you installed last week?** Or need to audit recent system changes? This tool makes it effortless.

---

## ✨ Why Use This?

- **⚡ Lightning Fast** - Cached queries return results instantly
- **📅 Date-Aware** - Filter packages by any date range or use convenient shortcuts
- **📊 Analytics** - Built-in aggregation to see installation patterns (per-day/per-week)
- **🎯 Simple** - Zero dependencies, pure Fish shell
- **🔍 Smart** - Auto-detects RPM systems and uses consistent locale parsing

Perfect for system administrators, power users, and anyone managing RPM-based distributions like **Fedora**, **RHEL**, **CentOS**, **Rocky Linux**, **AlmaLinux**, and **openSUSE**.

---

## 📦 Installation

### Using [Fisher](https://github.com/jorgebucaran/fisher) (Recommended)

```fish
fisher install fdel-ux64/fish-rpm-installed
```

### Manual Installation

```fish
# Clone the repository
git clone https://github.com/fdel-ux64/fish-rpm-installed.git

# Copy to your Fish functions directory
cp fish-rpm-installed/functions/rpm_installed.fish ~/.config/fish/functions/
cp fish-rpm-installed/completions/rpm_installed.fish ~/.config/fish/completions/
```

---

## 🎯 Quick Start

```fish
# What did I install today?
rpm_installed today

# Show packages from last week
rpm_installed last-week

# Count installations this month
rpm_installed count this-month

# Custom date range
rpm_installed since 2025-01-01 until 2025-01-10

# See installation patterns
rpm_installed per-day
```

---

## 📖 Usage

### Basic Syntax

```fish
rpm_installed [OPTION]
rpm_installed count [OPTION]
rpm_installed since DATE [until DATE]
rpm_installed --refresh
rpm_installed --help
```

### Time-Based Shortcuts

| Shortcut | Alias | Description |
|----------|-------|-------------|
| `today` | `td` | Packages installed today |
| `yesterday` | `yd` | Packages installed yesterday |
| `last-week` | `lw` | Last 7 days |
| `this-month` | `tm` | Current calendar month |
| `last-month` | `lm` | Previous calendar month |

### Analytics Options

| Option | Description |
|--------|-------------|
| `per-day` | Count packages grouped by day |
| `per-week` | Count packages grouped by week |

### Special Flags

| Flag | Description |
|------|-------------|
| `--refresh` | Rebuild the cache from scratch |
| `--help` | Show usage information |

---

## 💡 Examples

### Simple Queries

```fish
# Using shortcuts
rpm_installed td                    # Today's installations
rpm_installed yd                    # Yesterday's installations
rpm_installed lw                    # Last week

# With counts
rpm_installed count today           # How many packages today?
rpm_installed count last-month      # Monthly installation count
```

### Date Range Queries

```fish
# Specific date range
rpm_installed since 2025-12-01 until 2025-12-15

# Open-ended (everything since a date)
rpm_installed since 2025-01-01

# Just a specific day
rpm_installed since 2025-12-25 until 2025-12-25
```

### Analytics

```fish
# Daily installation pattern
rpm_installed per-day

# Weekly trends
rpm_installed per-week
```

### Cache Management

```fish
# Refresh the cache after system updates
rpm_installed --refresh
```

---

## 🏗️ How It Works

1. **First Run**: Queries all installed RPM packages with installation dates using `rpm -qa --last`
2. **Caching**: Stores results in `~/.cache/rpm_installed.cache` for instant subsequent queries
3. **Locale Handling**: Forces US English locale (`LC_TIME=en_US.UTF-8`) for consistent date parsing across systems
4. **Smart Filtering**: Parses cache efficiently for lightning-fast date-based queries

---

## 🔧 Requirements

- **Fish Shell** v3.0 or later
- **RPM-based system** (Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux, openSUSE, etc.)
- Standard UNIX tools: `rpm`, `grep`, `sort`, `date`

---

## 📁 Project Structure

```
fish-rpm-installed/
├── completions/
│   └── rpm_installed.fish    # Tab completion support
├── functions/
│   └── rpm_installed.fish    # Main function
├── LICENSE                    # MIT License
└── README.md                 # This file
```

---

## 🔗 Related Projects

- [bash-rpm-installed](https://github.com/fdel-ux64/bash-rpm-installed) - Bash shell version of this tool

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Created for the Fish shell community and RPM-based distribution users who want better visibility into their system's package history.

---

## ⭐ Show Your Support

If you find this useful, please consider:
- ⭐ Starring this repository
- 🐛 Reporting issues you encounter
- 📢 Sharing it with others who might benefit

---

**Made with 🐟 and ❤️ for the Fish shell community**
