# Cross-Platform Dotfiles

This repository manages Michael's shared macOS and Omarchy configuration. It
uses explicit, conflict-safe symbolic links. GNU Stow is not required.

The default repository location is `~/dotfiles`. Set `DOTFILES_DIR` only when
you intentionally use another location.

## Entry Points

| System      | Full bootstrap           | Configuration only   |
| ----------- | ------------------------ | -------------------- |
| macOS       | `./bootstrap_new_mac.sh` | `./setup_macos.sh`   |
| Omarchy     | `./bootstrap_omarchy.sh` | `./setup_omarchy.sh` |
| Auto-detect | Not applicable           | `./setup.sh`         |

`setup.sh` detects macOS through `uname`. It identifies Omarchy through the
`omarchy` command. It stops on other Linux distributions.

## Configuration Ownership

Both platforms share:

- Global Git ignore rules
- Codex and Claude instructions
- Claude settings and status line
- Per-skill Codex and Claude links
- Git `core.excludesfile`
- One per-machine SSH key and pinned GitHub host trust

macOS also manages:

- Zsh and Powerlevel10k
- Tmux
- Apple Keychain-aware SSH configuration
- Bartender Claude hooks
- Ghostty configuration

Omarchy also manages the Linux SSH configuration. Omarchy retains control of
Bash, Starship, Tmux, Ghostty, Hyprland, and desktop settings. This boundary
keeps Omarchy updates and theme synchronization intact.

## Package Management

macOS uses Homebrew formulas and casks. Omarchy uses `omarchy pkg add`, which
handles Arch repositories and the AUR.

The Omarchy bootstrap adds only these personal packages:

- `github-cli`
- `ruff`
- `prettier`

Omarchy already supplies Git, jq, Tmux, Fastfetch, `wl-clipboard`, and lazy
Claude and Codex launchers.

## Link Safety

Setup replaces an existing symbolic link when it points to another target. It
does not replace a regular file or directory. Move or merge a conflicting path,
then run setup again.

## Verification

Run the platform-aware health check:

```sh
./verify.sh
```

Run repository checks after script changes:

```sh
bash -n bootstrap_new_mac.sh bootstrap_omarchy.sh setup.sh setup_common.sh \
  setup_macos.sh setup_omarchy.sh verify.sh tests/test_setup.sh
zsh -n .zshrc
bash tests/test_setup.sh
git diff --check
```

Final Omarchy validation requires an Omarchy machine. Run both the bootstrap
and setup twice. The second run must preserve configuration and installed state.
