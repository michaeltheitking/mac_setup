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

### New Mac

1. **Open Terminal.** Paste this block and press Return. Run it as your normal user.

   ```sh
   bootstrap_file="$(mktemp -t dotfiles-bootstrap)" &&
     curl -fL https://raw.githubusercontent.com/michaeltheitking/mac_setup/main/bootstrap_new_mac.sh -o "$bootstrap_file" &&
     /bin/bash "$bootstrap_file"
   ```

2. **Follow the prompts.** If macOS opens the Command Line Tools installer, finish it and run the same block again.
   When GitHub CLI shows a code, authorize it in your browser with the `michaeltheitking` passkey.

3. **Restore your settings.** Wait for `Your Mac is bootstrapped.` Then follow the [settings guide](docs/manual-settings.md).

If an app fails to install, review the error and run the same block again.
For sign-in problems, see [GitHub setup and recovery](docs/github-authentication.md).

Bootstrap enables Dark Mode after verification. If macOS prompts for permission,
allow Terminal to control System Events. If the change fails, choose **System Settings → Appearance → Dark**.

Bootstrap also saves Column View as the Finder default. Finder reads it when it next starts.
Folders with a saved view can still open in that view.

On Apple silicon, bootstrap installs and selects **Michael's Mac** from the ZIP in **iCloud Drive → Mac Setup**.
If iCloud Drive is not ready, run `bash ~/dotfiles/scripts/install-michaels-mac-saver.sh` after it syncs.
If macOS asks for Automation permission, allow Terminal to control System Events.

### New Omarchy computer

Unlock your desktop's Secret Service credential store. Then run these commands in a normal terminal session.

```sh
git clone https://github.com/michaeltheitking/mac_setup.git ~/dotfiles
cd ~/dotfiles
./bootstrap_omarchy.sh
```

If the intended checkout already exists, run `./bootstrap_omarchy.sh` from it.
When GitHub CLI shows a code, authorize it in your browser with the `michaeltheitking` passkey.

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
nvidia-geforce-now, openlogi, protonvpn, raindropio, raycast, saffsanity/sill/sill, spotify,
tailscale-app, todoist-app, vlc, windows-app, wispr-flow, zed
```

It installs these Homebrew formulas:

```text
awscli, git, gh, node, jq, pngpaste, ruff, prettier, tmux, powerlevel10k,
zsh-autosuggestions, fastfetch, btop
```

Other install steps provide Xcode Command Line Tools, Homebrew,
`@anthropic-ai/claude-code` through npm, and [Screens 5](https://apps.apple.com/us/app/id1663047912) through the Mac App Store.
If Screens 5 is missing, bootstrap installs the Homebrew formula `mas` as needed and runs `mas get 1663047912`.
Sign in to the App Store if prompted. Restore an existing Screens purchase inside the app if needed.
Existing tools and applications are skipped. Dropbox and Zoom are not installed.
The optional `dbox()` shell helper remains available for a manually installed Dropbox.
Microsoft Office supplies OneDrive. The standalone `onedrive` cask conflicts with Office and is not installed separately.
Full verification checks the AWS and Codex commands and the Edge Beta, Windows App, OneDrive, Linear, and Screens 5 bundles.
If Homebrew lists an installed cask whose app is missing, reinstall that cask (for example, `brew reinstall --cask linear`).
Microsoft Office supplies the OneDrive bundle. Run `./verify.sh` after the repair.

[Sill for Mac](https://getsill.app/download.html) streams Mac windows to an iPhone or iPad.
Its official `saffsanity/sill/sill` cask installs the vendor's DMG with SHA-256 verification
and supports Intel and Apple silicon on macOS 14 or later. The existing cask loop skips installed
casks and uses `--adopt` for matching app bundles installed outside Homebrew.
Permissions and device pairing remain [manual follow-ups](docs/manual-settings.md).

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
zsh -f tests/test-shell-helpers.zsh
git diff --check
```

Final Omarchy validation requires an Omarchy machine. Run both the bootstrap
and setup twice. The second run must preserve configuration and installed state.

## Manual settings backup and restore

The [Mini updater](docs/daily-app-updates.md) is inactive. ChatGPT checks are paused.

Follow [the settings guide](docs/manual-settings.md) before replacing a Mac and after bootstrap.
It covers app exports, private configuration files, account setup, permissions, and restore checks.
Keep private exports outside this repository. Bootstrap prints the guide path when it finishes.
Homebrew initialization is added to `.zprofile` even when Homebrew already exists.

Run `awssync` from the root of the personal website checkout after configuring AWS access.
It syncs the site to S3 with deletions and then invalidates CloudFront.
For `clip`, enroll the new Mac's public SSH key on the Mini and confirm that `ssh devbox` connects.
The helper copies the remote path to the clipboard after a successful image transfer.

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
