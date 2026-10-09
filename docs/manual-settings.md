# Manual settings backup and restore

Reviewed: 2026-10-09. Sources: this repository, local file inventory, and the linked vendor documentation.
These instructions do not establish that an export or restore succeeded on another machine.

## Before replacing a Mac

1. Run `./verify.sh`. Record failures before changing anything.
2. Save exports and screenshots in a private backup outside every Git checkout.
3. Use an encrypted backup destination with an off-device copy. Confirm that you can read it.
4. Record the app version and export date. Keep account recovery information in your password manager.
5. Exclude credentials, authentication databases, browser profiles, and agent conversation directories.

Review exports before sharing them. Device identifiers, private hosts, snippets, and clipboard records can be sensitive.
Do not export browser passwords to CSV or copy session tokens between devices.

## Settings with a specific backup route

| App or configuration  | Before replacement                                                                                                                                                   | Restore and verify                                                                                                                                                                        |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| iStat Menus 7         | Export through the app. Keep the full export private. Follow [the refresh rules](../istat-menus/README.md) before updating the reviewed repo copy.                   | Export the target settings for rollback. Import through iStat Menus, activate separately, and check menu items. The sanitized repo copy's import remains unverified.                      |
| Raycast               | Run **Export Settings & Data**. Save the export privately. Retain its export passphrase separately when requested.                                                   | Run **Import Settings & Data** and select the required categories. Check hotkeys, extensions, snippets, and quicklinks. Authorize extensions separately.                                  |
| OpenLogi              | Quit the GUI and resident agent. Copy `${XDG_CONFIG_HOME:-$HOME/.config}/openlogi/config.toml` to the private backup. Record the app version.                        | Back up the target file, then copy the reviewed file into the same configuration path. Relaunch OpenLogi. Check device selection, DPI, buttons, and per-app mappings.                     |
| Microsoft Edge Beta   | Check **Settings > Profiles > Sync** for every profile. Export important favorites through the Favorites menu as a private HTML fallback.                            | Sign in to the same profiles and select sync categories. Check favorites and extensions. Import the HTML fallback only when needed to avoid duplicates. Reauthorize sites and extensions. |
| Windows App           | Use the app's PC export control when available. Save RDP files privately. Record workspace/feed URLs, gateways, and display options separately.                      | Import saved PCs through the app. Re-add feeds and gateways where necessary. Reenter credentials through the app or password manager. Test one intended connection.                       |
| OneDrive              | Record accounts, sync-folder locations, **Account > Choose Folders** selections, and offline-folder choices. Check sync errors and unsynced files.                   | Office installs OneDrive. Sign in, select the intended folder location, and reapply per-account folder choices. Confirm sync status and open a representative file.                       |
| AeroSpace             | If customized, back up `~/.aerospace.toml` or `${XDG_CONFIG_HOME:-$HOME/.config}/aerospace/aerospace.toml`. Keep display-specific settings private.                  | Back up any target file before restoring. Reload through AeroSpace and test shortcuts, window placement, and displays. This Mac had neither custom file during review.                    |
| Cursor and Zed        | Open user settings and keybindings from the editor. Back up customized text files when present. Record extensions and themes. Review files for embedded credentials. | Restore compatible settings and keybindings. Reinstall extensions and authorize accounts. Check shortcuts and one project. Do not copy entire editor profiles or caches.                  |
| btop                  | If customized, back up `${XDG_CONFIG_HOME:-$HOME/.config}/btop/btop.conf` after closing btop.                                                                        | Preserve the target file before replacing it. Run btop and check layout, colors, and controls. Default settings need no private backup.                                                   |
| Local shell overrides | Back up `.zshrc.private` when present. Save custom `.zprofile` additions separately from Homebrew initialization.                                                    | Restore reviewed overrides manually. Bootstrap restores Homebrew initialization. Open a fresh terminal and test the relevant command.                                                     |

OpenLogi stores physical device keys in its configuration. Inspect them before transferring settings to different hardware.
Its current schema can differ from an older export. Fix reported compatibility errors before testing device behavior.
Do not back up its lock file as configuration.

