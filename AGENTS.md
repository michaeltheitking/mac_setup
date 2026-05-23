# AGENTS.md

Guidance for coding agents working in this dotfiles repo.

## Project Purpose

This repository backs up and restores Michael's personal Mac setup. It is expected to live at `~/dotfiles` and is mirrored to `github.com/michaeltheitking/mac_setup`.

The matching Notion source of truth is:

- `Mac Setup: Backup & Restoration`
- `https://www.notion.so/35935e13a82f81f8a46bd26bd534c388`

When setup behavior changes, update both this repo and that Notion page.

## Repo Layout

- `bootstrap_new_mac.sh` - fresh-Mac bootstrap script for Xcode CLT, Homebrew, CLI tools, casks, Claude Code, Git, SSH, GitHub auth, and dotfile setup.
- `setup.sh` - symlinks `.zshrc`, `.p10k.zsh`, and Ghostty config into their expected locations.
- `.zshrc` - zsh shell config. Sources Powerlevel10k and zsh-autosuggestions only when installed.
- `.p10k.zsh` - Powerlevel10k prompt config.
- `codex/AGENTS.md` - global Codex instructions symlinked to `~/.codex/AGENTS.md`.
- `ghostty/config.ghostty` - Ghostty terminal config.
- `README.md` - brief repo inventory.

## Bootstrap Script Conventions

- Add GUI apps to the `BREW_CASKS` array in `bootstrap_new_mac.sh`.
- Add Homebrew CLI tools to the `BREW_FORMULAS` array.
- For non-Homebrew tools, add an explicit idempotent install step.
- Keep the script safe to re-run. Existing formulae/casks should be skipped.
- Keep Homebrew casks installed with `brew install --cask --adopt`.
- Keep Claude Code installed via `npm install -g @anthropic-ai/claude-code`; `node` must remain in `BREW_FORMULAS`.
- Keep the final output reminder to restore iStat Menus settings from the exported file in the Documents folder.
- iStat Menus settings should be restored through the app's own import UI, not by copying raw plist files unless explicitly requested.

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

For `setup.sh` changes, also run:

```sh
bash -n setup.sh
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

## Notion Sync Notes

The Notion page currently documents:

- Repo layout
- Backup process
- Fresh Mac restoration steps
- Manual follow-ups
- Verification commands
- Notes about Xcode CLT, GitHub auth, iStat Menus restore, and SSH key naming

When updating the bootstrap script, mirror any user-facing behavior in Notion, especially:

- New or removed casks
- New or removed formulae
- Manual follow-ups after bootstrap
- Verification commands
- Final reminders printed by the script
