# 1. Neovim config is machine-local, not tracked in dotfiles

- Status: Accepted
- Date: 2026-08-22

## Context

This repo syncs a Mac's setup two ways: `bootstrap_new_mac.sh` installs packages
from `BREW_FORMULAS`/`BREW_CASKS`, and `setup.sh` symlinks configs out of
`~/dotfiles` into place (ghostty, claude, codex, ssh, tmux, zsh). Every config
the repo manages follows that symlink pattern.

LazyVim was installed on this device. Its starter config lands in
`~/.config/nvim`, and the natural default would have been to move it into
`dotfiles/nvim/` and symlink it like everything else.

## Decision

Neovim's config stays at `~/.config/nvim` as a plain directory. It is not
tracked in this repo and not symlinked by `setup.sh`. Its supporting tools
(`neovim`, `fd`, `lazygit`, `ripgrep`, `fzf`) are likewise not added to
`BREW_FORMULAS`.

This was an explicit choice, not an oversight.

## Rationale

The LazyVim starter is designed to be owned and edited in place rather than
consumed as a pinned upstream artifact, and `lazy-lock.json` records
plugin commits that are reasonable to let drift per machine. Keeping it out of
the repo avoids committing churn from a config that changes every time a plugin
updates.

The tradeoff was considered and accepted rather than assumed: syncing it would
have been the more consistent option.

## Consequences

- A freshly bootstrapped Mac gets no Neovim and no LazyVim. Setting it up is a
  manual step, and the tool list above has to be reinstalled by hand.
- Editor config diverges across devices by design. There is no mechanism that
  will warn when it does.
- This is the first config in the repo that intentionally departs from the
  symlink pattern, so the pattern can no longer be read as universal.
- Package installs and config tracking are now independently decided. `btop`,
  added to `BREW_FORMULAS` the same day, is the inverse case: the tool syncs
  across devices while its config does not.

## Revisit triggers

- The `~/.config/nvim` config accumulates real customization worth not losing to
  a disk failure.
- Neovim gets used on a second device and the drift becomes annoying rather than
  irrelevant.
- A new Mac gets bootstrapped and the missing editor is a friction point worth
  removing.
