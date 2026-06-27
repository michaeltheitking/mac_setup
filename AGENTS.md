# AGENTS.md

Guidance for coding agents working in this dotfiles repo.

## Project Purpose

This repository backs up and restores Michael's personal Mac setup. It is expected to live at `~/dotfiles` and is mirrored to `github.com/michaeltheitking/mac_setup`.

The matching Confluence runbook is:

- `Mac Dotfiles Runbook`
- `https://michael-kingdocs.atlassian.net/wiki/spaces/~5570583e46f7b02769468785802b45c5e986a5/pages/61341700/Mac+Dotfiles+Runbook`

When setup behavior changes, update both this repo and that Confluence page.

## Repo Layout

- `bootstrap_new_mac.sh` - fresh-Mac bootstrap script for Xcode CLT, Homebrew, CLI tools, casks, Claude Code, Git, SSH, GitHub auth, and dotfile setup.
- `setup.sh` - symlinks `.zshrc`, `.tmux.conf`, `.p10k.zsh`, global agent instructions, Claude Code config, Claude/Codex skills, and Ghostty config into place, and generates per-machine Claude local settings.
- `.zshrc` - zsh shell config. Sources Powerlevel10k and zsh-autosuggestions only when installed.
- `.tmux.conf` - tmux terminal config. Uses `tmux-256color` and enables RGB color support for `xterm-256color`.
- `.p10k.zsh` - Powerlevel10k prompt config.
- `codex/AGENTS.md` - global agent instructions, symlinked to both `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md` so Codex and Claude Code stay in sync.
- `claude/skills/` - global Claude Code skills, each symlinked per-skill into `~/.claude/skills/`. Add a new `claude/skills/<name>/SKILL.md` and re-run `setup.sh` to link it.
- `codex/skills/` - global Codex skills, each symlinked per-skill into `~/.codex/skills/`. Linked per-skill (not the whole directory) so Codex's managed `~/.codex/skills/.system` is left untouched.
- `claude/settings.json` - Claude Code settings symlinked to `~/.claude/settings.json`.
- `claude/statusline-command.sh` - Claude Code status line command symlinked to `~/.claude/statusline-command.sh`.
- `claude/install-local-hooks.sh` - generates the per-machine `~/.claude/settings.local.json` (Bartender hooks + permissions); not symlinked or committed.
- `verify.sh` - read-only health check for symlink integrity, required tools, and Claude settings hygiene. Run anytime; `bootstrap_new_mac.sh` runs it last.
- `ghostty/config.ghostty` - Ghostty terminal config.

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
