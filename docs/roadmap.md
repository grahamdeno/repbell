# Rep Bell roadmap

The running plan for Rep Bell. It follows Graham's playbook (grahamdeno/playbook, version 1.4.0): the process, roles,
rules and item format live there and aren't repeated here. This file holds what's specific to Rep Bell: where things
stand, decisions, the backlog and what shipped.

**To pick up the work:** read "Where things stand", then "Decision log", then "Release scope", in that order.

Built from `docs/plan.md` on 20 Nov 2026. The plan stays as reference for the concept, the program table, the user
journey, the platform check, the schedule engine spec and the copy deck. Where the two differ, this file wins.

## Project and chats

- **Claude project:** "App | RepBell".
- **Standing chats:** Rep Bell Product (Opus), Rep Bell Build (Sonnet), Rep Bell Review (Fable), Rep Bell Grok.

## Where things stand (20 Nov 2026)

- **Store:** nothing released. App Store Connect record "Rep Bell: 14-Day Push-Ups", Apple ID 6834201034, iOS 1.0 in
  Prepare for Submission. Version 1.0 (build 1) in the project. Internal TestFlight only.
- **Code:** `main` at `4d32ad1`. The first build (12 to 15 Nov) was made before this repo followed the playbook.
  It includes the program, Progress, Settings, a paywall, and Workouts with coach clips and Apple Health.
- **Reviews so far:** gap review (16 to 17 Nov), design evaluation by code read (36 findings), independent review of
  it (20 Nov). All findings are in `docs/audit/findings.md` as UX-1 to UX-41.
- **Decided 20 Nov:** what 1.0 is, and the 1.0 scope, frozen (see Decision log and Release scope).
- **1.0 runs under an exception to the playbook:** Rep Bell Product (Opus) shapes, builds and merges the whole scope,
  and stops only where Graham's input is required.
- **Next step:** Product builds the scope in the order under Release scope.

## Product specifics

- **Standing rules:** see CLAUDE.md, "Rules that must never be missed" and "Product design rules".
- **Core flow (regression list):**
  1. Setup: promise, wake time, bedtime, start day, allow alerts, done.
  2. Test morning (Days 1, 8, 15): the alarm rings at wake time, the counter opens, the number is confirmed, the
     day's sets are scheduled one interval after the test.
  3. A set: the alert arrives on phone and Watch with Done and In 10 min; Done logs the set from the alert, the
     Watch or the app; an ignored set is logged as missed when the next comes due.
  4. Today shows the next set, the tally and the day bars; the widget matches.
  5. Busy for 1 hour silences alerts and marks those sets missed; Undo restores them.
  6. The alert queue refills on every log and app open (Day 10 has 61 sets; iOS holds 64 pending).
  7. Day 15: final test, result, share, run it again.
  8. Something hurts: pause and resume, or end the run with progress kept.
  9. Workouts: pick a session, play it to the end, save it to Apple Health when allowed. No set alerts during a
     session.
- **Edge cases always checked in Shape:** largest text size, small phone, VoiceOver, Reduce Motion, first run, a test
  day, Day 9 and Day 10 (46 and 61 sets), a day with missed sets, paused, run ended, alerts denied, alarm permission
  denied, Health denied, iPhone without a Watch, time zone change, a rerun.
- **Uploads and deploys:** see CLAUDE.md, "Uploads and deploys in this repo".
- **Guard:** `scripts/privacy_guard.py` enforces the on-device promise in CI, with a self-test.
- **Device checks:** alerts and Time Sensitive delivery, the test alarm through Silent and Focus, Watch actions and
  Double Tap, the widget, haptics, VoiceOver, Reduce Motion, Larger Text, Health permission.
- **Websites:** none yet for Rep Bell. tangomike.app (grahamdeno/tangomike) lists Graham's apps.
- **Compiled-in dates or values:** the program table (percent and interval per day) in the schedule engine.

## Steps that can't be undone (this product)

The playbook's list applies. This product adds:

- The unlock product `com.grahamdeno.repbell.unlock` stays in App Store Connect, unused in 1.0. It is not deleted
  or changed.
- App Privacy answers and the Apple Health permission wording: Graham approves the exact text before Grok sets them.
- The coach clips and stills remain in this public repo's history after they leave the build. Removing them from
  history would be a force-push and needs Graham's go.

## Decision log

Newest first. Refined decisions only.

