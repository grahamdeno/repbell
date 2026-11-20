#!/usr/bin/env python3
"""Writes docs/screenshots/README.md from the captured files and scripts/screenshot_states.tsv."""
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
out = root / "docs" / "screenshots"
states = {}
for line in (root / "scripts" / "screenshot_states.tsv").read_text().splitlines():
    if line.strip():
        key, screen, state, how = line.split("\t")
        states[key] = (screen, state, how)
watch = {
    "watch-empty": ("Watch", "No run yet", "No run seeded"),
    "watch-set-due": ("Watch", "Set alert screen (a set due now)", "Same run as today-set-due"),
    "watch-between-sets": ("Watch", "Today, between sets", "Same run as today-between-sets"),
    "watch-busy": ("Watch", "Today, Busy active", "Same run as today-busy"),
    "watch-finished": ("Watch", "Today, day finished", "Same run as today-finished"),
}
states.update(watch)
sizes = {"default": "Large (default)", "ax3": "AX3", "ax5": "AX5 (largest)"}
devices = {"iphone16promax": "iPhone 16 Pro Max", "iphonese3": "iPhone SE (3rd gen)", "watch41mm": "Apple Watch 41 mm class", "watch45mm": "Apple Watch 45 mm class"}

rows = []
for png in sorted(out.glob("*.png")):
    device, size, state = png.stem.split("_", 2)
    screen, what, how = states.get(state, ("?", state, "?"))
    rows.append(f"| `{png.name}` | {devices.get(device, device)} | {sizes.get(size, size)} | {screen} | {what} | {how} |")

log = (out / ".capture-log.txt").read_text() if (out / ".capture-log.txt").exists() else ""
failed = [l for l in log.splitlines() if "failed" in l or l.startswith("no ")]
watch_used = [l for l in log.splitlines() if " uses " in l]
tz = [l for l in log.splitlines() if l.startswith("Time zone")]

text = f"""# Rep Bell screenshots (current build)

Captured from the real app, built in Debug for the Simulator from `main` by `.github/workflows/screenshots.yml`
(`scripts/screenshots.sh`). Each state is reached with the Debug-only launch argument `-RBScreenshot <state>`, which
loads a seeded run in memory (nothing is saved) and opens one screen. The seeded runs are built relative to the
current time by `ScreenshotSeeds` in the engine, so the real schedule engine produces every number shown. The app's
time zone is set so local time is mid-afternoon. The status bar is overridden to 3:00.

Names: `<device>_<textsize>_<screen-state>.png`. {len(rows)} files.

{chr(10).join(tz)}
{chr(10).join(watch_used)}

| File | Device | Text size | Screen | State | How it was reached |
|---|---|---|---|---|---|
{chr(10).join(rows)}

## Not captured here

- Lock Screen alert, expanded alert with Done and In 10 min, and the AlarmKit alarm screens: the Simulator can't
  produce them reliably. Capture them on a phone.
- Widgets (every family and state): the Simulator can't place a widget on the Home or Lock Screen from a script.
- Light mode: the app is dark only and doesn't respond to light mode, so there's no light set.
- Busy sheet, Coach settings, and the paywall as the Day 4 screen or from Workouts: these no longer exist in 1.0
  (Busy is one tap; coach media is out; nothing is locked). The paywall screen itself is shown for the record.
- Settings below the first screen, and the End confirmation under Something hurts: both need taps or scrolling,
  which the script doesn't do.
"""
if failed:
    text += "\n## Capture problems\n\n" + "\n".join(f"- {l}" for l in failed) + "\n"
(out / "README.md").write_text(text)
print(f"README written, {len(rows)} rows, {len(failed)} problems")
