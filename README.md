# clix

Pronounced "CLI X"
Command-line interface scripts to streamline my workflow (and maybe yours too).

## Purpose

CLI scripts with an easy way to link them into your `~/bin` directory, making
them globally available via your terminal.

## Usage

Run `bootstrap.sh` to set everything up:

```bash
./bootstrap.sh
```

This will:

- Create `~/bin` if it doesn’t exist.
- Symlink scripts in this repo to `~/bin`, ensuring they can be accessed from
  anywhere in your terminal.
- Set executable permissions on the scripts.

Note: After running `bootstrap.sh`, ensure that `~/bin` is in your `PATH`
environment variable. If not, add this to your shell profile
(e.g., `~/.bashrc`, `~/.bash_profile`, or `~/.zshrc`):

```bash
export PATH="$PATH:$HOME/bin"
```

Why? Running `bootstrap.sh` makes these scripts globally available without
needing to type their full path, as long as your `PATH` includes `~/bin`.

## Scripts

### oplyn.sh

Opens the AWS Web Console for the currently active **AWS** Leapp session.

- **Usage:** `oplyn.sh [--help]`

- **Limitation:** assumes that the active session is for an **AWS** account. It will **not** work with Azure or other hosts.

#### Example

To open the AWS Web Console for your active AWS Leapp session:

```bash
oplyn.sh
```

> Important: must have an active _AWS_ session in Leapp before running this script

### opx.sh

Interact with the 1Password CLI (`op`) to copy a password into your clipboard.

- **Usage:** `opx.sh [TAG]`

- **Parameters:**

  - `TAG` _(optional)_: A tag to filter items within the selected vault. If none provided, display items without any tags.

- **Dependencies:**

  - **[1Password CLI](https://developer.1password.com/docs/cli/get-started/) (`op`)**: Must be installed and signed in.
  - **jq**: For parsing JSON output. Install with your package manager:
    - Debian/Ubuntu: `sudo apt-get install jq`
    - macOS (Homebrew): `brew install jq`
  - **Clipboard Utility**:
    - macOS: `pbcopy` (usually installed by default)
    - Linux: `xclip` or `xsel`

- **Example:**

  ```bash
  # Retrieve and copy a password from items with a specific tag
  opx.sh "work"

  # Retrieve and copy a password from items without any tags
  opx.sh
  ```

- **Notes:**

  - **Security Warning:** Reads and copies sensitive information (passwords). Avoid running this in shared or untrusted environments.
  - **Interactive Selection:** Includes prompts to select an account, vault, and item through numbered lists.
  - **Clipboard Handling:** Password is copied to your clipboard for easy pasting, can be written into your clipboard history.

- **Auth Requirement:** Sign in to your 1Password account using `op signin` or the Leapp Desktop App (GUI) before running this script.
