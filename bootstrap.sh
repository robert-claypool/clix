#!/usr/bin/env bash

set -euo pipefail

# Directory containing this script
REPO_DIR=$(cd "$(dirname "$0")" && pwd)

# Target directory for symlinks
BIN_DIR="$HOME/bin"

# Create ~/bin if not found
if [ ! -d "$BIN_DIR" ]; then
    echo "Creating $BIN_DIR..."
    mkdir -p "$BIN_DIR"
fi

# Symlink each executable script in this repo to ~/bin
for script in "$REPO_DIR"/*; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        script_name=$(basename "$script")
        target="$BIN_DIR/$script_name"

        echo "Linking $script_name to $target..."
        ln -sfi "$script" "$target"
    else
        echo "Skipping $script (not an executable file)"
    fi
done

echo "All scripts are symlinked to $BIN_DIR."

# Check if $BIN_DIR is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -Fxq "$BIN_DIR"; then
    echo -e "\nWarning: $BIN_DIR is not in your PATH."
    echo "To add it, you can run the following command or add it to your shell profile:"
    echo 'export PATH="$PATH:$HOME/bin"'
fi
