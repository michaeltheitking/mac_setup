# Daily Mac mini app updates

On 2026-11-24, the Mini retired its 04:00 LaunchAgent and removed its installed updater copy.
Workbench is no longer an install or update target. ChatGPT remains paused.
ChatGPT is skipped before reading its bundle, contacting its feed, or requesting a quit, for both `--run` and `--check`.
To re-enable ChatGPT after review, set its `enabled` flag to `True` in `APPS` and redeploy the installed script.
The Mini uses America/Chicago. Other Macs do not receive this schedule through bootstrap or setup.

The task reads the official public release feeds. It downloads an installer only when its build exceeds the installed build.
It checks macOS compatibility, CPU architecture, bundle identity, publisher signature, and Gatekeeper acceptance before replacement.
It requests a normal quit, installs the update, and launches the app in the background.
An updated app launches even when it was closed before the check.
Current apps stay open without a restart.

## Install and check

Only use these commands if you deliberately restore the schedule. Use the signed-in desktop account without `sudo`:

```sh
/usr/bin/python3 ~/dotfiles/scripts/daily-app-updates.py --check
/usr/bin/python3 ~/dotfiles/scripts/daily-app-updates.py --install
launchctl print "gui/$(id -u)/com.michael.daily-app-updates"
```

Installation copies the script into `~/Library/Application Support/DailyAppUpdates/updater.py`.
It writes `~/Library/LaunchAgents/com.michael.daily-app-updates.plist` and loads the job.
It does not run an update immediately. Reinstall after changing the repository script.
The installed copy keeps running when the checkout changes branches.

Run an immediate update through the installed job:

```sh
launchctl kickstart "gui/$(id -u)/com.michael.daily-app-updates"
tail -n 30 ~/Library/Logs/DailyAppUpdates/update.log
```

The Mac must remain logged into the desktop account. A locked session can run the job.
launchd runs a missed calendar event after sleep ends; it does not wake or power on the Mac.
A logged-out or powered-off Mac does not perform checks.
An update can interrupt app work during the restart.
If an app refuses to quit, the task logs a failure and leaves it installed.
The task never forces termination.

## Logs and recovery

The main log is `~/Library/Logs/DailyAppUpdates/update.log`.
It rotates at 1 MB and retains three previous logs.
`launchd-error.log` in the same folder records startup errors.
Check logs after the first scheduled run. Logs contain failures; the task does not send remote notifications.

Each successful update retains the previous bundle at:

```text
/Applications/.daily-app-updates-previous/ChatGPT.app
```

The task restores the previous bundle if replacement or launch fails and the new app can quit.
Power loss or job removal between bundle moves can leave the app path absent. Restore its previous bundle manually.
Launch verification confirms a running main process. Test the intended workflow after recovery.
Do not restore app data or credentials as part of bundle recovery.

To disable the schedule:

```sh
/usr/bin/python3 ~/dotfiles/scripts/daily-app-updates.py --remove
```

Removal preserves app bundles, backups, logs, and the installed script.
For manual rollback, disable the job and quit the affected app first.
Use Finder's **Go to Folder** to open `/Applications/.daily-app-updates-previous`.
Move the current app aside if present, move its previous bundle into `/Applications`, and reopen it.
The next update check installs the current release again if you re-enable the job.

## Sources and validation

On 2026-10-30, the installed unified ChatGPT app uses bundle ID `com.openai.codex`.
Its packaged updater code names the [public OpenAI feed](https://persistent.oaistatic.com/codex-app-prod/appcast.xml).
The script pins the ChatGPT bundle identifier and publisher team identifier.
A future publisher or identity change requires review; the script does not accept it automatically.

The script uses Python 3 from the existing Xcode Command Line Tools and built-in macOS commands.
No package-manager update or dependency installation runs each day.
See [the deployment decision](decisions/0006-opt-in-mini-app-updates.md).

```sh
python3 -m unittest discover -s tests -p test_daily_app_updates.py
ruff check scripts/daily-app-updates.py tests/test_daily_app_updates.py
ruff format --check scripts/daily-app-updates.py tests/test_daily_app_updates.py
```
