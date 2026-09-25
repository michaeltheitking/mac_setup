# iStat Menus settings

[settings.ismp7](settings.ismp7) contains the saved iStat Menus 7 preferences.
The source is `~/Documents/iStat Menus Settings.ismp7`, modified on 2026-05-23.
The repository copy was reviewed on 2026-09-25.

The copy excludes all `License.*` and `Device.*` fields.
All other preferences match the source export, including its version and build metadata.
Keep licensing information and the original export outside Git.

## Restore

1. Install and open iStat Menus 7.
2. Use the app's import UI to select `istat-menus/settings.ismp7` from this checkout.
3. Activate the app separately if required.
4. Check the menu bar items and preferences on the target Mac.

Setup does not import this file automatically or link it into Library preferences.
The sanitized file passes plist validation. An import of this copy remains unverified.
Before importing, export the target Mac's settings to a private location for rollback.

## Refresh

Export new settings through iStat Menus to a private location outside the repository.
Remove every `License.*` and `Device.*` preference before saving the repository copy.
Review the remaining values for credentials, identifiers, private addresses, and locations.
Validate the file with `plutil -lint istat-menus/settings.ismp7`, then review the Git diff.
Update the source date and verification record when replacing this snapshot.