| Date | Decision | Why |
|---|---|---|
| 2026-11-20 | **1.0 scope frozen** as listed under Release scope: Builds A to F, the Progress insights story, all of UX-11, a CI guard for the on-device promise, navigation, Run it again, the Watch items, Apple Health for push-ups, and the day-start alarms epic. Payment and coach media stay out | Graham's decision |
| 2026-11-20 | **Exception to the playbook for 1.0 only.** Rep Bell Product (Opus) takes every item in the 1.0 scope from shaping through build and merge without read-backs, shape approvals, mockup picks or per-PR go-aheads. Graham gave a standing merge go for the 1.0 scope (merge each PR once CI is green) and a standing test build go (one internal TestFlight upload when the scope is merged, plus one per fix round). No ship go is given. Each PR on the always-review list is reviewed by a separate agent that did not write it. Design and wording choices are recorded here as "decided by Product under the 1.0 exception" for Graham to review. Steps that can't be undone are unchanged | Graham's decision, to reach a test build without stops |
| 2026-11-20 | **Apple Health permission text:** "Rep Bell saves your finished Workouts sessions and push-ups to Apple Health. It does not read your Health data." **App Privacy answer:** Data Not Collected. Grok sets it at release, from this text | Decided by Product under the 1.0 exception. Health data stays on the device and nothing is sent to a server |
| 2026-11-20 | **UX-11 is fully in 1.0;** none of it is deferred | Graham's decision, with the scope freeze |
| 2026-11-20 | **The repo stays public for now.** Revisit at launch. The coach clips stay in the public history while R-1 is open | Graham's decision. Replaces the gap review's lean toward private |
| 2026-11-20 | **1.0 is free with no paywall. Nothing is locked.** The free and paid boundary and the price are decided in a later version. People who install 1.0 stay free when payment arrives. The unlock product stays in App Store Connect, unused. Findings UX-1, UX-13 and UX-37 are deferred to the version that adds payment | Graham's decision. **Replaces** the approved pricing of 3 free days and a $4.99 unlock |
| 2026-11-20 | **Progress keeps all its current numbers** (Day, Push-ups, Sets done, Sets missed, On time, Typical response, Perfect days in a row, Snoozed), in factual wording. Finding UX-9 is accepted. **This amends the "no streak or guilt language" voice rule: factual counts are allowed on Progress, and only there** | Graham's decision: the program only delivers its benefit when every set is done, so these numbers support staying on it |
| 2026-11-20 | **Progress will also explain what the numbers mean,** in a way that encourages. Approved as a story (item 5) to be shaped with mockups; its release is not yet decided | Graham's decision |
| 2026-11-20 | **Busy is one tap plus Undo, with no sheet. The label is "Busy for 1 hour".** | Graham's decision on UX-6. Undo makes the sheet unnecessary; the label matches the plan |
| 2026-11-20 | **Every set logged in the app keeps a full-screen celebration:** 1.5 seconds, dismissed at once by a tap, with a Reduce Motion version and time for VoiceOver to read it. **A finished day and Day 15 get a larger, longer celebration** with a haptic pattern that builds from light to strong and back, in bursts. Haptics follow system settings | Graham's decision on UX-5. Replaces the evaluation's proposal of an inline confirmation |
| 2026-11-20 | **1.0 includes the push-up program and Workouts.** Coach clips, coach stills, the Coach picker and the Grok credit leave the build. Workouts shows the built-in figure. Workouts is switched on by a build setting, never by receipt type. Saving a finished session to Apple Health stays in, **write only**; the read request is removed | Graham's decision. **Replaces** the gap review's program-only 1.0. Removes the clip rights gate for 1.0; R-1 still applies before any coach media returns |
| 2026-11-20 | The repo moves onto the playbook: CLAUDE.md block, this roadmap, the Sonnet log and the findings file. Review level L0. Work merged before today is not counted | Independent review, finding UX-40 |
| 2026-11-17 | Never gate a feature on receipt type | Gap review. App Review and TestFlight use sandbox receipts, so the gate would open for the wrong people |
| 2026-11-17 | Generated coach media needs a recorded origin and clear usage rights before any build shows it (requirement R-1, item 8) | Gap review. The clips were made with consumer tools whose terms point business use elsewhere |
| 2026-11-17 | Gap review decisions: Graham chose the review's recommended option on each. (1) 1.0 is program only, with Workouts and Health out of the build: **replaced 20 Nov**. (2) The unlock is approved at $4.99, Family Sharing off: **replaced 20 Nov**; the product stays, unused. (3) Record the origin and terms of the coach clips before any build shows them. (4) The repo goes private until launch: **replaced 20 Nov**. (5) A missed Day 1 test stays open and Day 1 moves; no sets until a max exists. (6) Dark only is accepted and recorded; text scaling is fixed | Gap review of 16 to 17 Nov |
| 2026-11-17 | Day-start epic: the day-start choice carries over as the preselected default and is still shown every morning. Any acknowledgment ends a run of quiet alerts. Day-start copy encourages and never counts missed sets | Graham's decisions when the epic was approved |
| 2026-11-12 | Design system published (Chalk tokens, 7 components, icon) | Single reference for the build |
| 2026-11-12 | App icon: h1-B, an orange chevron above a white 14 on black #121212 | Graham's pick after four rounds |
| 2026-11-12 | App Store Connect record created: Apple ID 6834201034, SKU repbell-ios; Health & Fitness, then Sports. Time Sensitive Notifications, App Groups and In-App Purchase on both App IDs. EU trader status not set | Grok's report |
| 2026-11-12 | Name: Rep Bell. Bundle IDs com.grahamdeno.repbell and com.grahamdeno.repbell.watchkitapp; App Group group.com.grahamdeno.repbell | Only name that came back clear |
| 2026-11-12 | Test counter is slide-to-set; Days 8 and 15 start at the previous max | People report the count after the set |
| 2026-11-12 | Brand direction: Chalk | Reads at a glance from the floor mid-set |
| 2026-11-12 | Minimum iOS 26, AlarmKit for test mornings | The test is never slept through |
| 2026-11-12 | "Busy for 1 hour" counts those sets as missed | Approved default |
| 2026-11-12 | Concept, journey, v1 scope and defaults approved | Graham's review |

