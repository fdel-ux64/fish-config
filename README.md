# Fish Various Config Functions

A collection of custom Fish shell functions and completions, designed to be easily shared across machines.

## Current Functions

### `install_package`

A Fish shell helper function that installs a package with the correct package manager — automatically detecting your Linux distro (Fedora, Manjaro/Arch, or Ubuntu/Debian).
If automatic detection fails, it falls back to an interactive menu prompt.

**Installation:**

To use the `install_package` function, follow these steps:
1. Copy the function code into your `fish` configuration file (`~/.config/fish/functions/install_package.fish`).
2. Reload your shell or restart the terminal to make the function available.

**Usage:**

- Call it from your terminal
- install_package [package_name]

**Behavior:**

- If your distro can be auto‑identified, it installs immediately. 
- Otherwise, it will ask.
  - Please choose your distro:
   - 1 Fedora
   - 2 Manjaro
   - 3 Ubuntu
  - Enter the number corresponding to your distro: █

---

### `advanced_install_package`

The `advanced_install_package` function is a versatile command-line tool designed to simplify package installation across different Linux distributions. It automatically detects your system's distribution (Fedora, Manjaro/Arch, Ubuntu/Debian) and installs the specified package using the appropriate package manager.

- **Automatic Distro Detection**: The function first attempts to auto-detect your Linux distribution by checking the `/etc/os-release` file. It supports Fedora, Manjaro (or any Arch-based distro), and Ubuntu/Debian.
- **Package Installation**: Once the distro is detected, the function runs the relevant package manager:
  - `dnf` for Fedora
  - `pacman` for Manjaro/Arch
  - `apt` for Ubuntu/Debian
- **Fallback to Manual Selection**: If the distro cannot be automatically detected, it prompts the user to select their distribution from a simple menu (Fedora, Manjaro, or Ubuntu).
- **Package Name Input**: You can pass the package name directly as an argument when calling the function, or you will be prompted to enter the package name interactively.
- **Error Handling**: The function checks the success or failure of each installation command and provides feedback to the user (success or failure messages).
  
**Installation:**

To use the `advanced_install_package` function, follow these steps:

1. Copy the function code into your `fish` configuration file (`~/.config/fish/functions/advanced_install_package.fish`).
2. Reload your shell or restart the terminal to make the function available.

**Usage:**

- With Package Name Argument
- You can pass one or more package names as arguments to install multiple packages at once. Simply separate the package names with spaces:

  advanced_install_package [package_name]

**Example:**
- advanced_install_package vim htop curl
- advanced_install_package vim
- advanced_install_package

**Behavior:**
- If you don't provide a package name, the script will prompt you for the name of the package to install

---

### `showfunc`

Search, display, and optionally edit Fish shell functions. This function is useful for quickly viewing or modifying your custom shell functions.

**Usage:**

showfunc [OPTION] 


| Option          | Description                                      |
| --------------- | ------------------------------------------------ |
| `FUNCTION_NAME` | The exact name of the function to show.          |
| `PATTERN`       | A pattern to search for matching function names. |


**Behavior:**

- If you provide a function name (e.g., `showfunc showfunc`), it will display the contents of that function.
- If you provide a pattern (e.g., `showfunc inst`), it will search for and show all matching functions.
- If multiple functions are found, you will be prompted to select one using fuzzy search (if `fzf` is installed), or through a numbered list.
- If the function is user-defined (not loaded by a plugin or autoload), you can choose to edit it using your `$EDITOR`.


**Key Binding:**
- You can trigger `showfunc` using **CTRL+F** in your terminal.

---

### `instlist`

List installed RPM packages by install date.

**Usage:**

instlist [OPTION]

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


**Examples:**

- instlist td
- instlist this-month
- instlist --help


**Behavior:**

- If no option is provided, lists all installed packages.
- If no packages are found for a selected time range, it will prompt to show the full list.

---

### `search_history` or `shisto`

Search a pattern through history and displays results.

**Usage:**

search_history [OPTION] or shisto [OPTION]

**Behavior:**
- if no option is provided, will display history
- if you provide a pattern or command, will search in history and show all matching values from history 

**Key Binding:**
- You can trigger `shisto` using **CTRL+H** in your terminal.
 
---

### `kver`
Display the current kernel version, Prompt to visit kernel.org

**Installation:**

To use the `kver` function, follow these steps:
1. Copy the function code into your `fish` configuration file (`~/.config/fish/functions/kver.fish`).
2. Reload your shell or restart the terminal to make the function available.

**Usage:**

kver

---

### `generate_password`
Generate a secured password using pwgen, prompt for password length and number of passwords to generate if not provided.
If pwgen is not installed, will print an error message and exit.

**Installation:**

To use the `generate_password` function, follow these steps:
1. Copy the function code into your `fish` configuration file (`~/.config/fish/functions/generate_password.fish`).
2. Reload your shell or restart the terminal to make the function available.

**Usage:**

- generate_password [password_length number_of_passwords]
- generate_password

**Example:**
- generate_password 15 5
- generate_password






