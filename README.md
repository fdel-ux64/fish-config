# Fish Various Config Functions

A collection of custom Fish shell functions and completions, designed to be easily shared across machines.

## Current Functions

### `install_package`

A Fish shell helper function that installs a package with the correct package manager — automatically detecting your Linux distro (Fedora, Manjaro/Arch, or Ubuntu/Debian).
If automatic detection fails, it falls back to an interactive menu prompt.

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

**Usage:**

kver

---

### `generate_password`
Generate a secured password using pwgen, prompt for password length and number of passwords to generate

**Usage:**

generate_password