Raycast exports can include clipboard history, snippets, notes, and account-related extension settings.
Keep them private. Import only needed categories; do not use **Import AI chats as copies** for a settings-only restore.
That operation can replace cloud-synced chat data across devices.

OneDrive folder selections are specific to each computer and account.
Cloud-only files are not offline backups. Download needed files before including them in an offline backup.
Bootstrap does not choose folders, enable folder backup, or move user files.

Windows App also provides documented bookmark export commands.
Use the installed version's help before exporting through its CLI:

```sh
'/Applications/Windows App.app/Contents/MacOS/Windows App' --script bookmark export help
```

The command above displays help only. Do not publish exported connection details.
Saved PC exports do not replace workspace sign-in or stored credentials.

## Preferences that require manual recreation or account setup

No app-specific export route was verified for the preferences below.
Save private screenshots or short notes, then recreate the settings through the installed app.
Use an app's supported export if your version provides one. Back up target settings before importing.

| App or area                                           | Record and restore                                                                                                                                 | Observable check                                                                                       |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Bartender                                             | Menu-item order, hidden items, triggers, hotkeys, and app permissions. Recreate through Bartender; do not transplant raw preference plists.        | Check visible and hidden items and one configured trigger.                                             |
| Fantastical and Microsoft Office                      | Calendar/mail accounts, display choices, default apps, and custom shortcuts. Back up local templates, macros, and signatures separately when used. | Check the intended account and one calendar, document template, or signature.                          |
| Astropad Workbench                                    | Pairing choices, display/input preferences, and required permissions. Pair and authorize the new Mac manually.                                     | Connect to the intended computer and check input.                                                      |
| ProtonVPN and Tailscale                               | Custom connection choices and split-routing preferences when used. Sign in and enroll the new device through the app.                              | Check the intended connection and reachable resource. Retire old devices separately.                   |
| Wispr Flow                                            | Custom dictionary, shortcuts, language, app rules, microphone selection, and permissions.                                                          | Test dictation in one intended app.                                                                    |
| VLC, GeForce NOW, GrandPerspective                    | Customized playback, streaming, shortcuts, scan exclusions, and display preferences.                                                               | Test playback, one game session, or one selected scan.                                                 |
| 1Password, Notion, Todoist, Linear, Raindrop, Spotify | Use their normal account sign-in and recovery. Record local shortcuts and account choices privately.                                               | Confirm the expected account and one known item.                                                       |
| Claude, Codex, ChatGPT                                | Repo-managed instructions and Claude settings restore through setup. Reauthorize plugins and connectors. Keep volatile agent homes local.          | Check instruction links and one intended connector. Configuration files do not prove connector access. |
| macOS                                                 | Login items, default browser, keyboard shortcuts, displays, and app permissions. Reapply through System Settings.                                  | Check permissions and the affected app workflow.                                                       |

The repo already restores Ghostty, Zsh, Powerlevel10k, Tmux, SSH, and shared agent files through managed links.
Use [Omarchy's separate capture workflow](../omarchy/README.md) for personal Linux desktop settings.
Neovim remains machine-local under [ADR 0001](decisions/0001-neovim-config-is-machine-local.md).
Dropbox remains optional. Its shell helper does not install or configure Dropbox.

## After bootstrap

Run `./verify.sh`, then complete the manual restore checks above.
Keep the old machine and private backups until the required workflows work on the replacement.
File equality, application presence, and successful sign-in each prove different parts of restoration.
Record actual imports and workflow results before describing a restore as verified.

## Vendor references

- [Raycast import and export](https://manual.raycast.com/import-export)
- [OpenLogi configuration and recovery](https://github.com/AprilNEA/OpenLogi/blob/master/docs/CONFIGURATION.md)
- [Edge sync settings](https://support.microsoft.com/en-us/edge/change-and-customize-sync-settings-in-microsoft-edge)
- [Windows App macOS CLI](https://learn.microsoft.com/en-us/windows-app/cli-macos)
- [OneDrive folder selection](https://support.microsoft.com/en-us/onedrive/choose-which-onedrive-folders-you-want-to-sync-on-windows-or-macos)
- [Office cask, including OneDrive](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/m/microsoft-office.rb)
- [Standalone OneDrive cask conflicts](https://formulae.brew.sh/cask/onedrive)
