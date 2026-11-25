import importlib.util
import plistlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "scripts/daily-app-updates.py"
spec = importlib.util.spec_from_file_location("updater", SOURCE)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.app = {**updater.APPS[0], "enabled": True}

    def feed(self, items):
        return (
            '<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">'
            f"<channel>{items}</channel></rss>"
        ).encode()

    def item(self, build, extra="", host="persistent.oaistatic.com"):
        return (
            f"<item><sparkle:version>{build}</sparkle:version>{extra}"
            f'<enclosure url="https://{host}/app.zip" /></item>'
        )

    def test_selects_newest_compatible_public_full_release(self):
        feed = self.feed(
            self.item(10)
            + self.item(
                15, "<sparkle:minimumSystemVersion>99.0</sparkle:minimumSystemVersion>"
            )
            + self.item(13, "<sparkle:channel>beta</sparkle:channel>")
            + self.item(
                14,
                "<sparkle:hardwareRequirements>x86_64</sparkle:hardwareRequirements>",
            )
            + self.item(12)
        )
        release = updater.select_release(feed, self.app, "27.2", "arm64")
        self.assertEqual(release["build"], "12")

    def test_rejects_untrusted_download(self):
        with self.assertRaises(ValueError):
            updater.select_release(
                self.feed(self.item(10, host="example.com")),
                self.app,
                "27.2",
                "arm64",
            )

    def test_disabled_chatgpt_skips_checks_and_app_control(self):
        self.assertEqual([app["id"] for app in updater.APPS], ["com.openai.codex"])
        for check_only in (False, True):
            with (
                self.subTest(check_only=check_only),
                patch.object(updater, "info") as metadata,
                patch.object(updater, "fetch") as fetch,
                patch.object(updater, "install_release") as install,
                patch.object(updater, "command") as command,
                patch.object(updater, "quit_app") as quit_app,
            ):
                updater.update_app(updater.APPS[0], check_only)
                metadata.assert_not_called()
                fetch.assert_not_called()
                install.assert_not_called()
                command.assert_not_called()
                quit_app.assert_not_called()

    def test_enabled_app_installs_newer_release(self):
        app = self.app
        release = {"build": "12"}
        with (
            patch.object(
                updater,
                "info",
                return_value={"CFBundleVersion": "11", "CFBundleIdentifier": app["id"]},
            ),
            patch.object(updater, "fetch", return_value=b"feed") as fetch,
            patch.object(updater, "select_release", return_value=release),
            patch.object(updater, "install_release") as install,
        ):
            updater.update_app(app, False)
            fetch.assert_called_once_with(app["feed"])
            install.assert_called_once_with(app, release)

    def test_current_or_newer_install_does_not_download_or_quit(self):
        for build in ("12", "13"):
            with (
                self.subTest(build=build),
                patch.object(
                    updater,
                    "info",
                    return_value={
                        "CFBundleVersion": build,
                        "CFBundleIdentifier": self.app["id"],
                    },
                ),
                patch.object(updater, "fetch", return_value=b"feed"),
                patch.object(updater, "select_release", return_value={"build": "12"}),
                patch.object(updater, "install_release") as install,
            ):
                updater.update_app(self.app, False)
                install.assert_not_called()

    def test_dry_run_reports_update_without_install(self):
        with (
            patch.object(
                updater,
                "info",
                return_value={
                    "CFBundleVersion": "11",
                    "CFBundleIdentifier": self.app["id"],
                },
            ),
            patch.object(updater, "fetch", return_value=b"feed"),
            patch.object(updater, "select_release", return_value={"build": "12"}),
            patch.object(updater, "install_release") as install,
        ):
            updater.update_app(self.app, True)
            install.assert_not_called()

    def test_failed_launch_restores_previous_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target, staged, backup = (
                root / name for name in ("App.app", "new.app", "old.app")
            )
            target.mkdir()
            (target / "version").write_text("old")
            staged.mkdir()
            (staged / "version").write_text("new")
            app = {**self.app, "path": target}
            with (
                patch.object(updater, "quit_app"),
                patch.object(
                    updater,
                    "launch_app",
                    side_effect=[RuntimeError("launch failed"), None],
                ),
                self.assertRaises(RuntimeError),
            ):
                updater.replace_app(app, staged, backup)
            self.assertEqual((target / "version").read_text(), "old")

    def test_success_keeps_previous_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target, staged, backup = (
                root / name for name in ("App.app", "new.app", "old.app")
            )
            target.mkdir()
            (target / "version").write_text("old")
            staged.mkdir()
            (staged / "version").write_text("new")
            with patch.object(updater, "quit_app"), patch.object(updater, "launch_app"):
                updater.replace_app({**self.app, "path": target}, staged, backup)
            self.assertEqual((target / "version").read_text(), "new")
            self.assertEqual((backup / "version").read_text(), "old")

    def test_failed_backup_rename_reopens_original_app(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "App.app"
            target.mkdir()
            (target / "version").write_text("old")
            process = root / "process-state"
            process.write_text("running")
            with (
                patch.object(
                    updater,
                    "quit_app",
                    side_effect=lambda app: process.write_text("stopped"),
                ),
                patch.object(
                    updater,
                    "launch_app",
                    side_effect=lambda app: process.write_text("running"),
                ),
                patch.object(Path, "rename", side_effect=OSError("rename failed")),
                self.assertRaises(OSError),
            ):
                updater.replace_app(
                    {**self.app, "path": target},
                    root / "new.app",
                    root / "old.app",
                )
            self.assertEqual((target / "version").read_text(), "old")
            self.assertEqual(process.read_text(), "running")

    def test_plist_runs_daily_without_install_time_restart(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            data = plistlib.loads(updater.agent_plist(path))
            self.assertEqual(data["StartCalendarInterval"], {"Hour": 4, "Minute": 0})
            self.assertNotIn("RunAtLoad", data)
            self.assertEqual(data["ProgramArguments"][-1], "--run")


if __name__ == "__main__":
    unittest.main()
