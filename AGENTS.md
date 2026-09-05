# AGENTS.md

Guidance for coding agents working in this dotfiles repo.

## Project Purpose

This repository backs up and restores Michael's personal macOS and Omarchy setup. It is expected to live at `~/dotfiles` and is mirrored to `github.com/michaeltheitking/mac_setup`.

The matching Confluence runbook is:

- `Cross-Platform Dotfiles Runbook`
- `https://michael-kingdocs.atlassian.net/wiki/spaces/~5570583e46f7b02769468785802b45c5e986a5/pages/61341700/Cross-Platform+Dotfiles+Runbook`

When setup behavior changes, update both this repo and that Confluence page.

## Repo Layout

- `bootstrap_new_mac.sh` - fresh-Mac bootstrap script for Xcode CLT, Homebrew, CLI tools, casks, Claude Code, Git, SSH, GitHub auth, and dotfile setup.
- `bootstrap_omarchy.sh` - Omarchy bootstrap script for personal Arch packages, Git, SSH, GitHub auth, plugins, setup, and verification.
- `setup.sh` - detects macOS or Omarchy and dispatches to the matching platform setup.
- `setup_common.sh` - conflict-safe linking helpers and shared Git, Codex, and Claude setup.
- `setup_macos.sh` - links macOS shell, Tmux, SSH, and Ghostty files; removes retired Bartender hooks.
- `setup_omarchy.sh` - links portable files and the Linux SSH config while preserving Omarchy-owned configuration.
- `.zshrc` - zsh shell config. Sources Powerlevel10k and zsh-autosuggestions only when installed.
- `.tmux.conf` - tmux terminal config. Uses `tmux-256color` and enables RGB color support for `xterm-256color`.
- `ssh/config` - SSH client config symlinked to `~/.ssh/config`; routes GitHub SSH through `ssh.github.com:443` and includes global keepalives.
- `ssh/github-known-hosts` - pinned GitHub Ed25519 host key linked into `~/.ssh` on both supported platforms.
- `ssh/config.omarchy` - Linux SSH client config without Apple Keychain options.
- `.p10k.zsh` - Powerlevel10k prompt config.
- `.gitignore_global` - global Git ignore rules, symlinked to `~/.gitignore_global` and wired up through `core.excludesfile`.
- `codex/AGENTS.md` - global agent instructions, symlinked to both `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md` so Codex and Claude Code stay in sync.
- `claude/skills/` - global Claude Code skills, each symlinked per-skill into `~/.claude/skills/`. Add a new `claude/skills/<name>/SKILL.md` and re-run `setup.sh` to link it.
- `codex/skills/` - global Codex skills, each symlinked per-skill into `~/.codex/skills/`. Linked per-skill (not the whole directory) so Codex's managed `~/.codex/skills/.system` is left untouched.
- `claude/settings.json` - Claude Code settings symlinked to `~/.claude/settings.json`.
- `claude/statusline-command.sh` - Claude Code status line command symlinked to `~/.claude/statusline-command.sh`.
- `claude/remove-bartender-hooks.sh` - removes retired Bartender hooks from local Claude settings; preserves other hooks and permissions.
- `verify.sh` - read-only health check for symlink integrity, required tools, and Claude settings hygiene. Run anytime; `bootstrap_new_mac.sh` runs it last.
- `scripts/check-github-host-key.sh` - validates the managed GitHub Ed25519 host key against its pinned fingerprint.
- `scripts/github-ssh-auth.sh` - runs the bounded GitHub SSH client-authentication health check.
- `tests/test_setup.sh` - isolated setup tests for both platforms and link-conflict handling.
- `ghostty/config.ghostty` - Ghostty terminal config.
- `docs/decisions/` - architecture decision records for choices that outlive a single change (see Decision Records).

## Decision Records

