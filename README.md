# mac_setup
bootstrap new mac devices with basic configs

## Files

- `.zshrc` - zsh shell configuration
- `.gitignore_global` - global Git ignore rules configured by `setup.sh`
- `.p10k.zsh` - Powerlevel10k prompt configuration
- `codex/AGENTS.md` - global agent instructions symlinked to `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md`
- `claude/settings.json` - Claude Code settings symlinked to `~/.claude/settings.json`
- `claude/statusline-command.sh` - Claude Code status line command symlinked to `~/.claude/statusline-command.sh`
- `claude/install-local-hooks.sh` - generates per-machine `~/.claude/settings.local.json` (not symlinked)
- `setup.sh` - symlinks dotfiles into place
- `verify.sh` - read-only health check (symlinks, required tools, settings hygiene)
- `bootstrap_new_mac.sh` - installs tools and configures a new Mac
- `ghostty/config.ghostty` - Ghostty terminal configuration
