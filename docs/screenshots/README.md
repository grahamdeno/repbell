# Rep Bell screenshots (current build)

Captured from the real app, built in Debug for the Simulator from `main` by `.github/workflows/screenshots.yml`
(`scripts/screenshots.sh`). Each state is reached with the Debug-only launch argument `-RBScreenshot <state>`, which
loads a seeded run in memory (nothing is saved) and opens one screen. The seeded runs are built relative to the
current time by `ScreenshotSeeds` in the engine, so the real schedule engine produces every number shown. The app's
time zone is set so local time is mid-afternoon. The status bar is overridden to 3:00.

Names: `<device>_<textsize>_<screen-state>.png`. 215 files.

Time zone for the app: Etc/GMT+6
watch41mm uses Apple Watch Series 9 (41mm)
watch45mm uses Apple Watch Series 9 (45mm)

| File | Device | Text size | Screen | State | How it was reached |
|---|---|---|---|---|---|
| `iphone16promax_ax5_about.png` | iPhone 16 Pro Max | AX5 (largest) | About | About | From Settings |
| `iphone16promax_ax5_alerts-check.png` | iPhone 16 Pro Max | AX5 (largest) | Alerts check | Diagnostics | From Settings |
| `iphone16promax_ax5_celebration-day.png` | iPhone 16 Pro Max | AX5 (largest) | Celebration | Finished day | Day 3 Today with the day celebration shown |
| `iphone16promax_ax5_celebration-set.png` | iPhone 16 Pro Max | AX5 (largest) | Celebration | After an in-app set | Day 3 Today with the set celebration shown |
| `iphone16promax_ax5_confirm.png` | iPhone 16 Pro Max | AX5 (largest) | Confirm | Test confirm (Recount is the link on this screen; it reopens the counter) | Day 1, 40 logged |
| `iphone16promax_ax5_counter-day8-high.png` | iPhone 16 Pro Max | AX5 (largest) | Counter | High number | Day 8 re-test, count 64 |
| `iphone16promax_ax5_counter-mid.png` | iPhone 16 Pro Max | AX5 (largest) | Counter | Mid-count | Day 1 test, count 23 |
| `iphone16promax_ax5_counter-zero.png` | iPhone 16 Pro Max | AX5 (largest) | Counter | At 0 | Day 1 test, count 0 |
| `iphone16promax_ax5_day-start.png` | iPhone 16 Pro Max | AX5 (largest) | Day start | Ring or Quiet choice | Day 9 run, no choice made today |
| `iphone16promax_ax5_desk-stretch.png` | iPhone 16 Pro Max | AX5 (largest) | Desk stretch | Start screen | Day 3 Today with the first stretch shown |
| `iphone16promax_ax5_fit-my-time.png` | iPhone 16 Pro Max | AX5 (largest) | Fit my time | Pick the minutes | From Workouts |
| `iphone16promax_ax5_fit-session.png` | iPhone 16 Pro Max | AX5 (largest) | Fit my time | A 15-minute session | Built from Fit my time |
| `iphone16promax_ax5_hurts.png` | iPhone 16 Pro Max | AX5 (largest) | Something hurts? | Pause and End options | Day 9 run |
| `iphone16promax_ax5_onboarding-alerts-denied.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Allow alerts, denied | Alerts-denied flag set |
| `iphone16promax_ax5_onboarding-alerts.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Allow alerts, not yet asked | No run stored; opened on the step |
| `iphone16promax_ax5_onboarding-bed.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Bedtime (step 3) | No run stored; opened on the step |
| `iphone16promax_ax5_onboarding-promise.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Promise (step 1) | No run stored |
| `iphone16promax_ax5_onboarding-ready.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Ready (step 5) | No run stored; opened on the step |
| `iphone16promax_ax5_onboarding-start.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Start day (step 4) | No run stored; opened on the step |
| `iphone16promax_ax5_onboarding-wake.png` | iPhone 16 Pro Max | AX5 (largest) | Onboarding | Wake time (step 2) | No run stored; opened on the step |
| `iphone16promax_ax5_paywall.png` | iPhone 16 Pro Max | AX5 (largest) | Paywall | Not reachable in 1.0 (nothing is locked); shown for the record | Opened directly |
| `iphone16promax_ax5_player.png` | iPhone 16 Pro Max | AX5 (largest) | Workouts player | Core, first step | Opened on the player |
| `iphone16promax_ax5_progress.png` | iPhone 16 Pro Max | AX5 (largest) | Progress | Partway through a run | Day 9, real-looking logs |
| `iphone16promax_ax5_rerun.png` | iPhone 16 Pro Max | AX5 (largest) | Run it again | Review screen | From the Day 15 result |
| `iphone16promax_ax5_result-ended.png` | iPhone 16 Pro Max | AX5 (largest) | Result | Ended early (Something hurts) | Run ended on Day 6 |
| `iphone16promax_ax5_result-final.png` | iPhone 16 Pro Max | AX5 (largest) | Result | End of a run | Day 15 final test logged, 40 to 58 |
| `iphone16promax_ax5_settings.png` | iPhone 16 Pro Max | AX5 (largest) | Settings | Top | Day 9 run |
| `iphone16promax_ax5_today-between-sets.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Between sets | Day 3, 4 sets done, next in 25 min |
| `iphone16promax_ax5_today-busy.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Busy active, Undo strip | Day 3, Busy tapped 5 min ago |
| `iphone16promax_ax5_today-day1-before-test.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Day 1 before the test | Run starts today, wake 2 hours ahead |
| `iphone16promax_ax5_today-day15.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Day 15 | Day 15, final test not logged |
| `iphone16promax_ax5_today-day8-test.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Day 8 test morning | Day 8, woke 30 min ago, re-test not logged |
| `iphone16promax_ax5_today-finished.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Day finished | Day 4, every set done, window closed |
| `iphone16promax_ax5_today-missed.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Some sets missed | Day 5, 3 of 7 sets missed |
| `iphone16promax_ax5_today-paused.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Paused | Day 6, paused an hour ago |
| `iphone16promax_ax5_today-set-due.png` | iPhone 16 Pro Max | AX5 (largest) | Today | Set due now | Day 3, wake 138 min ago, 3 sets done, the 4th due 3 min ago |
| `iphone16promax_ax5_workout-session.png` | iPhone 16 Pro Max | AX5 (largest) | Workouts session | Core | From Workouts |
| `iphone16promax_ax5_workout-settings.png` | iPhone 16 Pro Max | AX5 (largest) | Workouts settings | Gear, Go easy on, Health (replaces Coach settings) | From Workouts |
| `iphone16promax_ax5_workouts.png` | iPhone 16 Pro Max | AX5 (largest) | Workouts | List | Day 9 run (upper-body sessions under After Day 15) |
| `iphone16promax_default_about.png` | iPhone 16 Pro Max | Large (default) | About | About | From Settings |
| `iphone16promax_default_alerts-check.png` | iPhone 16 Pro Max | Large (default) | Alerts check | Diagnostics | From Settings |
| `iphone16promax_default_celebration-day.png` | iPhone 16 Pro Max | Large (default) | Celebration | Finished day | Day 3 Today with the day celebration shown |
| `iphone16promax_default_celebration-set.png` | iPhone 16 Pro Max | Large (default) | Celebration | After an in-app set | Day 3 Today with the set celebration shown |
| `iphone16promax_default_confirm.png` | iPhone 16 Pro Max | Large (default) | Confirm | Test confirm (Recount is the link on this screen; it reopens the counter) | Day 1, 40 logged |
| `iphone16promax_default_counter-day8-high.png` | iPhone 16 Pro Max | Large (default) | Counter | High number | Day 8 re-test, count 64 |
| `iphone16promax_default_counter-mid.png` | iPhone 16 Pro Max | Large (default) | Counter | Mid-count | Day 1 test, count 23 |
| `iphone16promax_default_counter-zero.png` | iPhone 16 Pro Max | Large (default) | Counter | At 0 | Day 1 test, count 0 |
| `iphone16promax_default_day-start.png` | iPhone 16 Pro Max | Large (default) | Day start | Ring or Quiet choice | Day 9 run, no choice made today |
| `iphone16promax_default_desk-stretch.png` | iPhone 16 Pro Max | Large (default) | Desk stretch | Start screen | Day 3 Today with the first stretch shown |
| `iphone16promax_default_fit-my-time.png` | iPhone 16 Pro Max | Large (default) | Fit my time | Pick the minutes | From Workouts |
| `iphone16promax_default_fit-session.png` | iPhone 16 Pro Max | Large (default) | Fit my time | A 15-minute session | Built from Fit my time |
| `iphone16promax_default_hurts.png` | iPhone 16 Pro Max | Large (default) | Something hurts? | Pause and End options | Day 9 run |
| `iphone16promax_default_onboarding-alerts-denied.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Allow alerts, denied | Alerts-denied flag set |
| `iphone16promax_default_onboarding-alerts.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Allow alerts, not yet asked | No run stored; opened on the step |
| `iphone16promax_default_onboarding-bed.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Bedtime (step 3) | No run stored; opened on the step |
| `iphone16promax_default_onboarding-promise.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Promise (step 1) | No run stored |
| `iphone16promax_default_onboarding-ready.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Ready (step 5) | No run stored; opened on the step |
| `iphone16promax_default_onboarding-start.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Start day (step 4) | No run stored; opened on the step |
| `iphone16promax_default_onboarding-wake.png` | iPhone 16 Pro Max | Large (default) | Onboarding | Wake time (step 2) | No run stored; opened on the step |
| `iphone16promax_default_paywall.png` | iPhone 16 Pro Max | Large (default) | Paywall | Not reachable in 1.0 (nothing is locked); shown for the record | Opened directly |
| `iphone16promax_default_player.png` | iPhone 16 Pro Max | Large (default) | Workouts player | Core, first step | Opened on the player |
| `iphone16promax_default_progress.png` | iPhone 16 Pro Max | Large (default) | Progress | Partway through a run | Day 9, real-looking logs |
| `iphone16promax_default_rerun.png` | iPhone 16 Pro Max | Large (default) | Run it again | Review screen | From the Day 15 result |
| `iphone16promax_default_result-ended.png` | iPhone 16 Pro Max | Large (default) | Result | Ended early (Something hurts) | Run ended on Day 6 |
| `iphone16promax_default_result-final.png` | iPhone 16 Pro Max | Large (default) | Result | End of a run | Day 15 final test logged, 40 to 58 |
| `iphone16promax_default_settings.png` | iPhone 16 Pro Max | Large (default) | Settings | Top | Day 9 run |
| `iphone16promax_default_today-between-sets.png` | iPhone 16 Pro Max | Large (default) | Today | Between sets | Day 3, 4 sets done, next in 25 min |
| `iphone16promax_default_today-busy.png` | iPhone 16 Pro Max | Large (default) | Today | Busy active, Undo strip | Day 3, Busy tapped 5 min ago |
| `iphone16promax_default_today-day1-before-test.png` | iPhone 16 Pro Max | Large (default) | Today | Day 1 before the test | Run starts today, wake 2 hours ahead |
| `iphone16promax_default_today-day15.png` | iPhone 16 Pro Max | Large (default) | Today | Day 15 | Day 15, final test not logged |
| `iphone16promax_default_today-day8-test.png` | iPhone 16 Pro Max | Large (default) | Today | Day 8 test morning | Day 8, woke 30 min ago, re-test not logged |
| `iphone16promax_default_today-finished.png` | iPhone 16 Pro Max | Large (default) | Today | Day finished | Day 4, every set done, window closed |
| `iphone16promax_default_today-missed.png` | iPhone 16 Pro Max | Large (default) | Today | Some sets missed | Day 5, 3 of 7 sets missed |
| `iphone16promax_default_today-paused.png` | iPhone 16 Pro Max | Large (default) | Today | Paused | Day 6, paused an hour ago |
| `iphone16promax_default_today-set-due.png` | iPhone 16 Pro Max | Large (default) | Today | Set due now | Day 3, wake 138 min ago, 3 sets done, the 4th due 3 min ago |
| `iphone16promax_default_workout-session.png` | iPhone 16 Pro Max | Large (default) | Workouts session | Core | From Workouts |
| `iphone16promax_default_workout-settings.png` | iPhone 16 Pro Max | Large (default) | Workouts settings | Gear, Go easy on, Health (replaces Coach settings) | From Workouts |
| `iphone16promax_default_workouts.png` | iPhone 16 Pro Max | Large (default) | Workouts | List | Day 9 run (upper-body sessions under After Day 15) |
| `iphonese3_ax3_about.png` | iPhone SE (3rd gen) | AX3 | About | About | From Settings |
| `iphonese3_ax3_alerts-check.png` | iPhone SE (3rd gen) | AX3 | Alerts check | Diagnostics | From Settings |
| `iphonese3_ax3_celebration-day.png` | iPhone SE (3rd gen) | AX3 | Celebration | Finished day | Day 3 Today with the day celebration shown |
| `iphonese3_ax3_celebration-set.png` | iPhone SE (3rd gen) | AX3 | Celebration | After an in-app set | Day 3 Today with the set celebration shown |
| `iphonese3_ax3_confirm.png` | iPhone SE (3rd gen) | AX3 | Confirm | Test confirm (Recount is the link on this screen; it reopens the counter) | Day 1, 40 logged |
| `iphonese3_ax3_counter-day8-high.png` | iPhone SE (3rd gen) | AX3 | Counter | High number | Day 8 re-test, count 64 |
| `iphonese3_ax3_counter-mid.png` | iPhone SE (3rd gen) | AX3 | Counter | Mid-count | Day 1 test, count 23 |
| `iphonese3_ax3_counter-zero.png` | iPhone SE (3rd gen) | AX3 | Counter | At 0 | Day 1 test, count 0 |
| `iphonese3_ax3_day-start.png` | iPhone SE (3rd gen) | AX3 | Day start | Ring or Quiet choice | Day 9 run, no choice made today |
| `iphonese3_ax3_desk-stretch.png` | iPhone SE (3rd gen) | AX3 | Desk stretch | Start screen | Day 3 Today with the first stretch shown |
| `iphonese3_ax3_fit-my-time.png` | iPhone SE (3rd gen) | AX3 | Fit my time | Pick the minutes | From Workouts |
| `iphonese3_ax3_fit-session.png` | iPhone SE (3rd gen) | AX3 | Fit my time | A 15-minute session | Built from Fit my time |
| `iphonese3_ax3_hurts.png` | iPhone SE (3rd gen) | AX3 | Something hurts? | Pause and End options | Day 9 run |
| `iphonese3_ax3_onboarding-alerts-denied.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Allow alerts, denied | Alerts-denied flag set |
| `iphonese3_ax3_onboarding-alerts.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Allow alerts, not yet asked | No run stored; opened on the step |
| `iphonese3_ax3_onboarding-bed.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Bedtime (step 3) | No run stored; opened on the step |
| `iphonese3_ax3_onboarding-promise.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Promise (step 1) | No run stored |
| `iphonese3_ax3_onboarding-ready.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Ready (step 5) | No run stored; opened on the step |
| `iphonese3_ax3_onboarding-start.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Start day (step 4) | No run stored; opened on the step |
| `iphonese3_ax3_onboarding-wake.png` | iPhone SE (3rd gen) | AX3 | Onboarding | Wake time (step 2) | No run stored; opened on the step |
| `iphonese3_ax3_paywall.png` | iPhone SE (3rd gen) | AX3 | Paywall | Not reachable in 1.0 (nothing is locked); shown for the record | Opened directly |
| `iphonese3_ax3_player.png` | iPhone SE (3rd gen) | AX3 | Workouts player | Core, first step | Opened on the player |
| `iphonese3_ax3_progress.png` | iPhone SE (3rd gen) | AX3 | Progress | Partway through a run | Day 9, real-looking logs |
| `iphonese3_ax3_rerun.png` | iPhone SE (3rd gen) | AX3 | Run it again | Review screen | From the Day 15 result |
| `iphonese3_ax3_result-ended.png` | iPhone SE (3rd gen) | AX3 | Result | Ended early (Something hurts) | Run ended on Day 6 |
| `iphonese3_ax3_result-final.png` | iPhone SE (3rd gen) | AX3 | Result | End of a run | Day 15 final test logged, 40 to 58 |
| `iphonese3_ax3_settings.png` | iPhone SE (3rd gen) | AX3 | Settings | Top | Day 9 run |
| `iphonese3_ax3_today-between-sets.png` | iPhone SE (3rd gen) | AX3 | Today | Between sets | Day 3, 4 sets done, next in 25 min |
| `iphonese3_ax3_today-busy.png` | iPhone SE (3rd gen) | AX3 | Today | Busy active, Undo strip | Day 3, Busy tapped 5 min ago |
| `iphonese3_ax3_today-day1-before-test.png` | iPhone SE (3rd gen) | AX3 | Today | Day 1 before the test | Run starts today, wake 2 hours ahead |
| `iphonese3_ax3_today-day15.png` | iPhone SE (3rd gen) | AX3 | Today | Day 15 | Day 15, final test not logged |
| `iphonese3_ax3_today-day8-test.png` | iPhone SE (3rd gen) | AX3 | Today | Day 8 test morning | Day 8, woke 30 min ago, re-test not logged |
| `iphonese3_ax3_today-finished.png` | iPhone SE (3rd gen) | AX3 | Today | Day finished | Day 4, every set done, window closed |
| `iphonese3_ax3_today-missed.png` | iPhone SE (3rd gen) | AX3 | Today | Some sets missed | Day 5, 3 of 7 sets missed |
| `iphonese3_ax3_today-paused.png` | iPhone SE (3rd gen) | AX3 | Today | Paused | Day 6, paused an hour ago |
| `iphonese3_ax3_today-set-due.png` | iPhone SE (3rd gen) | AX3 | Today | Set due now | Day 3, wake 138 min ago, 3 sets done, the 4th due 3 min ago |
| `iphonese3_ax3_workout-session.png` | iPhone SE (3rd gen) | AX3 | Workouts session | Core | From Workouts |
| `iphonese3_ax3_workout-settings.png` | iPhone SE (3rd gen) | AX3 | Workouts settings | Gear, Go easy on, Health (replaces Coach settings) | From Workouts |
| `iphonese3_ax3_workouts.png` | iPhone SE (3rd gen) | AX3 | Workouts | List | Day 9 run (upper-body sessions under After Day 15) |
| `iphonese3_ax5_about.png` | iPhone SE (3rd gen) | AX5 (largest) | About | About | From Settings |
| `iphonese3_ax5_alerts-check.png` | iPhone SE (3rd gen) | AX5 (largest) | Alerts check | Diagnostics | From Settings |
| `iphonese3_ax5_celebration-day.png` | iPhone SE (3rd gen) | AX5 (largest) | Celebration | Finished day | Day 3 Today with the day celebration shown |
| `iphonese3_ax5_celebration-set.png` | iPhone SE (3rd gen) | AX5 (largest) | Celebration | After an in-app set | Day 3 Today with the set celebration shown |
| `iphonese3_ax5_confirm.png` | iPhone SE (3rd gen) | AX5 (largest) | Confirm | Test confirm (Recount is the link on this screen; it reopens the counter) | Day 1, 40 logged |
| `iphonese3_ax5_counter-day8-high.png` | iPhone SE (3rd gen) | AX5 (largest) | Counter | High number | Day 8 re-test, count 64 |
| `iphonese3_ax5_counter-mid.png` | iPhone SE (3rd gen) | AX5 (largest) | Counter | Mid-count | Day 1 test, count 23 |
| `iphonese3_ax5_counter-zero.png` | iPhone SE (3rd gen) | AX5 (largest) | Counter | At 0 | Day 1 test, count 0 |
| `iphonese3_ax5_day-start.png` | iPhone SE (3rd gen) | AX5 (largest) | Day start | Ring or Quiet choice | Day 9 run, no choice made today |
| `iphonese3_ax5_desk-stretch.png` | iPhone SE (3rd gen) | AX5 (largest) | Desk stretch | Start screen | Day 3 Today with the first stretch shown |
| `iphonese3_ax5_fit-my-time.png` | iPhone SE (3rd gen) | AX5 (largest) | Fit my time | Pick the minutes | From Workouts |
| `iphonese3_ax5_fit-session.png` | iPhone SE (3rd gen) | AX5 (largest) | Fit my time | A 15-minute session | Built from Fit my time |
| `iphonese3_ax5_hurts.png` | iPhone SE (3rd gen) | AX5 (largest) | Something hurts? | Pause and End options | Day 9 run |
| `iphonese3_ax5_onboarding-alerts-denied.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Allow alerts, denied | Alerts-denied flag set |
| `iphonese3_ax5_onboarding-alerts.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Allow alerts, not yet asked | No run stored; opened on the step |
| `iphonese3_ax5_onboarding-bed.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Bedtime (step 3) | No run stored; opened on the step |
| `iphonese3_ax5_onboarding-promise.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Promise (step 1) | No run stored |
| `iphonese3_ax5_onboarding-ready.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Ready (step 5) | No run stored; opened on the step |
| `iphonese3_ax5_onboarding-start.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Start day (step 4) | No run stored; opened on the step |
| `iphonese3_ax5_onboarding-wake.png` | iPhone SE (3rd gen) | AX5 (largest) | Onboarding | Wake time (step 2) | No run stored; opened on the step |
| `iphonese3_ax5_paywall.png` | iPhone SE (3rd gen) | AX5 (largest) | Paywall | Not reachable in 1.0 (nothing is locked); shown for the record | Opened directly |
| `iphonese3_ax5_player.png` | iPhone SE (3rd gen) | AX5 (largest) | Workouts player | Core, first step | Opened on the player |
| `iphonese3_ax5_progress.png` | iPhone SE (3rd gen) | AX5 (largest) | Progress | Partway through a run | Day 9, real-looking logs |
| `iphonese3_ax5_rerun.png` | iPhone SE (3rd gen) | AX5 (largest) | Run it again | Review screen | From the Day 15 result |
| `iphonese3_ax5_result-ended.png` | iPhone SE (3rd gen) | AX5 (largest) | Result | Ended early (Something hurts) | Run ended on Day 6 |
| `iphonese3_ax5_result-final.png` | iPhone SE (3rd gen) | AX5 (largest) | Result | End of a run | Day 15 final test logged, 40 to 58 |
| `iphonese3_ax5_settings.png` | iPhone SE (3rd gen) | AX5 (largest) | Settings | Top | Day 9 run |
| `iphonese3_ax5_today-between-sets.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Between sets | Day 3, 4 sets done, next in 25 min |
| `iphonese3_ax5_today-busy.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Busy active, Undo strip | Day 3, Busy tapped 5 min ago |
| `iphonese3_ax5_today-day1-before-test.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Day 1 before the test | Run starts today, wake 2 hours ahead |
| `iphonese3_ax5_today-day15.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Day 15 | Day 15, final test not logged |
| `iphonese3_ax5_today-day8-test.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Day 8 test morning | Day 8, woke 30 min ago, re-test not logged |
| `iphonese3_ax5_today-finished.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Day finished | Day 4, every set done, window closed |
| `iphonese3_ax5_today-missed.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Some sets missed | Day 5, 3 of 7 sets missed |
| `iphonese3_ax5_today-paused.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Paused | Day 6, paused an hour ago |
| `iphonese3_ax5_today-set-due.png` | iPhone SE (3rd gen) | AX5 (largest) | Today | Set due now | Day 3, wake 138 min ago, 3 sets done, the 4th due 3 min ago |
| `iphonese3_ax5_workout-session.png` | iPhone SE (3rd gen) | AX5 (largest) | Workouts session | Core | From Workouts |
| `iphonese3_ax5_workout-settings.png` | iPhone SE (3rd gen) | AX5 (largest) | Workouts settings | Gear, Go easy on, Health (replaces Coach settings) | From Workouts |
| `iphonese3_ax5_workouts.png` | iPhone SE (3rd gen) | AX5 (largest) | Workouts | List | Day 9 run (upper-body sessions under After Day 15) |
| `iphonese3_default_about.png` | iPhone SE (3rd gen) | Large (default) | About | About | From Settings |
| `iphonese3_default_alerts-check.png` | iPhone SE (3rd gen) | Large (default) | Alerts check | Diagnostics | From Settings |
| `iphonese3_default_celebration-day.png` | iPhone SE (3rd gen) | Large (default) | Celebration | Finished day | Day 3 Today with the day celebration shown |
| `iphonese3_default_celebration-set.png` | iPhone SE (3rd gen) | Large (default) | Celebration | After an in-app set | Day 3 Today with the set celebration shown |
| `iphonese3_default_confirm.png` | iPhone SE (3rd gen) | Large (default) | Confirm | Test confirm (Recount is the link on this screen; it reopens the counter) | Day 1, 40 logged |
| `iphonese3_default_counter-day8-high.png` | iPhone SE (3rd gen) | Large (default) | Counter | High number | Day 8 re-test, count 64 |
| `iphonese3_default_counter-mid.png` | iPhone SE (3rd gen) | Large (default) | Counter | Mid-count | Day 1 test, count 23 |
| `iphonese3_default_counter-zero.png` | iPhone SE (3rd gen) | Large (default) | Counter | At 0 | Day 1 test, count 0 |
| `iphonese3_default_day-start.png` | iPhone SE (3rd gen) | Large (default) | Day start | Ring or Quiet choice | Day 9 run, no choice made today |
| `iphonese3_default_desk-stretch.png` | iPhone SE (3rd gen) | Large (default) | Desk stretch | Start screen | Day 3 Today with the first stretch shown |
| `iphonese3_default_fit-my-time.png` | iPhone SE (3rd gen) | Large (default) | Fit my time | Pick the minutes | From Workouts |
| `iphonese3_default_fit-session.png` | iPhone SE (3rd gen) | Large (default) | Fit my time | A 15-minute session | Built from Fit my time |
| `iphonese3_default_hurts.png` | iPhone SE (3rd gen) | Large (default) | Something hurts? | Pause and End options | Day 9 run |
| `iphonese3_default_onboarding-alerts-denied.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Allow alerts, denied | Alerts-denied flag set |
| `iphonese3_default_onboarding-alerts.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Allow alerts, not yet asked | No run stored; opened on the step |
| `iphonese3_default_onboarding-bed.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Bedtime (step 3) | No run stored; opened on the step |
| `iphonese3_default_onboarding-promise.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Promise (step 1) | No run stored |
| `iphonese3_default_onboarding-ready.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Ready (step 5) | No run stored; opened on the step |
| `iphonese3_default_onboarding-start.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Start day (step 4) | No run stored; opened on the step |
| `iphonese3_default_onboarding-wake.png` | iPhone SE (3rd gen) | Large (default) | Onboarding | Wake time (step 2) | No run stored; opened on the step |
| `iphonese3_default_paywall.png` | iPhone SE (3rd gen) | Large (default) | Paywall | Not reachable in 1.0 (nothing is locked); shown for the record | Opened directly |
| `iphonese3_default_player.png` | iPhone SE (3rd gen) | Large (default) | Workouts player | Core, first step | Opened on the player |
| `iphonese3_default_progress.png` | iPhone SE (3rd gen) | Large (default) | Progress | Partway through a run | Day 9, real-looking logs |
| `iphonese3_default_rerun.png` | iPhone SE (3rd gen) | Large (default) | Run it again | Review screen | From the Day 15 result |
| `iphonese3_default_result-ended.png` | iPhone SE (3rd gen) | Large (default) | Result | Ended early (Something hurts) | Run ended on Day 6 |
| `iphonese3_default_result-final.png` | iPhone SE (3rd gen) | Large (default) | Result | End of a run | Day 15 final test logged, 40 to 58 |
| `iphonese3_default_settings.png` | iPhone SE (3rd gen) | Large (default) | Settings | Top | Day 9 run |
| `iphonese3_default_today-between-sets.png` | iPhone SE (3rd gen) | Large (default) | Today | Between sets | Day 3, 4 sets done, next in 25 min |
| `iphonese3_default_today-busy.png` | iPhone SE (3rd gen) | Large (default) | Today | Busy active, Undo strip | Day 3, Busy tapped 5 min ago |
| `iphonese3_default_today-day1-before-test.png` | iPhone SE (3rd gen) | Large (default) | Today | Day 1 before the test | Run starts today, wake 2 hours ahead |
| `iphonese3_default_today-day15.png` | iPhone SE (3rd gen) | Large (default) | Today | Day 15 | Day 15, final test not logged |
| `iphonese3_default_today-day8-test.png` | iPhone SE (3rd gen) | Large (default) | Today | Day 8 test morning | Day 8, woke 30 min ago, re-test not logged |
| `iphonese3_default_today-finished.png` | iPhone SE (3rd gen) | Large (default) | Today | Day finished | Day 4, every set done, window closed |
| `iphonese3_default_today-missed.png` | iPhone SE (3rd gen) | Large (default) | Today | Some sets missed | Day 5, 3 of 7 sets missed |
| `iphonese3_default_today-paused.png` | iPhone SE (3rd gen) | Large (default) | Today | Paused | Day 6, paused an hour ago |
| `iphonese3_default_today-set-due.png` | iPhone SE (3rd gen) | Large (default) | Today | Set due now | Day 3, wake 138 min ago, 3 sets done, the 4th due 3 min ago |
| `iphonese3_default_workout-session.png` | iPhone SE (3rd gen) | Large (default) | Workouts session | Core | From Workouts |
| `iphonese3_default_workout-settings.png` | iPhone SE (3rd gen) | Large (default) | Workouts settings | Gear, Go easy on, Health (replaces Coach settings) | From Workouts |
| `iphonese3_default_workouts.png` | iPhone SE (3rd gen) | Large (default) | Workouts | List | Day 9 run (upper-body sessions under After Day 15) |
| `watch41mm_ax5_watch-between-sets.png` | Apple Watch 41 mm class | AX5 (largest) | Watch | Today, between sets | Same run as today-between-sets |
| `watch41mm_ax5_watch-busy.png` | Apple Watch 41 mm class | AX5 (largest) | Watch | Today, Busy active | Same run as today-busy |
| `watch41mm_ax5_watch-empty.png` | Apple Watch 41 mm class | AX5 (largest) | Watch | No run yet | No run seeded |
| `watch41mm_ax5_watch-finished.png` | Apple Watch 41 mm class | AX5 (largest) | Watch | Today, day finished | Same run as today-finished |
| `watch41mm_ax5_watch-set-due.png` | Apple Watch 41 mm class | AX5 (largest) | Watch | Set alert screen (a set due now) | Same run as today-set-due |
| `watch41mm_default_watch-between-sets.png` | Apple Watch 41 mm class | Large (default) | Watch | Today, between sets | Same run as today-between-sets |
| `watch41mm_default_watch-busy.png` | Apple Watch 41 mm class | Large (default) | Watch | Today, Busy active | Same run as today-busy |
| `watch41mm_default_watch-empty.png` | Apple Watch 41 mm class | Large (default) | Watch | No run yet | No run seeded |
| `watch41mm_default_watch-finished.png` | Apple Watch 41 mm class | Large (default) | Watch | Today, day finished | Same run as today-finished |
| `watch41mm_default_watch-set-due.png` | Apple Watch 41 mm class | Large (default) | Watch | Set alert screen (a set due now) | Same run as today-set-due |
| `watch45mm_ax5_watch-between-sets.png` | Apple Watch 45 mm class | AX5 (largest) | Watch | Today, between sets | Same run as today-between-sets |
| `watch45mm_ax5_watch-busy.png` | Apple Watch 45 mm class | AX5 (largest) | Watch | Today, Busy active | Same run as today-busy |
| `watch45mm_ax5_watch-empty.png` | Apple Watch 45 mm class | AX5 (largest) | Watch | No run yet | No run seeded |
| `watch45mm_ax5_watch-finished.png` | Apple Watch 45 mm class | AX5 (largest) | Watch | Today, day finished | Same run as today-finished |
| `watch45mm_ax5_watch-set-due.png` | Apple Watch 45 mm class | AX5 (largest) | Watch | Set alert screen (a set due now) | Same run as today-set-due |
| `watch45mm_default_watch-between-sets.png` | Apple Watch 45 mm class | Large (default) | Watch | Today, between sets | Same run as today-between-sets |
| `watch45mm_default_watch-busy.png` | Apple Watch 45 mm class | Large (default) | Watch | Today, Busy active | Same run as today-busy |
| `watch45mm_default_watch-empty.png` | Apple Watch 45 mm class | Large (default) | Watch | No run yet | No run seeded |
| `watch45mm_default_watch-finished.png` | Apple Watch 45 mm class | Large (default) | Watch | Today, day finished | Same run as today-finished |
| `watch45mm_default_watch-set-due.png` | Apple Watch 45 mm class | Large (default) | Watch | Set alert screen (a set due now) | Same run as today-set-due |

## Not captured here

- Lock Screen alert, expanded alert with Done and In 10 min, and the AlarmKit alarm screens: the Simulator can't
  produce them reliably. Capture them on a phone.
- Widgets (every family and state): the Simulator can't place a widget on the Home or Lock Screen from a script.
- Light mode: the app is dark only and doesn't respond to light mode, so there's no light set.
- Busy sheet, Coach settings, and the paywall as the Day 4 screen or from Workouts: these no longer exist in 1.0
  (Busy is one tap; coach media is out; nothing is locked). The paywall screen itself is shown for the record.
- Settings below the first screen, and the End confirmation under Something hurts: both need taps or scrolling,
  which the script doesn't do.

## Capture problems

- Simulator device failed to complete the requested operation.
- Simulator device failed to complete the requested operation.
- Simulator device failed to complete the requested operation.
- Simulator device failed to complete the requested operation.
- Simulator device failed to complete the requested operation.
- Simulator device failed to complete the requested operation.
