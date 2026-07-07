# Handoff: Purrfect Recall — Flashcard App UI Redesign

## Overview
A redesigned desktop and mobile UI for **Purrfect Recall** (the flashcard/spaced-repetition app in the `AnkiLikeWeb` repo — FastAPI backend, vanilla HTML/CSS/JS frontend). This redesign keeps the app's existing feature set (Home/Dashboard, Study session, Deck + card management, Stats) but reskins it in a dark, dense, "pro tool" visual language, and adds three new surfaces the current MVP doesn't have: deck progress/streaks on the dashboard, a searchable card browser per deck, and a stats screen with charts.

## About the Design Files
The files in this bundle (`Flashcard App - Desktop.dc.html`, `Flashcard App - Mobile.dc.html`) are **design references built in HTML** — interactive prototypes showing intended layout, styling, and behavior. They are **not production code to copy directly**: they use a proprietary component-streaming format (custom `<x-dc>`/`<x-import>` tags, a `support.js` runtime) that only exists in the design tool that produced them and will not run as-is in a normal app.

**The task is to recreate these designs in the target codebase's real environment** — today that's the vanilla HTML/CSS/JS frontend in `AnkiLikeWeb/frontend/`, talking to the existing FastAPI routes. If/when the frontend is rebuilt in a framework (React, Vue, etc.), recreate the same designs there instead using that framework's normal patterns — don't try to run the `.dc.html` files directly.

To read the actual layout/markup/values, open the files as text — every style is inline (no external stylesheet to trace), so each element's CSS is visible right on the tag.

## Fidelity
**High-fidelity.** Every color, spacing value, radius, and font is a real design-system token (see Design Tokens below) — implement pixel-for-pixel. Copy text is final. Demo data (deck names, card counts, stats numbers) is illustrative — wire it to the real API in `AnkiLikeWeb/app/routes/`.

## Design System
Visual language: **BlackCat Audio** — a dark, dense, "pro audio tool" aesthetic (near-black surfaces, amber accent, IBM Plex Sans/Mono, small radii, high-contrast shadows, no gradients/emoji/decoration). Token source files are included in `tokens/` in this folder — pull hex/px values directly from there rather than re-deriving them. If the frontend already has a CSS variable system, map 1:1 onto these; otherwise these `:root` files can be dropped in wholesale.

## Screens / Views

Both Desktop and Mobile share 4 views, switched via left sidebar (desktop) or bottom tab bar (mobile): **Dashboard, Study, Decks, Stats**.

### 1. Dashboard (Home)
- **Purpose:** at-a-glance status — streak, due count, cards learned, retention — and a deck grid to jump into study or a specific deck.
- **Desktop layout:** content area padding 28px/32px, header row (greeting + date/due summary left, "Start Study" primary button right), 4-column stat card grid (gap 14px), then a 3-column deck card grid (gap 14px).
- **Mobile layout:** padding 18px/16px, 2-column stat card grid, full-width "Start Study" button, single-column deck list.
- **Stat cards:** BlackCat `Card` component, `padding="md"`/`"sm"`, label = 10/9px uppercase `--fg-3`, value = mono, 28px desktop / 20px mobile, `--fg-1` (or `--accent`/`--color-active` for streak/retention).
- **Deck card:** raised surface (`--bg-raised`, 1px `--border-default`, `--radius-md`), 8px color-coded square dot + deck name (13/12px, `--fg-1`) + optional amber "N due" pill (`--accent-dim` bg, `--accent` text, `--radius-full`), description (11px `--fg-3`), then a 4px/thin progress bar (deck color fill on `--bg-control` track) with a mono `mastered/total` readout.

