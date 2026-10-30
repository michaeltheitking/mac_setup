#!/usr/bin/python3
"""Daily, opt-in macOS updates for the Mini's ChatGPT and Astropad Workbench."""

import argparse
import fcntl
import logging
import os
import platform
import plistlib
import re
import shutil
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET
from logging.handlers import RotatingFileHandler
from pathlib import Path
from urllib.parse import urlparse

LABEL = "com.michael.daily-app-updates"
logger = logging.getLogger(__name__)
STATE = Path.home() / "Library/Application Support/DailyAppUpdates"
AGENT = Path.home() / "Library/LaunchAgents" / f"{LABEL}.plist"
LOG = Path.home() / "Library/Logs/DailyAppUpdates/update.log"
SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
APPS = (
    {
        "path": Path("/Applications/ChatGPT.app"),
        # The current unified ChatGPT app retains the Codex bundle identifier.
        "id": "com.openai.codex",
        "team": "2DC432GLL2",
        "feed": "https://persistent.oaistatic.com/codex-app-prod/appcast.xml",
        "host": "persistent.oaistatic.com",
    },
    {
        "path": Path("/Applications/Astropad Workbench.app"),
        "id": "com.astropad.workbench",
        "team": "8356ZZ8Y5K",
        "feed": "https://downloads.astropad.com/workbench/mac/sparkle.xml",
        "host": "downloads.astropad.com",
    },
)


def command(*args, timeout=120):
    try:
        result = subprocess.run(args, check=True, capture_output=True, timeout=timeout)
    except subprocess.CalledProcessError as error:
        raise RuntimeError(
            error.stderr.decode(errors="replace").strip() or str(error)
        ) from error
    return result.stdout


def info(path):
    return plistlib.loads((path / "Contents/Info.plist").read_bytes())


def version(value):
    if not re.fullmatch(r"\d+(?:\.\d+)*", value):
        raise ValueError(f"Unsupported version: {value!r}")
    return tuple(int(part) for part in value.split("."))


def fetch(url, destination=None):
    args = [
        "/usr/bin/curl",
        "--fail",
        "--location",
        "--silent",
        "--show-error",
        "--proto",
        "=https",
        "--proto-redir",
        "=https",
        "--connect-timeout",
        "30",
        "--max-time",
        "1800" if destination else "60",
    ]
    if destination:
        args.extend(["--output", str(destination)])
    return command(*args, url, timeout=1810 if destination else 70)


def select_release(data, app, system, arch):
    releases = []
    for item in ET.fromstring(data).findall("./channel/item"):
        enclosure = item.find("enclosure")
        if enclosure is None or item.findtext(SPARKLE + "channel"):
            continue
        minimum = item.findtext(SPARKLE + "minimumSystemVersion", "0")
        hardware = item.findtext(SPARKLE + "hardwareRequirements", "")
        if version(minimum) > version(system) or (
            hardware and arch not in hardware.split(",")
        ):
            continue
        build = item.findtext(SPARKLE + "version") or enclosure.get(
            SPARKLE + "version", ""
        )
        url = enclosure.get("url", "")
        parsed = urlparse(url)
        if parsed.scheme != "https" or parsed.hostname != app["host"]:
            raise ValueError("Feed contains an untrusted download URL")
        if Path(parsed.path).suffix not in (".dmg", ".zip"):
            raise ValueError("Feed does not contain a supported full installer")
        releases.append({"build": build, "url": url})
    if not releases:
        raise ValueError("No compatible public release found")
    return max(releases, key=lambda release: version(release["build"]))


def verify_bundle(path, app, build):
    metadata = info(path)
    if (
        metadata["CFBundleIdentifier"] != app["id"]
        or metadata["CFBundleVersion"] != build
    ):
        raise ValueError("Downloaded bundle identity or build does not match")
    requirement = (
        f'=anchor apple generic and identifier "{app["id"]}" '
        f'and certificate leaf[subject.OU] = "{app["team"]}"'
    )
    command(
        "/usr/bin/codesign",
        "--verify",
        "--deep",
        "--strict",
        "-R",
        requirement,
        str(path),
    )
    command("/usr/sbin/spctl", "--assess", "--type", "execute", str(path))
    command(
        "/usr/bin/lipo",
        "-verify_arch",
        platform.machine(),
        str(path / "Contents/MacOS" / metadata["CFBundleExecutable"]),
    )


