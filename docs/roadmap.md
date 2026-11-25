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

## Where things stand (22 Nov 2026)

- **Store:** nothing released. App Store Connect record "Rep Bell: 14-Day Push-Ups", Apple ID 6834201034, iOS 1.0 in
  Prepare for Submission. Internal TestFlight only.
- **1.0 scope:** open (decision of 20 Nov 2026); items join as Graham approves them. Built under the 1.0 exception.
- **Test builds:** 15 rejected at upload (missing NSHealthShareUsageDescription, fixed in #30); 16 and 17 uploaded;
  18 and 19 failed at signing (certificate limit); 20, 22, 23, 24, 26 and 27 uploaded; 25 cancelled before it
  started; 28 failed at signing (certificate limit); 29 uploaded 25 Nov 2026 from `2040cee` (coach clips, volt icon,
  paid unlock, Coach voice, harder Push, tap to clear).
- **Screenshots:** `docs/screenshots/` holds run 3; run 4 (24 Nov, with the paywall) is on `screenshots/run-4`, and its paywall shot is the purchase's review screenshot.
- **Not built:** the Watch face complication (needs a new bundle ID, which needs Graham's approval); the new app
  icon (art pending Graham's approval); "Start set now" (early sets, not yet shaped).
- **Next:** Graham lives on the newest test build; fix rounds as he finds things; the Stage 5 UX walk; the Fable go-live
  assessment. Graham reviewed and agreed every "decided by Product under the 1.0 exception" line on 25 Nov 2026.

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
| 2026-11-25 | **Product's 1.0 calls reviewed:** Graham agreed the Desk stretch flow, Fit my time details, Desk stretch joining 1.0, the Health read permission text, the Health permission text with "Data Not Collected", and this week's calls (glow at 30% and 22%, Fit my time needs the unlock, no free sample sessions) | Graham's review |
| 2026-11-25 | **Watch coach line joins 1.0** (item 19), moved back from the next version; **light mode is dropped** | Graham's decisions |
| 2026-11-25 | **Hourly desk stretch on weekdays joins 1.0** (item 20) | Graham's decision |
| 2026-11-25 | **Background glow:** every iPhone screen has a violet glow behind the top and a volt glow from the bottom right over `ground`; flood screens keep their colour and the Watch stays black. Set to 30% and 22% so muted text stays at 4.5:1 everywhere and faint outlines at 3:1 | Graham's decision ("build the glow", from the violet and volt mockups) |
| 2026-11-25 | **Test builds reuse one saved signing certificate.** "Apple Development: Graham DeNoyer" (expires 25 Nov 2027) is loaded from build secrets into a temporary keychain each run, so runs stop creating development certificates while it is valid. The archive step checks the app was signed with it. Renew it before 25 Nov 2027 | Graham's go 25 Nov 2026 (Product's recommendation). Builds 18, 19 and 28 had failed on the Apple Development certificate limit |
| 2026-11-24 | **Coach voice in 1.0:** a Settings choice of Off, Coaching or Push. Coaching reads the person's stats, recognizes past wins and looks ahead, with no guilt. Push says the same stats bluntly and may name a missed set, snooze or skipped day as a broken commitment, within limits (item 17) | Graham's decision |
| 2026-11-24 | **Design rule amended:** no guilt copy, except in Push coaching, which the person turns on | Graham's decision. **Amends** the no-guilt design rule |
| 2026-11-24 | **1.0 is paid:** the program, bells, logging, Progress, Watch and Desk stretch stay free; Workouts and Coach voice need the one-time unlock `com.grahamdeno.repbell.unlock` at $4.99 (item 18) | Graham's decision. **Replaces** the 20 Nov decision that 1.0 is free with no paywall (item 4) |
| 2026-11-23 | **Coach clips return for TestFlight testing.** Both coaches' clips (68 movements, 16 of the 19 desk stretches) and the Coach picker are back in the build, switched by `Features.coachMedia`. A move with no clip yet shows its line figure. The About screen credits "Coach animations created with Grok." R-1 stays open: written permission was asked of xAI on 23 Nov 2026. Before any ship go, R-1 is met or `coachMedia` goes back to false and the clips leave the build | Graham's decision. **Replaces** the 20 Nov rule that coach media stays out of every build |
| 2026-11-22 | Animated figures: every Workouts movement and desk stretch shows an animated line figure (side, front or hand close-up view, turn arrows for rotations, several key positions for flows), drawn by the app from numbers in figures.json. No art files, no outside media, no network | Approved by Graham after the thread-the-needle and rice-bucket-twist samples |
| 2026-11-22 | D7 amended: lime `volt` stays. The bell-ring flood becomes a dark olive tint (`flood` #202B06) with the number and bell in volt and soft text in `flood-soft` #A8C25A, instead of a full lime screen. The taller day bars with outlined upcoming days (from #39) stay | Graham, after trying amber: keep the lime, tone the flood down to a dark screen |
| 2026-11-22 | D8 reversed: the amber palette and deep amber flood are withdrawn, so D7 (Volt lime, full volt bell-ring flood) stands. The one wording change kept: `ink-faint` is for outlines only, never text | Graham's decision, relayed from the design system chat |
| 2026-11-22 | D8 (reversed the same day, see above): the "now" color changed from lime to amber (#FFB020) and the bell-ring flood became a deep amber tint (#3A2A08). Shipped in test build 21 only | Graham found the lime hard on his eyes in build 20 |
| 2026-11-21 | D7: palette changes from Chalk (one orange) to Volt and Ultraviolet: lime `volt` for now, violet `ultraviolet` for earned, a volt flood when a set's bell rings, Day 15 the only ultraviolet flood. Tokens in docs/design-system/tokens.json | Approved by Graham from the palette canvas |
| 2026-11-20 | Screenshots of the real build: a Debug-only launch argument opens the app in a seeded state (never saved, never compiled into Release), and a manual workflow captures each state in the Simulator on GitHub's Mac and pushes the PNGs to a screenshots branch for a PR | Graham's choice (option 1); built by Product |
| 2026-11-20 | Desk stretch flow fixed after Graham's first use (it started without warning, and a Done button mid-stretch ended it): a start screen with Start and Skip; 5 seconds to get into position; then the hold, with two-sided stretches held 20 seconds per side, a 5-second Switch sides between, and each side named on screen, with a haptic and a VoiceOver cue; End early is the only control while it runs; Stretch done and the only big Done come at the end | Graham's report; flow decided by Product under the 1.0 exception |
| 2026-11-20 | **Fit my time joins 1.0** (item 15), with a 5-minute option; and a Workouts button joins the top of Today | Graham's decision to add both; he asked for Product's best calls on the details |
| 2026-11-20 | Fit my time details: name "Fit my time"; choices 5, 10, 15, 20, 30 and 45 minutes; one decision (the minutes), with the focus set by program day (test mornings and the day after: mobility; other even days: legs and back; odd days: core and easy cardio; no run: full body); warm-up, main moves in 40-second blocks with 20-second rests (two-sided moves split with a switch), cool-down always ending with breathing, timed to end exactly on the minute; during a run no move from an upper-body session; gear the person lacks is skipped unless a stand-in exists; "Another one" reshuffles; first row in Workouts | Decided by Product under the 1.0 exception |
| 2026-11-20 | **1.0 scope is open again, not frozen.** Graham expects to add what he finds he needs while living on the test builds. New items join 1.0 as he approves them | Graham's decision |
| 2026-11-20 | **Desk stretch joins 1.0** (item 14). Name "Desk stretch"; at most once an hour | Graham's decision to add it to 1.0; name and frequency decided by Product under the 1.0 exception |
| 2026-11-20 | The Health read permission text is back: Apple rejects any HealthKit app without it, even one that only saves (TestFlight run 15 failed on this). It says Rep Bell does not read Health data; the app still asks for no read access, and the privacy guard checks both | Found by the failed upload; decided by Product under the 1.0 exception |
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

- **1.0:** proposed 20 Nov 2026, frozen, then **reopened the same day at Graham's call**; items join as he approves them. Under the 1.0 exception. Built in this order, one PR per item or small
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
- **Before the 1.0 ship go:** Graham reviews every choice logged as "decided by Product under the 1.0 exception". Done 25 Nov 2026: all agreed.
- **Before any ship go:** R-1 is met for every coach clip in the build, or the clips leave the build (Opus checks, Graham approves).

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

### 4. Requirement: 1.0 is free and nothing is locked (approved 2026-11-20; built in group 1; replaced 2026-11-24 by item 18)
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

### 6. Story: people who installed 1.0 stay free (approved 2026-11-20; no longer needed from 2026-11-24, since 1.0 itself is paid)
As someone who installed Rep Bell while it was free, I want to keep everything when payment arrives, so that the
app keeps its word.
- Open: how an early install is recognised. To check in shaping: the store's own record of the first installed
  version, which would need nothing stored in 1.0.

**Steps:** 1. Confirm the mechanism before 1.0 ships, in case 1.0 must record anything (Opus). 2. Shape with the
payment version (Opus, with a Fable strategy review of the boundary and price).

### 7. Epic: payment (folded into item 18 on 2026-11-24)
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

### 12. Apple Health for push-ups (in 1.0, group 11; built)

### 13. Epic: Day start and alarms that ring through silent (in 1.0, group 12; built)

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

### 14. Story: Desk stretch after a set (approved 2026-11-20; in 1.0; built)
As someone who sits all day, I want each push-up set to end with one short stretch for sitting posture, so every
set also undoes some desk time.
- Given Desk stretch is on in Settings, when I log a set, Rep Bell shows one stretch with its name and two cues;
  nothing counts until I tap Start, then 5 seconds to get into position, then the hold (two-sided stretches: 20
  seconds per side with a Switch sides step); Done appears only at the end.
- It rotates through hip flexor, doorway chest, neck, wall chest and seated hamstring (the Workouts cues).
- At most once an hour. Done or Skip; nothing is recorded either way.
- A set logged from an alert or the Watch brings the stretch as a quiet notification, which also shows on the Watch.
- Off by default; the program doesn't change.

**Out of scope:** a stretch screen on the Watch itself; stretches chosen by the person.

### 15. Story: Fit my time (approved 2026-11-20; in 1.0; built)
As someone with a gap in my day, I want to say how much time I have and get one session made to fit, so I can use
the time without choosing moves myself.
- Given Workouts, when I tap Fit my time and pick 5, 10, 15, 20, 30 or 45 minutes, Rep Bell builds one session that
  lasts exactly that long.
- It has a warm-up and a cool-down; the middle comes from the Workouts moves, with their cues.
- It respects my gear, Go easy on, and the program: no upper-body pushing or pulling during the 14 days, mobility
  on test mornings and the day after.
- It plays, holds set alerts and saves to Health like any session. "Another one" gives a different mix.

**Out of scope:** choosing the focus; saving a built session.

### 16. Story: animated figures for every move (approved 2026-11-22; in 1.0; built)
As someone doing a move I don't know, I want to see it move, not only read the steps, so I do it right.
- Given any Workouts movement or desk stretch, the picture shows a line figure easing between the move's key
  positions in a loop, in volt on the surface panel.
- Each move uses the view that explains it: side for most, front for sideways and "arm under" moves, a close-up of
  the hand in a cut-away bucket for the grip moves. Far-side limbs are dimmer so depth reads.
- Pure rotations (Russian twist, supine twist, halo, hip and arm circles) add a turn arrow. Flows step through their
  key positions in order.
- During a rest the picture shows the next move's key position, still and dim.
- With Reduce Motion on, the key position shows without moving. The picture is decorative; the cues stay the
  instructions for VoiceOver.
- Positions are numbers in `App/Studio/figures.json`, built by `tools/build_figures.py`; CI checks every movement and
  desk stretch has one. No art files, outside media or network, so R-1 does not apply.

**Out of scope:** realistic people, hand grip detail beyond the close-ups, choosing a camera angle.

### 17. Epic: Coach voice (approved 2026-11-24; in 1.0; paid)
**Goal:** after each set and at the end of the day, one short line that reacts to the person's own numbers, in the
voice they choose.

**Story:** As someone on the program, I want a coach line that knows my numbers, in the tone I pick, so that I keep
going.
- Given Settings, when the person opens Coach voice, then the choices are Off, Coaching and Push; Off is the default.
- Given Coaching, the line uses the person's own numbers, recognizes a past win or looks ahead, and carries no guilt.
- Given Push, the line uses the same numbers, is blunt, and may name a missed set, a snooze or a skipped day as a
  broken commitment.
- Push never uses profanity, never mentions the person's body, weight or worth, never urges past injury or pain
  beyond normal effort, and always ends pointed at the next rep.
- Inputs are numbers only: reps this set and today against the plan, best day, starting max and test results, sets
  done and missed, snoozes, days completed. Nothing a person types reaches the model.
- Apple's on-device model writes the line; nothing leaves the phone. Where the model is unavailable, refuses, or
  returns a line that breaks the rules, a written line for that mode and moment is shown.
- The line has no exclamation marks, grows with text size and is read by VoiceOver.
- With a coach line showing, the celebration stays until the person taps to clear it; a desk stretch comes up only after that.
- Push is hard: no praise unless every set is done, and then only briefly; excuses, snoozes and missed sets are called out as broken commitments.
- Push varies: no line repeats within 36 sets (on Day 10, a line shows at most twice), missed and snooze call-outs come every third set, and most lines speak to discipline and keeping your word rather than reciting counts. Lines may run to two or three sentences.
- The Watch coach line is item 19 (back in 1.0 on 25 Nov 2026).
- Needs the unlock (item 18). Without it, the Settings choice shows the unlock.

**Out of scope:** a named or real person's voice, spoken audio, lines about anything but the person's numbers.

**Steps:** 1. Shape lines and screens (Opus). 2. Build (Opus under the 1.0 exception). 3. Review by a separate
agent.

### 18. Epic: Workouts and Coach voice are paid (approved 2026-11-24; in 1.0)
**Requirement:** the 14-day program, bells, logging, Progress, the Watch app and Desk stretch never need a purchase.
Workouts and Coach voice need the one-time unlock `com.grahamdeno.repbell.unlock`, $4.99, no subscription.
- Given no unlock, when the person opens Workouts or picks a Coach voice other than Off, then a paywall shows what the
  unlock adds, its price from the store, Buy, Restore purchase and a way out.
- Given the unlock bought or restored, Workouts and Coach voice open at once and stay open across launches.
- Settings shows the unlock status and Restore purchase.
- Purchase and restore messages are correct for success, cancel, pending and failure (UX-13).
- Switched by `Features.payment`. Never gated on receipt type.
- Enforced by tests: the free list opens without a purchase; Workouts and Coach voice do not.

**Steps that can't be undone:** the product's price ($4.99), display name and description in App Store Connect are
set by Grok on Graham's go. The App Privacy answers ("Purchases") are approved by Graham.

**Steps:** 1. Build (Opus under the 1.0 exception). 2. Review by a separate agent. 3. Grok confirms the product in
App Store Connect after Graham's go.

### 19. Story: Watch coach line (approved 2026-11-25; in 1.0; paid)
As someone logging sets on the Watch, I want the coach line there too, so that the voice I chose reaches me wherever
I log.
- Given Coach voice on and the unlock, when a set is logged on the Watch, then the Watch shows the coach line in the
  chosen voice: the iPhone's model line when the iPhone is reachable, a written line otherwise.
- It waits for a tap to clear, like the iPhone.
- Same rules as item 17; numbers only.

### 20. Story: hourly desk stretch on weekdays (approved 2026-11-25; in 1.0; free)
As someone who sits all day, I want a desk stretch every hour on weekdays, whether or not a program is running, so
that I move regularly.
- Given Desk stretch on, then Monday to Friday, on the hour, from 9 a.m. to 5 p.m. by default (start and end
  adjustable in Settings), a quiet notification names the stretch; tapping it opens the stretch.
- It skips an hour when a program set's bell is within 15 minutes, or when a stretch was done in the last hour.
- Stretches rotate through all 19 with no back-to-back repeats.
- Notifications are scheduled a day or two ahead within iOS's limit of 64, and topped up when the app opens or a set
  is logged.

## Small follow-ups

- Missed Day 1 test: the test stays open and Day 1 moves (decided 17 Nov). Not yet checked against the code.
- `docs/provenance.md` for the coach media, from the evidence kept in Graham's Claude project (item 8).
- README.md and docs/README.md still describe the first build's rules; they are brought in line in Build F (UX-24).

## Shipped

- Nothing yet.