## Release scope

- **1.0:** proposed and **frozen 20 Nov 2026**, under the 1.0 exception. Built in this order, one PR per item or small
  group:

| # | Group | Contents | Review |
|---|---|---|---|
| 1 | A. Scope | Items 1 and 4: coach media, Coach picker and credit out; Workouts on by a build setting (UX-39); Health write only; paywall unreachable; no price or free-day copy | Separate agent |
| 2 | B. No dead ends | UX-2, UX-12, UX-18, UX-28, UX-29 | Separate agent |
| 3 | Guard | A CI guard for the on-device promise, with a self-test | Separate agent |
| 4 | C. Access for everyone | UX-3, UX-4, UX-16, UX-17, UX-19, UX-20, UX-21, UX-22, UX-23, UX-34, UX-35 | Separate agent where it touches the always-review list |
| 5 | Navigation and Settings | Item 9: UX-10 and all of UX-11 | Separate agent |
| 6 | D. Daily loop and glance | Items 2 and 3; UX-14, UX-15, UX-25, UX-26, UX-27, UX-31, UX-38, UX-41 | Separate agent |
| 7 | Progress | Item 5 | Separate agent where it touches the engine |
| 8 | E. Workouts in its place | UX-7, UX-8 | Separate agent where it touches the always-review list |
| 9 | Run it again | Item 10 (UX-30) | Separate agent |
| 10 | Watch | Item 11 (UX-32) | Separate agent |
| 11 | Health for push-ups | Item 12 | Separate agent |
| 12 | Day start and ringing alarms | Item 13, all four stories | Separate agent |
| 13 | F. Words and cleanup | UX-24, UX-33, UX-36; copy deck, README.md and docs/README.md | Separate agent |

  Then the test build, Graham's checks on his phone, the Stage 5 UX walk, and the Fable go-live assessment.
- **Out of 1.0:** payment (item 7, with items 6 and UX-1, UX-13, UX-37) and coach media (item 8).
- **Purchases approved:** none in 1.0. `com.grahamdeno.repbell.unlock` (non-consumable, $4.99, Family Sharing off)
  was approved on 17 Nov 2026 and is unused since the 20 Nov decision.
- **Go-aheads:** merge: standing, for the 1.0 scope, 20 Nov 2026 (under the exception). Test build: standing, one
  internal upload when the scope is merged plus one per fix round, 20 Nov 2026. Ship: none.

## Dated checks

- **At launch (before the 1.0 ship go):** revisit repo visibility (Graham).
- **Before the 1.0 ship go:** Graham reviews every choice logged as "decided by Product under the 1.0 exception".
- **Before any coach media returns:** R-1 is met (Opus checks, Graham approves).

## Backlog

Items in the playbook's item format. Numbers are stable.

### 1. Epic: 1.0 is the program plus Workouts, without coach media (approved 2026-11-20; built in group 1)
**Goal:** ship Workouts in 1.0 without waiting on the coach clip rights.

**Context:** Workouts, coach clips and Apple Health were built before the playbook applied. The clips' usage rights
are not settled (item 8).

- Given the 1.0 build, coach clips, coach stills, the Coach picker and the Grok credit are not in the app bundle and
  not on any screen.