def running(app):
    executable = (
        app["path"] / "Contents/MacOS" / info(app["path"])["CFBundleExecutable"]
    )
    result = subprocess.run(
        [
            "/usr/bin/pgrep",
            "-a",
            "-f",
            "^" + re.escape(str(executable)) + r"([[:space:]]|$)",
        ],
        capture_output=True,
        timeout=10,
        check=False,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError("Cannot inspect application processes")
    return result.returncode == 0


def quit_app(app):
    if not running(app):
        return
    command(
        "/usr/bin/osascript",
        "-e",
        f'tell application id "{app["id"]}" to quit',
        timeout=45,
    )
    for _ in range(30):
        if not running(app):
            return
        time.sleep(1)
    raise RuntimeError("App did not quit; update deferred without forcing termination")


def launch_app(app):
    command("/usr/bin/open", "-g", str(app["path"]))
    for _ in range(30):
        if running(app):
            return
        time.sleep(1)
    raise RuntimeError("App did not relaunch")


def replace_app(app, staged, backup):
    target = app["path"]
    if backup.exists():
        shutil.rmtree(backup)
    quit_app(app)
    try:
        target.rename(backup)
    except OSError:
        launch_app(app)
        raise
    try:
        staged.rename(target)
        launch_app(app)
    except Exception:
        if target.exists():
            quit_app(app)
            target.rename(staged)
        backup.rename(target)
        launch_app(app)
        raise


def install_release(app, release):
    target = app["path"]
    backups = target.parent / ".daily-app-updates-previous"
    backups.mkdir(mode=0o700, exist_ok=True)
    # Stage beside the installed app so both replacement renames use one filesystem.
    with tempfile.TemporaryDirectory(
        prefix=".daily-app-updates-", dir=target.parent
    ) as directory:
        root = Path(directory)
        archive = root / ("download" + Path(urlparse(release["url"]).path).suffix)
        fetch(release["url"], archive)
        extracted = root / "extracted"
        extracted.mkdir()
        if archive.suffix == ".dmg":
            mount = root / "mount"
            mount.mkdir()
            command(
                "/usr/bin/hdiutil",
                "attach",
                str(archive),
                "-readonly",
                "-nobrowse",
                "-mountpoint",
                str(mount),
            )
            try:
                source = mount / target.name
                verify_bundle(source, app, release["build"])
                command(
                    "/usr/bin/ditto",
                    str(source),
                    str(extracted / target.name),
                    timeout=300,
                )
            finally:
                command("/usr/bin/hdiutil", "detach", str(mount))
        else:
            command(
                "/usr/bin/ditto", "-x", "-k", str(archive), str(extracted), timeout=300
            )
        staged = extracted / target.name
        verify_bundle(staged, app, release["build"])
        # The app's own updater can run during the download. Never replace a newer build.
        if version(info(target)["CFBundleVersion"]) >= version(release["build"]):
            logger.info(
                "%s changed during download; no replacement needed", target.name
            )
            return
        replace_app(app, staged, backups / target.name)
        logger.info(
            "%s installed build %s and relaunched", target.name, release["build"]
        )


def update_app(app, check_only):
    installed = info(app["path"])
    if installed["CFBundleIdentifier"] != app["id"]:
        raise ValueError(
            "Installed app identity differs from the configured update channel"
        )
    release = select_release(
        fetch(app["feed"]), app, platform.mac_ver()[0], platform.machine()
    )
    current = installed["CFBundleVersion"]
    if version(release["build"]) <= version(current):
        logger.info("%s is current (build %s)", app["path"].name, current)
    elif check_only:
        logger.info(
            "%s update available: %s -> %s", app["path"].name, current, release["build"]
        )
    else:
        logger.info(
            "%s updating: %s -> %s", app["path"].name, current, release["build"]
        )
        install_release(app, release)


def agent_plist(state):
    return plistlib.dumps(
        {
            "Label": LABEL,
            "ProgramArguments": [
                "/usr/bin/python3",
                str(state / "updater.py"),
                "--run",
            ],
            "StartCalendarInterval": {"Hour": 4, "Minute": 0},
            "LimitLoadToSessionType": "Aqua",
            "ProcessType": "Background",
            "StandardOutPath": "/dev/null",
            "StandardErrorPath": str(LOG.parent / "launchd-error.log"),
        }
    )


def manage_agent(remove=False):
    service = f"gui/{os.getuid()}/{LABEL}"
    # launchctl reports a missing service as an error; other failures must remain visible.
    loaded = (
        subprocess.run(
            ["/bin/launchctl", "print", service], capture_output=True, check=False
        ).returncode
        == 0
    )
    if loaded:
        command("/bin/launchctl", "bootout", service)
    if remove:
        AGENT.unlink(missing_ok=True)
        logger.info("Daily task removed; backups and logs remain")
        return
    STATE.mkdir(parents=True, mode=0o700, exist_ok=True)
    shutil.copy2(Path(__file__).resolve(), STATE / "updater.py")
    AGENT.parent.mkdir(parents=True, exist_ok=True)
    AGENT.write_bytes(agent_plist(STATE))
    command("/usr/bin/plutil", "-lint", str(AGENT))
    command("/bin/launchctl", "enable", service)
    command("/bin/launchctl", "bootstrap", f"gui/{os.getuid()}", str(AGENT))
    logger.info("Daily task installed for 04:00 local time; no immediate app restart")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--install", action="store_true", help="Install the daily user LaunchAgent"
    )
    group.add_argument(
        "--remove", action="store_true", help="Unload and remove the LaunchAgent"
    )
    group.add_argument(
        "--check", action="store_true", help="Check feeds without changing apps"
    )
    group.add_argument(
        "--run", action="store_true", help="Check, install updates, and relaunch"
    )
    args = parser.parse_args()
    if platform.system() != "Darwin" or os.geteuid() == 0:
        parser.error("Run as the signed-in macOS desktop user, without sudo")
    LOG.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=[
            RotatingFileHandler(LOG, maxBytes=1_000_000, backupCount=3),
            logging.StreamHandler(),
        ],
    )
    if args.install or args.remove:
        manage_agent(args.remove)
        return 0
    STATE.mkdir(parents=True, mode=0o700, exist_ok=True)
    with (STATE / "run.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            logger.info("Another update check is running")
            return 0
        failed = False
        for app in APPS:
            try:
                update_app(app, args.check)
            except Exception:
                logger.exception("%s update failed", app["path"].name)
                failed = True
        return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
