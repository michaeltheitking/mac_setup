# 4. Use One Repository with Platform-Specific Setup

- Status: Accepted
- Date: 2026-08-22

## Context

The repository originally restored one macOS environment. Michael also wants
to use its portable configuration on Omarchy Linux.

The systems use different package managers and desktop configuration. macOS
uses Homebrew, Zsh, Powerlevel10k, Apple Keychain, and Bartender. Omarchy uses
Arch packages, Bash, Starship, Wayland, and Omarchy-managed desktop files.

Blindly linking the Mac files on Omarchy can break SSH parsing, shell startup,
Tmux behavior, terminal theme synchronization, and desktop updates.

## Decision

Keep one repository with separate macOS and Omarchy bootstrap and setup entry
points. Put portable link behavior in `setup_common.sh`.

The macOS setup owns the existing shell, Tmux, Ghostty, Keychain-aware SSH, and
Bartender files. The Omarchy setup owns only portable files and a Linux SSH
configuration.

Omarchy keeps ownership of Bash, Starship, Tmux, Ghostty, Hyprland, and desktop
configuration. Its bootstrap uses `omarchy pkg add` only for missing personal
packages.

As of 2026-09-05, `omarchy/config/` stores selected, reviewed personal configuration copies.
Paths mirror `~/.config/`. Capture and restore remain explicit, manual operations.
Bootstrap and setup do not apply these files or link entire desktop configuration directories.
Keep backups in ignored `omarchy/local/`; keep private data outside tracked files.
See the [capture and restore workflow](../../omarchy/README.md).

The setup scripts refuse to replace existing regular files or directories.

## Rationale

One repository keeps shared agent and Git configuration synchronized. Separate
entry points make package and desktop ownership explicit.

The small number of links does not justify a GNU Stow dependency. A shared
link helper provides conflict protection and keeps platform logic visible.

## Consequences

- macOS and Omarchy use different package installation commands.
- Shared files have one source of truth.
- Omarchy receives fewer managed files than macOS.
- New platform-specific files must go into the correct setup script.
- Verification must select checks for the active platform.
- Final Omarchy validation requires a real Omarchy system.
- Saved desktop files require review against current live settings before restoration.

## Revisit Triggers

- The repository gains many optional configuration packages.
- Omarchy changes ownership of its shell or terminal configuration.
- Another Linux distribution becomes a supported target.
- Platform-specific content no longer shares meaningful configuration.
