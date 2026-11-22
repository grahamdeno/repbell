# Rep Bell

Rep Bell runs the 14-day Evil Russian push-up program for you. Set your max once, and your phone and watch tell you when to drop and how many. One tap logs each set. This system is a dark ground, huge condensed numbers, lime for now and violet for earned.

## What the design is for

People read Rep Bell from the floor, mid-set, at arm's length, or from a wrist. The number always leads. Everything else is quiet so the number can be loud.

- **The number leads.** The next set's reps are the largest thing on any screen, in `volt`, set in `number-hero` (Barlow Condensed 800).
- **One color, one job.** `volt` means now: the next number, the primary button, the current set. `ultraviolet` means earned: finished days and the day total. White means done. Dashed gray means missed. Never use either color as decoration, and never put two primary buttons on a screen.
- **One decision per screen.** A flow screen has one choice or one tap. Browse screens (Today) may hold more, but the primary action is still singular.
- **Honest, never shaming.** A missed set is shown as a dashed outline in `ink-faint`, not red, not a broken streak.

## Voice

Short, plain, numbers first. No exclamation marks. No streaks, guilt or hype. No military phrasing.

- Do: "30 now." "Tomorrow is the hard day: 46 sets of 28." "13 of 16. Tomorrow starts fresh."
- Don't: "Crush it!" "You broke your streak." "Drop and give me 20."

Headlines and eyebrows are uppercase in the display face. Body copy is sentence case in Inter.

## Color

- One theme, Volt. The app is dark only.
- Screens sit on `ground`, and panels sit on `surface` with a `line` border.
- Text uses `ink` for numbers and headings and `ink-muted` for labels. `ink-faint` is for outlines only, never text.
- The primary button is a `volt` fill with `on-volt` text. Secondary buttons are transparent with a `line-strong` border and `ink` text.
- Set states: done is an `ink` fill, current is a `volt` fill, upcoming is a `line-strong` outline, and missed is a dashed `ink-faint` outline.
- Day bars: finished days are `ultraviolet`, today is `volt`, and upcoming days are `line`.
- Bell-ring flood: when a set's bell rings, the whole iPhone screen and the Watch set screen turn `volt`. The number and bell icon are `on-volt`, the eyebrow and caption are `on-volt-soft`, and the primary button is an `on-volt` fill with `volt` text. With Reduce Motion on, the flood shows with no animation.
- Day 15 is the only full `ultraviolet` flood.
- `alert` is only for destructive actions.
- The Watch uses `ground-watch` outside the flood.

## Type

Two families, both from Google Fonts in mockups; in the app, bundle Barlow Condensed and use SF Pro for body if Inter is not bundled.

- **Barlow Condensed** for numbers and uppercase headings: `number-hero` 200, `number-large` 150, `number-watch` 72, `headline` 48, `title` 28, `eyebrow` 22.
- **Inter** for everything read as sentences: `button` 18/600, `body` 17, `label` 15/500, `caption` 13. Nothing under 13px.

## Layout

iPhone screens are 390pt wide with `space-6` side margins and a `space-16` top inset. Primary actions sit at the bottom, full width, 60pt tall. Touch targets are at least 44pt; the counter panel fills the free height.

## Iconography

Inline stroke icons, 2 to 2.5pt strokes, round caps, in `volt`, `on-volt` or `ink-faint`. No emoji. The app icon is a black chevron sitting just above a black 14 on a volt square (art pending Graham's approval).

## Using this system

Rep Bell is a native SwiftUI app; there is no web bundle. Components here are reference previews: build them in SwiftUI from the tokens and the guideline in each component's README. Token names map one to one to the app's color and font assets.
