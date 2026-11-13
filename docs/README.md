# Rep Bell docs

Everything the build needs, exported from Graham's private Claude artifacts so any agent can read it here.

- `plan.md` — the plan: Start here, journey, v1 scope, Platform check, Schedule engine spec (13 test cases), Copy deck, Decision log, Next steps. Read this first.
- `design-system/` — Chalk design system. Start with `design-system/README.md` (brand book), then `tokens.json` (colors, type, spacing, radii). `components/<Name>/README.md` has build notes for each component; `preview.html` shows it (previews expect the token CSS variables, so open them for reference, not as finished pages).
- `screens/` — the approved screens as HTML artboards (390×844 iPhone, 198×242 Watch). File names match the journey: A1 to A6 setup, B2 counter, B3 confirm, C1 Lock Screen alert and widget, D-Today, E1 result, F1 something hurts, W1 and W2 Watch. `Icon-h1-B.dc.html` is the chosen icon at 512px. These use a small runtime (`support.js`) from Claude's design canvas, so they will not run as-is in a browser; read the markup for layout, sizes, colors and copy. `B2-Counter` contains the slide-to-set logic.
- `icon/rep-bell-icon.svg` — the h1-B app icon at 1024. The 14 is live text in Barlow Condensed 900; convert it to outlines before exporting the shipping PNG.

**Do not merge, ship to TestFlight or submit anything until Graham says ship.**
