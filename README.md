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
- Ghostty configuration

Omarchy also manages the Linux SSH configuration. Omarchy retains control of
Bash, Starship, Tmux, Ghostty, Hyprland, and desktop settings. This boundary
keeps Omarchy updates and theme synchronization intact.

macOS setup removes retired Bartender hooks from existing local Claude settings.
It preserves other hooks and permissions. It does not create local settings.
Bartender remains installed for menu bar management.

## Package Management

macOS uses Homebrew formulas and casks. Omarchy uses `omarchy pkg add`, which
handles Arch repositories and the AUR.

### macOS install inventory

The bootstrap installs these Homebrew casks:

```text
1password, nikitabobko/tap/aerospace, bartender, chatgpt, claude, codex,
cursor, fantastical, font-jetbrains-mono-nerd-font, font-meslo-lg-nerd-font,
ghostty, grandperspective, istat-menus, linear, microsoft-office, notion,
nvidia-geforce-now, openlogi, protonvpn, raindropio, raycast, spotify,
tailscale-app, todoist-app, vlc, wispr-flow, zed
```

It installs these Homebrew formulas:

```text
git, gh, node, jq, pngpaste, ruff, prettier, tmux, powerlevel10k,
zsh-autosuggestions, fastfetch, btop
```

Other install steps provide Xcode Command Line Tools, Homebrew,
`@anthropic-ai/claude-code` through npm, and Astropad Workbench through its official DMG.
Existing tools and applications are skipped. Dropbox and Zoom are not installed.

Both bootstrap scripts install these Claude plugins:

```text
claude-md-management@claude-plugins-official
compound-engineering@compound-engineering-plugin
context7@claude-plugins-official
skill-creator@claude-plugins-official
superpowers@claude-plugins-official
atlassian@claude-plugins-official
linear@claude-plugins-official
```

The additional marketplace is `EveryInc/compound-engineering-plugin`.
Plugin account authentication remains manual. macOS plugin installation is best-effort.

### Omarchy install inventory

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