### 2. Study (review session)
- **Purpose:** run a spaced-repetition review session for a chosen deck.
- **Top bar:** deck `Select` + Start/Stop `Button` + right-aligned mono progress readout ("CARD 3 OF 12" desktop, "3 / 12" mobile).
- **Card:** centered, `--bg-raised`, `--radius-lg`, `--shadow-lg`, generous padding (48/40 desktop, 32/24 mobile). Question shown first (22/17px, `--fg-1`); "Show Answer" secondary button; once revealed, a divider then the answer in `--color-info`.
- **Confidence panel** (shown only once revealed), in a second card below: an **AI Predicted Recall** meter (BlackCat `Meter`, horizontal, cyan/info-tinted via its own zone coloring) — this is a **new, ML-flavored addition**: instead of a plain 0–100% self-report slider only, the UI now also surfaces a model-predicted recall probability alongside the user's own confidence `Slider`. Submit button advances to the next card (or ends the session).
- **Behavior:** identical review flow to the current app (reveal → confidence → submit → next card), just restyled and with the added prediction readout. Wire the slider's value into the same SM-2 quality mapping the backend already does (`confidenceToSM2` in the current `frontend/index.html`) — the predicted-recall number is presentation only unless/until an actual model is wired up; treat it as a computed placeholder (`~55 + confidence×0.2`) until real ML scoring exists.

### 3. Decks (deck + card management, with search/filter — new)
- **Purpose:** browse/search decks, manage a deck's cards, add new flashcards.
- **Desktop layout:** two-pane — left rail (340px, deck search `Input` + "New Deck" button + scrollable deck list, each row showing color dot, name, card count), right pane (deck header + description + streak/mastered readout, an "Add Flashcard" `Card` with two `Input`s + Add `Button`, then the card list — each row: question/answer preview + a status pill (DUE / LEARNING / MASTERED, amber/warn/active colors respectively) + Edit/Delete buttons).
- **Mobile layout:** single-pane, drill-down navigation — deck list view (search input on top, tappable rows with a `›` chevron) → tapping a deck opens its detail view (a "‹ All Decks" back row, then the same add-card form and card list, stacked full-width).
- **New vs. current app:** current app has flat, unfiltered subject/flashcard lists with prompt()-based edit and no search. This redesign adds the search input, per-card status pills, and a proper master–detail structure — same underlying CRUD operations (create/edit/delete subject, create/edit/delete flashcard).