- Every Workouts step shows the built-in figure.
- Workouts is switched on by a build setting, never by receipt type (UX-39).
- A finished session can be saved to Apple Health. The app asks for write access only, with permission wording and
  App Privacy answers Graham approves.

**Out of scope:** coach media returning (item 8); Apple Health for push-ups (item 12).

**Steps:** 1. Shape as Build A (Opus). 2. Build (Sonnet). 3. Full diff review (Opus). 4. Health wording and privacy
answers (Opus drafts, Graham approves, Grok sets).

### 2. Story: a celebration after every in-app set, a larger one for a finished day (approved 2026-11-20; built in group 6)
As someone logging a set in the app, I want a short full-screen moment, so each set feels done.
- Given a set logged in the app, a full-screen celebration shows for 1.5 seconds, and a tap dismisses it at once.
- Given a finished day or Day 15, a larger, longer celebration plays with a haptic pattern that builds from light to
  strong and back, in bursts.
- Given Reduce Motion, there is no scale or spring; the celebration crossfades.
- Given VoiceOver, the celebration stays until it has been read or dismissed.
- Haptics follow the system settings.

**Out of scope:** a celebration for sets logged from the alert or the Watch.

**Steps:** 1. Shape with a mockup and the haptic pattern, Build D (Opus). 2. Build (Sonnet). 3. Device check of the
haptics (Graham).

### 3. Story: Busy is one tap (approved 2026-11-20; built in group 6)
As someone about to be unavailable, I want one tap to quiet the next hour, so I'm not confirming twice.
- Given Today, when I tap "Busy for 1 hour", alerts stop at once and no sheet appears.
- Then a strip shows: alerts off until [time], [n] sets count as missed, Undo.
- When I tap Undo, the alerts and the sets are restored.
- The words "Skip the next hour" appear nowhere in the app.

**Steps:** 1. Shape, Build D (Opus). 2. Build (Sonnet).

### 4. Requirement: 1.0 is free and nothing is locked (approved 2026-11-20; built in group 1)
In 1.0 no paywall can be reached on any day or rerun, and no copy mentions free days or a price.
- Enforced by tests: Day 4 and later, and a rerun, open without a purchase; no route leads to the paywall.
- Enforced by a copy test: no price or free-day wording in the `Copy` enum.
- The unlock product stays in App Store Connect, untouched.

**Steps:** 1. Shape as Build A (Opus). 2. Build (Sonnet). 3. Full diff review (Opus).

### 5. Requirement and story: Progress numbers (approved 2026-11-20; built in groups 6 and 7)
**Requirement:** Progress shows Day, Push-ups, Sets done, Sets missed, On time, Typical response, Perfect days in a
row and Snoozed, in factual wording. Enforced by a test that lists those labels.

**Story:** As someone partway through the program, I want Progress to show what my other numbers mean (for example
gain since the first test, sets left, best day, how tomorrow compares), so that I can see the program working and
want to keep going.
- Every insight is a true fact from the person's own log.
- Wording looks forward and never blames a missed set.
- Nothing is hidden behind a tap that VoiceOver can't reach.
- Open: which insights, and how they are shown. Graham picks from two or three mockups.
- Open: which release.

**Steps:** 1. Shape with mockups (Opus). 2. Graham picks. 3. Build (Sonnet).

### 6. Story: people who installed 1.0 stay free (approved 2026-11-20, for the version that adds payment)
As someone who installed Rep Bell while it was free, I want to keep everything when payment arrives, so that the
app keeps its word.
- Open: how an early install is recognised. To check in shaping: the store's own record of the first installed
  version, which would need nothing stored in 1.0.

**Steps:** 1. Confirm the mechanism before 1.0 ships, in case 1.0 must record anything (Opus). 2. Shape with the
payment version (Opus, with a Fable strategy review of the boundary and price).

### 7. Epic: payment (later; not yet shaped)
The free and paid boundary and the price; a paywall with a way out and Restore (UX-1); correct purchase messages
(UX-13); a locked day that starts while the app is open (UX-37); item 6.
Also: Settings lost its Purchase section (unlock status and Restore purchase) in the 1.0 Settings rebuild. It must
come back, behind `Features.payment`, before payment is turned on.

### 8. Requirement R-1: every coach image and clip has a recorded origin (read back 17 Nov 2026; approval not recorded)
Each batch of coach media is logged in `docs/provenance.md`: the tool and plan, the date, the prompt, where the
originals are kept, and the terms that applied. No build shows coach media until its usage rights are confirmed in
writing or the media is remade with a tool whose terms clearly allow the use.
- Open: Graham's approval of the read-back is not on record. Until then it is applied as a gate, as CLAUDE.md says.

