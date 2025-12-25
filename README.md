# Fish Config Functions

A collection of custom Fish shell functions and completions, designed to be easily shared across machines.

## Current Functions

### `instlist`

List installed RPM packages by install date.

**Usage:**

```fish
instlist [OPTION]

| Option       | Description                              |
| ------------ | ---------------------------------------- |
| `today`      | Packages installed today                 |
| `yesterday`  | Packages installed yesterday             |
| `last-week`  | Packages installed in the last 7 days    |
| `this-month` | Packages installed this calendar month   |
| `last-month` | Packages installed in the previous month |