### 4. Stats (new — was a placeholder alert in the current app)
- **Purpose:** surface the learning data the backend already tracks (interval/ease/repetition/due_date) that today goes unused in the UI.
- **Layout:** top stat-card row (Longest Streak, Cards Learned, Retention, Avg. Ease — desktop only shows Avg. Ease card; mobile shows Streak + Retention), a "Reviews — Last 7 Days" bar chart card (7 vertical bars, amber fill, height ∝ count, mono count readout above each bar, uppercase day label below), and a "Deck Retention" card listing each deck as a color dot + name + thin retention progress bar + mono percentage.
- **Implementation note:** the bar chart and retention bars are plain divs sized by percentage — no charting library needed, keep it that simple in the real implementation too (consistent with the DS's "no decorative illustration" rule).

## Interactions & Behavior
- **Navigation:** desktop = persistent left sidebar (icon + label rows, active row gets amber-tinted background + left accent border); mobile = bottom tab bar (4 tabs, active tab's icon chip turns solid amber, label turns amber + semibold).
- **Deck selection:** clicking/tapping a deck card/row anywhere (Dashboard or Decks list) opens that deck's detail in the Decks view.
- **Study flow state machine:** `idle → studying(revealed:false) → studying(revealed:true) → (next card | session end)`. Stop button or reaching the end of the queue returns to idle.
- **Hover/press states:** follow BlackCat Audio conventions — hover lightens background one step (`--bg-control-hover`), press darkens, no scale transforms, disabled = 0.4 opacity. Buttons/inputs are the DS's own components — don't restyle them.
- **Transitions:** 80ms for hover/color changes, 150ms for pressed/active state, per the DS's `--ease-fast`/`--ease-normal` tokens.
- **Responsive:** these are two distinct, purpose-built layouts (not one fluid breakpoint set) — desktop uses a sidebar + multi-column grids; mobile uses a bottom tab bar + single-column stacks and drill-down navigation for Decks. Implement them as separate layouts/components sharing the same design tokens and data layer, not as a CSS-media-query reflow of one markup tree.

## State Management
Per view, the state the prototype models (map onto real API calls where noted):
- **Dashboard:** streak count, due-today count, cards-learned count, retention % (derive from `/flashcards` + `/flashcards/due`), deck list with per-deck mastered/total/due/streak/color.
- **Study:** selected deck id, session queue (array of due cards, shuffled — same logic as current `startStudy()`), current index, revealed boolean, confidence (0–100, drives SM-2 quality via the existing `confidenceToSM2` mapping), predicted-recall number (placeholder formula noted above).
- **Decks:** search text, selected/open deck id, new-card form fields (question/answer) — wire to existing `POST /flashcards`, `PUT/DELETE /flashcards/{id}`, `POST/PUT/DELETE /subjects`.
- **Stats:** last-7-days review counts (would need a new backend aggregation — currently not exposed by any route; either add one or compute client-side from flashcard `last_reviewed` timestamps), per-deck retention (define as % of reviews with quality ≥ 3, or reuse `ease_factor` as a proxy — needs a product decision).

## Design Tokens
See `tokens/*.css` in this folder for the full, authoritative token set. Highlights:
- **Backgrounds:** `--bg-base #090909`, `--bg-raised #111111`, `--bg-elevated #181818`, `--bg-control #1c1c1c` (+ hover `#222`, active `#282828`, pressed `#0d0d0d`)
- **Accent:** `--accent #f08c0a` (hover `#f5a128`, pressed `#cc7808`) — used sparingly (2–3 instances/screen)
- **Semantic:** active/green `#34d058`, danger/red `#f05050`, warn/amber `#f0b030`, info/cyan `#38c4f0`
- **Text:** `--fg-1 #f2f2f2` (primary), `--fg-2 #a4a4a4` (secondary/labels), `--fg-3 #5c5c5c` (placeholder/tertiary), `--fg-4 #343434` (hairline)
- **Fonts:** UI = IBM Plex Sans (300/400/500/600), Mono = IBM Plex Mono (400/500) — mono is used for every number (counts, percentages, dates). Both via Google Fonts.
- **Type scale:** 9–38px named steps (`--text-2xs` … `--text-4xl`); control labels are ALL CAPS + `0.08em` letter-spacing.
- **Spacing:** 4px base unit (`--space-1` = 4px … `--space-24` = 96px); dense control gaps of 4–8px, section gaps of 16–24px.
- **Radii:** 2px (chips/segments) → 3px (buttons/inputs) → 4px (cards) → 6–8px (floating panels) → pill (9999px). Never exceed 12px anywhere.
- **Shadows/glow:** see `tokens/effects.css` — dark-mode shadows run 0.55–0.80 opacity; amber glow (`--glow-accent`) reserved for active states, not decoration.

## Assets
No custom illustration or icon assets are used in these two screens — icons are single Unicode glyphs (⌂ ▶ ▤ ▥ ›) consistent with the DS's "no icon font, no emoji" rule, plus one inline SVG (status-bar signal bars on mobile, copied verbatim from the DS's own iOS starting point). The DS's brand mascot (`kitty.png`) is not used here — a flashcard app has no natural place for a DAW mascot; flag to the design system owner if brand presence here is desired.

## Files
- `Flashcard App - Desktop.dc.html` — 1440×900 desktop design (Dashboard/Study/Decks/Stats), sidebar nav.
- `Flashcard App - Mobile.dc.html` — 390×844 mobile design (same 4 views), bottom tab bar, drill-down deck detail.
- `tokens/colors.css`, `tokens/typography.css`, `tokens/spacing.css`, `tokens/effects.css` — the authoritative BlackCat Audio design tokens referenced throughout.

For the **current, pre-redesign** app structure (routes, data model, SM-2 scheduling), see the `AnkiLikeWeb` repo's own `README.md` and `frontend/index.html` / `frontend/styles.css` — this handoff assumes that backend is unchanged except where Stats/search require new aggregation endpoints (noted above).