Setup choices that a future reader would otherwise have to reverse-engineer belong in `docs/decisions/` as a numbered ADR (`NNNN-slug.md`) with status, context, decision, rationale, consequences, and revisit triggers. Examples already recorded: why the Neovim config stays machine-local, why there is one SSH key per machine, and why GitHub SSH uses port 443.

Skip an ADR for routine package additions, formatting, or one-off fixes. When a recorded decision changes, update its ADR instead of adding a second one.

## Bootstrap Script Conventions

- Add GUI apps to the `BREW_CASKS` array in `bootstrap_new_mac.sh`.
- Add Homebrew CLI tools to the `BREW_FORMULAS` array.
- For non-Homebrew tools, add an explicit idempotent install step.
- Keep the script safe to re-run. Existing formulae/casks should be skipped.
- Keep Homebrew casks installed with `brew install --cask --adopt`.
- Keep Claude Code installed via `npm install -g @anthropic-ai/claude-code`; `node` must remain in `BREW_FORMULAS`.
- Keep the final output reminder to restore iStat Menus settings from the exported file in the Documents folder.
- iStat Menus settings should be restored through the app's own import UI, not by copying raw plist files unless explicitly requested.
- Keep GitHub host-key enrollment non-interactive. Verify key changes against GitHub's published fingerprints before updating `ssh/github-known-hosts`.

For Omarchy:

- Use `omarchy pkg add` for missing personal packages.
- Do not run `pacman -Sy` or a full system update from the bootstrap script.
- Keep Bash, Starship, Tmux, Ghostty, Hyprland, and desktop settings under Omarchy control.
- Use Omarchy's lazy Claude and Codex launchers instead of npm installs.

## Shell Config Conventions

- Do not hardcode `/opt/homebrew` in `.zshrc`; use `brew --prefix` so Apple Silicon and Intel Macs both work.
- Guard sourced Homebrew files with existence checks so a fresh terminal does not print missing-file errors before bootstrap finishes.
- `.zshrc.private` is intentionally ignored and should remain local-only.

## Validation

Before committing shell script changes, run:

```sh
bash -n bootstrap_new_mac.sh
zsh -n .zshrc
```

For `setup.sh` or `verify.sh` changes, also run:

```sh
bash -n bootstrap_omarchy.sh setup.sh setup_common.sh setup_macos.sh setup_omarchy.sh verify.sh
bash -n scripts/check-github-host-key.sh
bash -n scripts/github-ssh-auth.sh
bash tests/test_setup.sh
bash tests/test-github-ssh.sh
```

For SSH config changes, confirm the effective GitHub route:

```sh
ssh -G -F ssh/config github.com | grep -qx 'hostname ssh.github.com'
ssh -G -F ssh/config github.com | grep -qx 'port 443'
ssh -G -F ssh/config github.com | grep -qx 'user git'
ssh -G -F ssh/config github.com | grep -Fqx "userknownhostsfile $HOME/.ssh/github-known-hosts"
```

If Homebrew package names are uncertain, verify with:

```sh
brew search <name>
```

Networked commands such as `brew update`, installs, `npm install -g`, `git pull`, and `git push` may require approval in sandboxed environments.

## Git Workflow

- Main branch is `main`.
- Preferred commit style: concise but descriptive, for example `Add Mac bootstrap apps and shell dependencies`.
- If a push is rejected because the remote moved, use `git pull --rebase origin main`, resolve conflicts by preserving remote improvements and local requested changes, then push again.
- Use `git push --force-with-lease` only when intentionally updating an already-pushed commit, such as amending its message.

## Confluence Sync Notes

The Confluence runbook currently documents:

- Repo layout
- Backup process
- Fresh Mac restoration steps
- Manual follow-ups
- Verification commands
- Notes about Xcode CLT, GitHub auth, iStat Menus restore, and SSH key naming

When updating the bootstrap script, mirror any user-facing behavior in Confluence, especially:

- New or removed casks
- New or removed formulae
- Manual follow-ups after bootstrap
- Verification commands
- Final reminders printed by the script
