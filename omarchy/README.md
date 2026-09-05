# Personal Omarchy configuration

Store reviewed personal settings here. Keep one checkout of this repository on each machine.
The main [README](../README.md) describes bootstrap and shared configuration.

## Layout

| Path      | Purpose                                                          |
| --------- | ---------------------------------------------------------------- |
| `config/` | Selected files from `~/.config/`, with the same relative paths.  |
| `local/`  | Ignored working copies and backups. Never commit this directory. |

For example, save `~/.config/hypr/bindings.conf` as `config/hypr/bindings.conf`.
This example does not establish that the file exists on your machine.
Inspect the active configuration and its included files before choosing a source.

Keep personal package additions in `OMARCHY_PACKAGES` in [bootstrap_omarchy.sh](../bootstrap_omarchy.sh).
Keep shared Git, SSH, and agent settings in their existing repository directories.
Neovim remains machine-local under [ADR 0001](../docs/decisions/0001-neovim-config-is-machine-local.md).

## Save the first file

Run these commands from the Omarchy machine's checkout.
Inspect Git status and fetch before integrating changes from another device.
Preserve local changes before selecting or updating a branch.

```sh
cd ~/dotfiles
git status --short --branch
git fetch origin
```

Select one text configuration file. Read it locally and remove private content before copying it here.
Do not capture entire application directories, credentials, browser profiles, caches, or generated theme links.
Keep machine-specific display names and paths separate from portable settings when practical.

Example capture, after verifying this source file:

```sh
mkdir -p omarchy/config/hypr
cp -i "$HOME/.config/hypr/bindings.conf" omarchy/config/hypr/bindings.conf
git status --short -- omarchy
git diff --no-index -- /dev/null omarchy/config/hypr/bindings.conf
```

The last command shows a new file before staging. Exit status `1` means differences exist.
For an existing tracked file, use `git diff -- omarchy/config/hypr/bindings.conf` instead.
The `cp -i` prompt protects an existing repository copy from an accidental overwrite.

Before committing, review the complete file for private information and unwanted defaults.
Stage only the selected files. Inspect `git diff --cached` before committing and pushing.
Record the source path, capture date, Omarchy version, and validation result in this document.

## Edit and restore a saved file

Edit the repository copy, then compare it with the live file on Omarchy.
Inspect changes after Omarchy updates before restoring older settings.
Prefer the application's supported personal configuration files over replacing its defaults.

Example comparison:

```sh
diff -u "$HOME/.config/hypr/bindings.conf" omarchy/config/hypr/bindings.conf
```

Back up the live file before applying the reviewed copy:

```sh
mkdir -p omarchy/local
omarchy_backup_dir=$(mktemp -d "$PWD/omarchy/local/restore.XXXXXXXX")
cp -p "$HOME/.config/hypr/bindings.conf" "$omarchy_backup_dir/bindings.conf"
```

Check the destination before copying. If it is a symlink, inspect its target and stop this example workflow.
Do not overwrite a link to Omarchy defaults or generated theme files.
For an existing regular file, apply the reviewed copy:

```sh
if [ -f "$HOME/.config/hypr/bindings.conf" ] && [ ! -L "$HOME/.config/hypr/bindings.conf" ]; then
  cp -i omarchy/config/hypr/bindings.conf "$HOME/.config/hypr/bindings.conf"
fi
```

Use the application's supported reload procedure. Test the changed behavior in the desktop session.
File equality alone does not prove that the application loaded the setting.
If the change fails, restore the backup and reload the application:

```sh
cp -i "$omarchy_backup_dir/bindings.conf" "$HOME/.config/hypr/bindings.conf"
```

Keep the backup path until verification finishes. The shell variable lasts only for the current shell session.
For a missing destination file, inspect its parent configuration before adding and loading it.

## Automation boundary

`setup_omarchy.sh` does not apply this directory. Capturing a file does not change the running desktop.
Add automated installation only after native testing establishes the correct ownership, restore, and reload behavior.
Update [ADR 0004](../docs/decisions/0004-use-one-repository-with-platform-specific-setup.md) when that boundary changes.

## Current state

2026-09-05: The repository structure and manual capture workflow are ready.
No live Omarchy configuration is captured yet. Native capture, restore, and desktop validation remain pending.
The initial setup adds no desktop settings and makes no live configuration changes.
