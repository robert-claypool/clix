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
