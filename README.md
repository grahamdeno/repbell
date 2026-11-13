# repbell

Rep Bell: 14-Day Push-Ups. An iPhone and Apple Watch app that rings at every set and logs each one with a tap.

The plan, design system, approved screens, and icon are in `docs/`. Those files are the source of truth.

## Layout

- `Packages/RepBellEngine` — the schedule engine. Pure Swift. The 13 cases from the Schedule engine spec are in `Tests/RepBellEngineTests`.
- `App` — the iPhone app (`com.grahamdeno.repbell`).
- `Watch` — the Watch app (`com.grahamdeno.repbell.watchkitapp`).
- `Widget` — the Lock Screen and Home Screen widget (`com.grahamdeno.repbell.widget`).
- `RepBell.xcodeproj` — iOS 26, AlarmKit for test mornings, app group `group.com.grahamdeno.repbell`.

The 1024 px icon is h1-B. The 14 is outlined from Barlow Condensed Black so the App Store file does not depend on the font. The outlined SVG is `App/rep-bell-icon-outlined.svg`.

## Build

```sh
swift test --package-path Packages/RepBellEngine
xcodebuild -project RepBell.xcodeproj -scheme RepBell -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions on `macos-26` runs the package tests and that compile. It does not archive, notarize, upload a build, or submit for review.

Nothing merges, ships to TestFlight, or gets submitted until Graham says ship.
