# Rep Bell: Product Concept and Plan

Exported Nov 12, 2026 from the Claude doc of the same name. This file is the build's source of truth; if it and the original doc ever differ, ask Graham.

## Start here

This is the single plan for an iPhone and Apple Watch app that runs the 14-day "Evil Russian" push-up program for you. It is kept current so any agent or new conversation can pick up the work without drifting.

**To pick up the work:** read Start here, then the Decision log, then Next steps, in that order. Everything else is reference. Approved screens and the icon are in `docs/screens/`; the design system (tokens, components, brand book) is in `docs/design-system/`; the icon SVG is in `docs/icon/`.

**Status (Nov 12, 2026):** concept, journey, scope and defaults approved. Name: Rep Bell (store name Rep Bell: 14-Day Push-Ups). App Store Connect record created (Apple ID 6834201034), iOS 1.0 in Prepare for Submission. Chalk brand direction, all setup and core screens, app icon h1-B and the design system are approved. Platform check, engine spec and copy deck written. Repo created. Nothing is built.

**Standing rules:**
- **Nothing merges, ships to TestFlight or gets submitted until Graham says ship.** Graham presses Submit for Review himself.
- One decision or one tap per flow screen.
- Graham picks the model per step (Opus for design and judgment, Sonnet for building).

## Concept

An iPhone and Apple Watch app that runs the 14-day Evil Russian push-up program for you: it does the math, rings at every set, and takes one tap to log.

**The outcome people want:** a visibly higher max on Day 15, without thinking about the program for two weeks.

**The gap:** the program is simple on paper and miserable to administer. Every day has a new percentage and a new interval, so people set dozens of phone alarms by hand. The only dedicated app is Android-only and was last updated in December 2019. No iOS app runs this protocol.

**The product in one sentence:** tell it your max once, and for 14 days your wrist tells you when to drop and how many.

**Principles**
- One decision or one tap per flow screen. If a screen needs two, it becomes two screens or the app decides.
- The app carries the schedule; the user carries nothing. No math, no alarms, no planning.
- The set is the unit. Every alert ends in one tap: done, or later.
- Honest, never shaming. A missed set is logged as missed and the day goes on; no streak penalties, no guilt copy.
- On the device. No account, no server; the whole program fits on the phone.
- Watch first for the moment of the set. The phone is for setup and the record.

## The program

14 days of submaximal sets spread across every waking hour, bracketed by max tests on Day 1, Day 8 and Day 15. Each day sets a relative intensity (RI, a percentage of your last max, rounded up) and a set frequency (SF, minutes between sets).

**Rules:** test to failure on test days, then start that day's sets; do each set when due; no skipped sets; last set one hour before bed; no other upper-body training during the two weeks.

Illustration: max 50, awake 7:00 a.m. to 11:00 p.m. (sets 7:00 a.m. to 10:00 p.m.), same max in week 2. RI and SF are from the sources; the last three columns are calculated.

| Day | RI | SF | Sets | Reps per set | Total reps |
| --- | --- | --- | --- | --- | --- |
| 1 (test) | 30% | 60 min | 16 | 15 | 240 + test |
| 2 | 50% | 60 min | 16 | 25 | 400 |
| 3 | 60% | 45 min | 21 | 30 | 630 |
| 4 | 25% | 60 min | 16 | 13 | 208 |
| 5 | 45% | 30 min | 31 | 23 | 713 |
| 6 | 40% | 60 min | 16 | 20 | 320 |
| 7 | 20% | 90 min | 11 | 10 | 110 |
| 8 (test) | 35% | 45 min | 21 | 18 | 378 + test |
| 9 | 55% | 20 min | 46 | 28 | 1,288 |
| 10 | 30% | 15 min | 61 | 15 | 915 |
| 11 | 65% | 60 min | 16 | 33 | 528 |
| 12 | 35% | 45 min | 21 | 18 | 378 |
| 13 | 45% | 60 min | 16 | 23 | 368 |
| 14 | 25% | 120 min | 8 | 13 | 104 |
| 15 | Final max test | | | | |

**What this means for the build:** Day 9 and Day 10 are the stress cases. Day 10 needs 61 alerts in one day, right at iOS's limit of 64 pending notifications per app.