### 9. Navigation (in 1.0, group 5; built)
Browse screens on a navigation stack with swipe-back (UX-10); program settings in sections with a direct Settings
entry (UX-11, the part outside Build E).

### 10. Run it again review screen (in 1.0, group 9; built; UX-30)

### 11. Watch: complication, Busy on the wrist, the number's color rule (in 1.0, group 10; built except the complication, which needs Graham's approval of a new bundle ID; UX-32)

### 12. Apple Health for push-ups (later; from the plan's v1 scope table)

### 13. Epic: Day start and alarms that ring through silent

**Status:** Idea approved by Graham, Nov 17, 2026. Next: Shape (Opus).

**Goal:** set alarms reach the user when the phone is on silent, and the user stays in control of the noise.

**Context:**
- Set alerts are Time Sensitive banners and deliver correctly (verified Nov 17, 2026); silent mode mutes their sound by design.
- AlarmKit (iOS 26, already the minimum) is used for test-morning alarms on days 1, 8 and 15. AlarmKit alarms break through Silent and Focus with user consent and surface on a paired Watch.
- An app cannot take over the screen on its own. The only full-screen moment is the system alarm screen, whose layout Apple controls.

**Story 1, Morning screen.** As a user, I want a full-screen start to each program day so that I see the day's plan and choose Ring or Quiet.
- Given a program day, when the wake alarm rings and I tap it, then the app opens to the day-start screen with the day number, today's set count and the Ring/Quiet choice.
- Given yesterday I chose Quiet, when today's day-start screen opens, then Quiet is preselected and one tap starts the day.
- Given I never open the day-start screen, when sets come due, then the day uses yesterday's choice (Ring on the first day).

**Story 2, Ringing set alarms.** As a user, I want set alarms to ring through silent mode on Ring days so that I don't miss them.
- Given a Ring day, when a set is due, then an AlarmKit alarm rings even with the phone on silent or in Focus.
- Given a Quiet day, when a set is due, then it arrives as a Time Sensitive banner with a Watch tap, as today.

**Story 3, Quiet next.** As a user, I want each ringing alarm to offer "Quiet next" so that I can mute the next set without opening the app.
- Given an alarm is ringing, when I tap Quiet next, then the next set arrives as a banner with a Watch tap and no sound.
- Given an alarm is ringing, when I tap Got it, then the next set rings.

**Story 4, Quiet streak.** As a user, I want a missed quiet alert to keep the next one quiet so that the app does not ring while I am busy.
- Given a quiet alert goes unacknowledged, when the next set is due, then it is also quiet.
- Given a quiet streak, when I tap a quiet banner, log a set, or open the app, then the streak ends and the next set rings.
- Given a quiet streak still running at the end of the day, when the next program day starts, then the day-start choice applies.

**Decisions (Nov 17, 2026):**
- The day-start choice carries over from the previous day as the preselected default; it is still shown every morning.
- Any acknowledgment ends a quiet streak: tapping a quiet banner, logging a set, or opening the app.
- Day-start copy encourages and never guilts (for example "Day 5. 6 sets today."), never counts of missed sets.

**Out of scope:** Critical Alerts; changes to the program schedule.

**Open questions (for Shape):**
1. Morning alarm on every program day, or only test days? Recommendation: every program day, since it is the only way to reach the day-start screen.
2. Keep "Busy for 1 hour"? Recommendation: keep. It silences an hour and marks those sets missed; Quiet next mutes one set and marks nothing.
3. Dense days: Day 10 has 61 sets, every 15 minutes. Consider ringing only every second or fourth set on dense days, or capping rings per hour.
4. Confirm AlarmKit supports a custom secondary button that runs an App Intent (for Quiet next), and any limit on how many alarms an app can schedule.

**Steps:**
1. Shape: AlarmKit API check; edge cases (Watch, iPad, VoiceOver, Reduce Motion, big text, test mornings, Busy for 1 hour); copy; mockup from the design system. Model: Opus.
2. Graham approves the shaped stories. Graham.
3. Plan the release and freeze scope. Opus proposes, Graham picks.
4. Build from Ready stories. Model: Sonnet.

## Small follow-ups

- Missed Day 1 test: the test stays open and Day 1 moves (decided 17 Nov). Not yet checked against the code.
- `docs/provenance.md` for the coach media, from the evidence kept in Graham's Claude project (item 8).
- README.md and docs/README.md still describe the first build's rules; they are brought in line in Build F (UX-24).

## Shipped

- Nothing yet.
