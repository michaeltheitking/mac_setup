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

## New-device walkthrough

These steps cover a new Mac or Omarchy computer. Existing devices do not need migration.
Bootstrap installs the configured applications and tools, not only GitHub access.
Use a normal desktop terminal as your user. Do not run the entire script with `sudo`.

1. **Prepare browser access.** Make your existing GitHub passkey available in the browser or its passkey provider.
   On Omarchy, enable and unlock a Secret Service credential store in your desktop session.
   macOS uses Keychain. CLI authorization remains separate from browser sign-in.

2. **Start bootstrap.** On a fresh Mac, download and run the bootstrap before Git exists:

   ```sh
   bootstrap_file="$(mktemp -t dotfiles-bootstrap)" &&
     curl -fL https://raw.githubusercontent.com/michaeltheitking/mac_setup/main/bootstrap_new_mac.sh -o "$bootstrap_file" &&
     /bin/bash "$bootstrap_file"
   ```

   The script installs Xcode Command Line Tools, checks working Git, and clones the public repository into `~/dotfiles`.
   It then continues from that checkout. Full Xcode is not required.
   Installation can request your administrator password.
   If Apple offers no command-line update, finish the installation dialog and run the same command again.
   The script checks completion automatically. It stops if Git still fails.
   An existing directory without Git metadata stops the clone; preserve its files before retrying.

   On Omarchy, Git already exists. Clone the public repository and run its bootstrap:

   ```sh
   git clone https://github.com/michaeltheitking/mac_setup.git ~/dotfiles
   cd ~/dotfiles
   ./bootstrap_omarchy.sh
   ```

   Public download and clone need no GitHub login. If a checkout already exists, inspect it before continuing.
   From the intended checkout, run `./bootstrap_new_mac.sh` or `./bootstrap_omarchy.sh`.
   Bootstrap reuses installed packages and preserves existing repository remotes.

3. **Authorize GitHub CLI.** When `gh` displays a one-time code, follow its browser instructions.
   Sign in as `michaeltheitking` with your existing passkey, then authorize GitHub CLI.
   Bootstrap reuses valid CLI authentication and skips this prompt when possible.
   Approve native credential-storage prompts or unlock the credential store when required.