**Provenance:** popularized as the "Hit the Deck" program in The Modern Rogue episode 45 (Dec 23, 2016), which the d4rkd0s calculator (https://d4rkd0s.github.io/evilrussian/) credits. The same schedule appears in a 2013 blog post (https://lessthanhundredpercent.blogspot.com/2013/03/crazy-russian-push-up-program.html). Commonly linked to Pavel Tsatsouline; a primary source is not confirmed.

## User journey

Four short flows plus one browse screen; the set itself is a single tap. Each numbered item is one screen. Screen files are in `docs/screens/`.

**A. Commit (Day 0, under a minute)**
1. **The promise** (A1). "14 days. Your max goes up." One button: Start.
2. **Wake time** (A2). One time wheel, prefilled 7:00 a.m.
3. **Bedtime** (A3). One time wheel, prefilled 11:00 p.m. The app derives the last set (an hour before).
4. **Start day** (A4). Tomorrow morning (default) or Today.
5. **Allow alerts** (A5). Explains set alerts and the test-day alarm, then Apple's two prompts.
6. **Done** (A6). "Day 1 starts tomorrow at 7:00 with your test."

**B. Test (Days 1, 8 and 15)**
1. **Test alarm** (AlarmKit) at wake time: "Test day. As many as you can, good form." Opens the counter.
2. **Counter** (B2). Do the test, then set the number: slide a thumb up to add, down to subtract, haptic tick per rep, about 14pt of drag per rep. −1 and +1 buttons. Days 8 and 15 start at the previous max. Done.
3. **Confirm** (B3). "Your max: 50. Today: 15, every hour. First set at 8:05 a.m. Last set at 9:05 p.m. That's 14 sets." Start the day. (Recount link back to B2.)

Day 8 uses the new max for week 2. Day 15 ends in the result (flow E).

**C. The set (up to 61 times a day)** (C1, W1)
1. **Alert** on Watch and phone: "30 now", body "Set 6 of 21 · Day 3". Actions on the alert: Done, then In 10 min.
2. **Ignored alert:** the next set still comes on time; the missed one is logged quietly.

**D. Today (browse screen, the app's home)** (D-Today, W2)
- Next set and its time, large. Day progress (14 bars). Today's sets as marks: done, missed, current, to come. Total reps today.
- **Busy for 1 hour:** silences alerts for an hour; sets in that hour count as missed; the schedule resumes after.
- "Something hurts?" link to flow F.

**E. Day 15 result** (E1)
1. "Day 1 50 → Day 15 72", 14-day total, percent gain. Share (card image).
2. Run it again with the new max, or Done.

**F. Off-ramp** (F1)
1. "Something hurts?" Pause the program, or End it here. Progress is kept.

## v1 scope

| In v1 | Why |
| --- | --- |
| Flows A to F | They cover the whole 14 days |
| Schedule engine: RI, SF, waking window, rounding, Day 8 re-test | The math is the product |
| Alerts with Done and In 10 min on the alert itself | The set must take one tap |
| A rolling alert queue, topped up on every log and app open | Day 10 needs 61 alerts; iOS holds 64 at a time |
| Apple Watch app: next set, Done, alerts on the wrist | The wrist is where the set happens |
| Slide-to-set counter for tests (drag up or down, haptic tick per rep, ±1 buttons) | Fast to report a max after the set |
| Lock Screen and Home Screen widget: next set and time | Glanceable without opening the app |
| Result card to share | The Day 15 payoff people already post |
| On-device storage of every run | The record of before and after |

| Out of v1 | Why |
| --- | --- |
| Camera or motion rep counting | Hard to make reliable; the slide-to-set counter is enough |
| Apple Health workout logging | Not part of the core loop; v1.1 |
| Other programs (pull-ups, squats, Grease the Groove) | Prove one program first |
| Accounts, sync, leaderboards, friends | Server cost and privacy work for a 14-day app |
| iPad | Push-up sets do not happen at an iPad |
| Form coaching video | A link to a good form guide covers it |

## Platform check

| Mechanism | What the platform allows | What we do |
| --- | --- | --- |
| Pending notification limit | 64 pending requests per app, a system limit (Apple DTS, https://developer.apple.com/forums/thread/811171) | Schedule individual set alerts for the next slots, at most 60; top up on every log, app open and background refresh |
| Time Sensitive alerts | Break through Focus and the notification summary if the user allows; need the Time Sensitive capability; iOS asks the user the first time whether to keep allowing them | Every set alert is Time Sensitive; A5 says why |
| Actions on the alert | Actionable notifications respond without launching the app; the same buttons appear on a paired Apple Watch | One category with two actions: Done, then In 10 min |
| Apple Watch Double Tap | On Series 9 and Ultra 2, Double Tap on a notification runs the first nondestructive action | Done goes first, so a set can be logged with a pinch |
| Test-morning alarm | AlarmKit (iOS 26) alarms break through Silent and Focus with user consent, and surface on a paired Watch | Days 1, 8 and 15 open with an AlarmKit alarm at wake time; AlarmKit alarms do not use notification slots |

**Minimum iOS:** 26, for AlarmKit. Approved by Graham.

## Schedule engine spec

The engine is a pure function from (max, wake time, bedtime, start date, re-test setting, log) to a list of timed sets; everything else reads from it. Build it as a pure Swift package; it must pass every test case below.

**Rules**
1. **Reps** = RI × max, rounded up, at least 1. Compute in whole numbers: (max × RI% + 99) ÷ 100, integer division. Never multiply by a decimal; 100 × 0.55 comes out 56 in floating point.
2. **Window.** Last allowed set = bedtime minus 60 minutes. Sets fall on a grid: first set, then every SF minutes, until the last allowed time.
3. **First set.** Ordinary days: at wake time. Test days: one SF after the test is logged. Day 1 has no sets until the test is logged.
4. **Week 2 max.** Re-test on: the Day 8 result, even if lower. Re-test off, or Day 8 not logged by noon: the Day 1 max, and sets start at noon.
5. **Done** marks the set done with the planned reps. Logging a different count is not in v1.
6. **In 10 min** moves that one set 10 minutes later. Other sets stay on the grid. If the moved time reaches the next set's time, the set is marked missed.
7. **Busy for 1 hour** silences alerts from now for 60 minutes. Sets in that hour are marked missed; the grid resumes after.
8. **Missed.** A set not marked done by the next set's time, or by the end of the window, is missed. Missed sets never carry over or double up.
9. **Days** are calendar days in local time from the start date. If the time zone changes, the rest of the schedule is recomputed in local time.
10. **Mid-program changes** to wake time or bedtime apply from the next set, not retroactively.

**Alert queue**
- Keep at most 60 set alerts pending, soonest first. 4 slots stay free for the night-before and test-eve notes.
- Refill on every Done or In 10 min action, every app open, and every background refresh.
- Test mornings use AlarmKit, which does not use these slots.
- Known edge: on Day 10, if the user never touches an alert or the app all day, alert 61 can be lost. Accept for v1; log it.

**Test cases**

| # | Setup | Expected |
| --- | --- | --- |
| 1 | Max 50, Day 1, wake 7:00, bed 11:00 p.m., test logged 7:05 | 14 sets, 8:05 a.m. to 9:05 p.m., 15 reps each |
| 2 | Max 10, Day 4 (25%) | 3 reps (2.5 rounds up) |
| 3 | Max 100, Day 9 (55%) | 55 reps, not 56 |
| 4 | Max 50, Day 10 (every 15 min), wake 7:00, bed 11:00 p.m. | 61 sets, last at 10:00 p.m. |
| 5 | Day 14 (every 120 min), same window | 8 sets, last at 9:00 p.m. |
| 6 | Day 1 max 50, Day 8 re-test 62 | Day 9: 35 reps (34.1 rounds up) |
| 7 | Same, re-test off | Day 9: 28 reps |
| 8 | Day 10, set due 10:00, In 10 min | Alerts at 10:10; set due 10:15 unchanged |
| 9 | Same set, In 10 min a second time | 10:20 reaches the 10:15 set, so the 10:00 set is missed |
| 10 | Day 2 (hourly from 7:00), Busy for 1 hour at 1:20 p.m. | 2:00 set missed, no alert; 3:00 set alerts |
| 11 | Day 2, wake 5:30, bed 9:00 p.m. | 15 sets, 5:30 a.m. to 7:30 p.m. |
| 12 | Day 8 not logged by noon, re-test on | Week 2 uses the Day 1 max; sets start at noon |
| 13 | Day 10 queue at 6:59 a.m. | 60 alerts pending; the 10:00 p.m. alert is added at the first refill |

## Copy deck

Every line the app says. Short, plain, numbers first, never shaming. Brackets are filled by the engine.

**Voice rules:** the number leads; no exclamation marks; no streak or guilt language; a missed set is a fact, not a failure; no military phrasing.

| Where | Line |
| --- | --- |
| A1 promise, headline | 14 days. Your max goes up. |
| A1 promise, body | Tell it your max once. For two weeks, your phone and watch tell you when to drop and how many. One tap logs each set. |
| A1 health note | Shoulder, wrist or heart concerns? Check with a doctor first. |
| A2 wake time | When do you wake up? Your first set lands here. Test days start with an alarm at this time. |
| A3 bedtime | When do you go to bed? Your last set is an hour before. |
| A4 start day | When do you start? Tomorrow morning / Today |
| A5 alerts | Every set is an alert. No alerts, no program. |
| A5 Time Sensitive | Sets are due at a set time, so they come through Focus. You can change this in Settings. |
| A6 done | Day 1 starts [tomorrow] at [7:00] with your test. |
| Test alarm (AlarmKit) | Test day. As many as you can, good form. |
| B2 counter | How many did you do? Slide your thumb up or down to set the number. |
| B3 confirm | Your max: [50]. Today: [15], every [hour]. First set at [8:05 a.m.] Last set at [9:05 p.m.] That's [14] sets. |
| Set alert, title | [30] now |
| Set alert, body | Set [6] of [21] · Day [3] |
| Set alert, actions | Done / In 10 min |
| Today, next set | Next set at [10:45 a.m.] · [30] push-ups in [18] min |
| Today, tally | [4] of [21] done, [1] missed · [120] push-ups so far today |
| Busy for 1 hour, confirm | Alerts off until [2:20 p.m.] Sets in this hour count as missed. |
| Night before Day 9 | Tomorrow is the hard day: [46] sets of [28]. Sleep well. |
| Eve of Day 8 and 15 | Test tomorrow at [7:00]. |
| End of day | [16] of [16]. [400] push-ups today. |
| End of day, with misses | [13] of [16]. [325] push-ups today. Tomorrow starts fresh. |
| E1 result | Day 1 [50] → Day 15 [72] · [6,580] push-ups in 14 days · [+44%] on your max |
| E1 actions | Share / Run it again / Done |
| F1 something hurts | Something hurts? Sharp or joint pain is a reason to stop. Your progress is kept either way. |
| F1 options | Pause the program: No alerts until you resume. / End it here: Your days so far are saved. |
| Day 8 not logged by noon | No re-test today, so week 2 uses your Day 1 max. Sets start now. |

## Approved defaults

| Question | Decision |
| --- | --- |
| Alert style | Time Sensitive notifications with actions for each set; AlarmKit alarm on test mornings |
| "In 10 min" | Moves only that set |
| "Busy for 1 hour" | Silences alerts for an hour; those sets count as missed |
| Week 2 re-test | On by default |
| Day 9 and Day 10 load | As written, with a night-before note; no automatic cap |
| Health note | One plain line at setup |
| Pricing | Free for the first run's Days 1 to 3; one-time unlock $4.99 for the full program and every rerun. No subscription, no ads |
| Credit | Credit The Modern Rogue and the program's tradition in About, no claim of endorsement |
| iPhone without Apple Watch | Fully supported |

## Decision log

Newest first. All Nov 12, 2026.

| Decision | Why |
| --- | --- |
| Design system published (Chalk tokens, 7 components, icon) | Single reference for the build |
| App icon: h1-B, an orange chevron sitting just above a white 14 (Barlow Condensed 900) on black #121212, chevron the same width as the number | Graham's pick after four rounds |
| App Store Connect record: Rep Bell: 14-Day Push-Ups, Apple ID 6834201034, SKU repbell-ios; Health & Fitness, then Sports. Time Sensitive Notifications, App Groups and In-App Purchase on both App IDs. Nothing submitted; no build, pricing or availability. EU trader status not set | Grok's report |
| Name: Rep Bell. Bundle IDs com.grahamdeno.repbell and com.grahamdeno.repbell.watchkitapp; App Group group.com.grahamdeno.repbell | Only name that came back Clear |
| Test counter is slide-to-set; Days 8 and 15 start at the previous max | Graham: people report the count after the set |
| Brand direction: Chalk | Reads at a glance from the floor mid-set |
| Minimum iOS 26, AlarmKit for test mornings | The test is never slept through |
| "Busy for 1 hour" counts those sets as missed | Approved default |
| Concept, journey, v1 scope and defaults approved | Graham's review |

## Next steps

- [x] 1. Review concept, journey and defaults.
- [x] 2. Name and trademark check.
- [x] 3. Brand direction, screens and design system.
- [x] 4. App Store record and bundle IDs.
- [ ] 5. Repo and v1 build on a branch, with CI; schedule engine first with all 13 tests passing. Nothing merges until Graham says ship. Model: Sonnet.
- [ ] 6. Graham runs the full 14 days on TestFlight.
