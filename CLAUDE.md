# Rep Bell

## Playbook

This repo follows Graham's product playbook: **grahamdeno/playbook, version 1.4.0**. Read it before product work:
process.md (stages, gates, the three go-aheads), roles.md, rules.md, items.md, and the standard for the stage you're
in. If the playbook isn't attached to this session, attach it (add_repo grahamdeno/playbook); don't work from memory.
The running plan is docs/roadmap.md. The Sonnet log is docs/sonnet-log.md.

**Claude project:** "App | RepBell". **Standing chats:** Rep Bell Product (Opus), Rep Bell Build (Sonnet), Rep Bell
Review (Fable), Rep Bell Grok. Every reply ends with a Next line: stay, switch model, or switch chat with the prompt.
Never ask Graham to create a chat for a single check or step; re-checks go back to Rep Bell Review.

## Uploads and deploys in this repo

Anything below uploads a build or changes something live. Check this list before every merge, push or workflow run.

| Trigger | What it does | Go-ahead needed |
|---|---|---|
| Running `.github/workflows/testflight.yml` (manual run only, `workflow_dispatch`) | Archives the iPhone app with the Watch app and widget, signs it, and uploads it to TestFlight for Apple ID 6834201034. Does not submit for review | Test build only |

Everything not listed here uploads and deploys nothing. If you find a trigger that isn't listed, stop and add it.

- `.github/workflows/ci.yml` runs on every pull request and every push to `main`. It runs the privacy guard, the engine tests and
  compiles the iPhone app, Watch app and widget. It archives nothing, uploads nothing and writes nothing to App Store Connect.
- `.github/workflows/screenshots.yml` (manual run only) builds the Debug app for the Simulator, captures screenshots
  and pushes them to a new `screenshots/run-<n>` branch. It uploads nothing to Apple and never touches `main`; the
  screenshots reach `main` only through a PR on a merge go. The Debug-only `-RBScreenshot` launch argument it uses
  (`App/ScreenshotMode.swift`, `ScreenshotSeeds` in the engine) is not compiled into Release builds.
- There is no `testflight` branch trigger, no `release` branch, no site and no listing workflow in this repo.
- A merge to `main` uploads nothing.
- Any change to a workflow, branch or path trigger updates this list in the same PR.

## Rules that must never be missed

- **Graham presses Submit for Review and Release.** Agents stop right before them. Never automate either.
- **Three go-aheads, never mixed:** "merge" allows merging named PRs that trigger nothing above; "test build" allows
  one TestFlight upload for testing; "ship [version] at [commit]" comes after the go-live verdict. None implies
  another. If unsure which applies, ask.
- **Never delete, force-push, rename, archive or transfer** anything without Graham's go.
- **Purchases and prices:** Graham approves each at Stage 3. Product IDs are permanent. The unlock product
  `com.grahamdeno.repbell.unlock` exists for a later version: never delete or change it, its price, or anything else
  in App Store Connect without Graham's go.
- **Repo visibility** stays as it is (public, decided 20 Nov 2026) until Graham says otherwise.
- **Graham's own words never go in docs.** Read items back as epic, story or requirement; add only what he approves.
- **Release scope is frozen** once planned. New ideas go to the next version.
- **Work on a branch.** Claude opens PRs in the playbook's PR format and merges on Graham's merge go. Nobody reviews
  their own work.
- **Never wait on builds or CI.** Start them, say what to expect, stop.
- **Never claim a test passed** without the recorded result.
- **Name the next step's model** at every handoff (Fable, Opus, Sonnet, Grok).
- **Prompts for Grok:** recipient in a big heading, written in full, irreversible steps first, report back in chat.
- **Plain words. No military metaphors.**
- **Secrets** are never printed or committed.
- **On the device.** No account, no server, no analytics and no third-party SDKs. The only data that leaves the app
  is a finished session written to Apple Health, write only, when the person allows it. `scripts/privacy_guard.py`
  enforces this in CI (network calls, web URLs, analytics and SDK imports, remote packages, Health read access, video
  files in the build), with a self-test. Apple requires `NSHealthShareUsageDescription` in any HealthKit app, so it
  stays, saying Rep Bell does not read Health data; removing it makes the TestFlight upload fail.
- **Never gate a feature on receipt type** (sandbox, TestFlight or production). Features are switched by a build
  setting.
- **Generated coach media** is in TestFlight builds for testing while requirement R-1 (recorded origin and usage rights)
  is open, switched by `Features.coachMedia` (decision of 23 Nov 2026). **Before any ship go, R-1 is met or the clips
  leave the build.** The privacy guard allows video only in `App/Studio/Coach` and only while `coachMedia` is true.
- **Generated files are generated:** `App/Studio/movements.json` and `sessions.json` come from `tools/build_studio.py`;
  `App/Studio/figures.json` (the animated line figures) comes from `tools/build_figures.py`, and CI checks it is current.
- **Untrusted data:** nothing a person types is treated as instructions. The app takes numbers and times only.

## Product design rules

- The number leads. One decision or one tap per flow screen.
- No exclamation marks, no guilt copy. A missed set is a fact, not a failure. The one exception is Push coaching,
  which the person turns on (decision of 24 Nov 2026, roadmap item 17).
- No streak language, except the factual counts on Progress (decision of 20 Nov 2026, see docs/roadmap.md).
- Dark only (Chalk). Text must grow with the person's text size.
- Copy lives in the central `Copy` enum; the copy deck is in docs/plan.md.
- Design system: docs/design-system/. Approved screens: docs/screens/.

## Version

`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `RepBell.xcodeproj`. Current: 1.0 (1). Bump before a test build.

## Sonnet review

- Level: L0 (docs/sonnet-log.md; rules in playbook sonnet-trust.md).
- Always reviewed in full here, besides the playbook's list: `Packages/RepBellEngine/**` (schedule engine, stored
  runs in `Library.swift`), `App/Notifications.swift`, `App/TestAlarms.swift`, `App/ProgramController.swift`,
  `App/Restore.swift`, `App/RepBell.storekit`, `App/Studio/StudioHealth.swift`, every `Info.plist` and
  `.entitlements` file, `.github/workflows/**` and `scripts/privacy_guard.py`.