4. **Let automatic checks finish.** Bootstrap checks the API account, native credential storage, and a private HTTPS Git read.
   It configures the Git credential helper and runs the final health check.
   A failure stops bootstrap before its success message. Private reads prove read access, not repository write permission.
   If storage falls back to a plaintext file, follow [credential-store recovery](docs/github-authentication.md#credential-storage).

5. **Use GitHub and restore settings.** New HTTPS clones and normal Git commands use the saved CLI credential.
   Browser access uses your existing passkey. You need no GitHub SSH key or copied token for this setup.
   Follow [manual settings restoration](docs/manual-settings.md), including the iStat Menus import.

The confirmation commands below are optional diagnostics. Bootstrap already performs these checks:

```sh
gh api --hostname github.com user --jq .login
bash ~/dotfiles/scripts/github-auth.sh check
~/dotfiles/verify.sh
```

The account must be `michaeltheitking`. The helper must report a successful private HTTPS Git read.
See [GitHub setup and recovery](docs/github-authentication.md) for failures and scheduled-job checks.

## Configuration Ownership

Both platforms share:

- Global Git ignore rules
- Codex and Claude instructions
- Claude settings and status line
- Per-skill Codex and Claude links
- Git `core.excludesfile`
- GitHub HTTPS credentials through `gh` during bootstrap
- Optional GitHub SSH configuration and pinned trust for existing SSH users

macOS also manages:

- Zsh and Powerlevel10k
- Tmux
- Apple Keychain-aware SSH configuration
- Ghostty configuration

Omarchy also manages the Linux SSH configuration. Omarchy retains control of
Bash, Starship, Tmux, Ghostty, Hyprland, and desktop settings. This boundary
keeps Omarchy updates and theme synchronization intact.

Save selected personal Omarchy settings in [`omarchy/config/`](omarchy/config/).
Follow the [capture and restore workflow](omarchy/README.md) before adding or applying files.
Desktop configuration restoration remains manual; setup does not apply this directory.

macOS setup removes retired Bartender hooks from existing local Claude settings.
It preserves other hooks and permissions. It does not create local settings.
Bartender remains installed for menu bar management.

The reviewed iStat Menus 7 export is stored in [`istat-menus/`](istat-menus/README.md).
Import it manually through the app. License and device fields are excluded from the repository copy.

## Package Management

macOS uses Homebrew formulas and casks. Omarchy uses `omarchy pkg add`, which
handles Arch repositories and the AUR.

### macOS install inventory

The bootstrap installs these Homebrew casks:

```text
1password, nikitabobko/tap/aerospace, bartender, chatgpt, claude, codex,
cursor, fantastical, font-jetbrains-mono-nerd-font, font-meslo-lg-nerd-font,
ghostty, grandperspective, istat-menus, linear, microsoft-edge@beta, microsoft-office, notion,
nvidia-geforce-now, openlogi, protonvpn, raindropio, raycast, spotify,
tailscale-app, todoist-app, vlc, windows-app, wispr-flow, zed
```

It installs these Homebrew formulas:

```text
git, gh, node, jq, pngpaste, ruff, prettier, tmux, powerlevel10k,
zsh-autosuggestions, fastfetch, btop
```

Other install steps provide Xcode Command Line Tools, Homebrew,
`@anthropic-ai/claude-code` through npm, and Astropad Workbench through its official DMG.
Existing tools and applications are skipped. Dropbox and Zoom are not installed.
The optional `dbox()` shell helper remains available for a manually installed Dropbox.
Microsoft Office supplies OneDrive. The standalone `onedrive` cask conflicts with Office and is not installed separately.
Verification requires the Edge Beta, Windows App, and OneDrive application bundles.

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

The check validates GitHub authentication, Git ignore wiring, links, and required tools.
On macOS, `pngpaste`, `btop`, and `fastfetch` are required.
App-bundle checks confirm installation only; sign-in and settings restoration remain manual.
GitHub checks require network access. A network failure does not establish a credential failure.
HTTPS checks confirm the expected API identity, `gh` credential helper, and a private Git read.
Existing machines that select SSH retain the SSH route, trust, and client-authentication checks.
Legacy plaintext credential storage produces a warning. New bootstrap requires native credential storage.
Both bootstrap scripts stop when verification fails. The Mac bootstrap also stops if its verifier is unavailable.

Run repository checks after script changes:

```sh
bash -n bootstrap_new_mac.sh bootstrap_omarchy.sh setup.sh setup_common.sh \
  setup_macos.sh setup_omarchy.sh verify.sh tests/test_setup.sh
zsh -n .zshrc
bash tests/test_setup.sh
bash tests/test-github-ssh.sh
bash tests/test-github-auth.sh
bash tests/test-mac-bootstrap.sh
git diff --check
```

Final Omarchy validation requires an Omarchy machine. Run both the bootstrap
and setup twice. The second run must preserve configuration and installed state.

## Manual settings backup and restore

Follow [the settings guide](docs/manual-settings.md) before replacing a Mac and after bootstrap.
It covers app exports, private configuration files, account setup, permissions, and restore checks.
Keep private exports outside this repository. Bootstrap prints the guide path when it finishes.
Homebrew initialization is added to `.zprofile` even when Homebrew already exists.

## GitHub CLI setup

Both bootstraps configure HTTPS Git through the shared [authentication helper](scripts/github-auth.sh).
They reuse valid credentials or request browser authorization in an interactive terminal.
They do not generate GitHub SSH keys, start agents, register keys, or rewrite existing repository remotes.
Fresh clones retain their HTTPS remote. Existing devices do not need migration.
See [GitHub setup, checks, and recovery](docs/github-authentication.md) for storage and scheduled-job boundaries.

## Project context

Start with [the documentation index](docs/README.md).
It links current state, structure, operations, decisions, and handoff guidance.
Keep these records aligned with reviewed changes.
