# Native Purrfect Recall Apps (macOS + iOS)

Purrfect Recall ships native SwiftUI clients that implement the **BlackCat Audio** redesign from `design_handoff_flashcard_app_ui/`. Both apps share one library (`PurrfectRecallKit`) and talk to the existing FastAPI backend.

## Architecture

```
apps/
├── PurrfectRecall.xcodeproj   # macOS + iOS app targets
├── PurrfectRecallMac/         # macOS @main entry
├── PurrfectRecallIOS/         # iOS @main entry
└── PurrfectRecallKit/         # Shared Swift package
    ├── DesignSystem/       # BlackCat tokens + BC* components
    ├── API/                # URLSession client + DTOs
    ├── Domain/             # SM-2 mapping, deck colors, card status
    ├── ViewModels/         # Dashboard, Study, Decks, Stats
    └── Views/              # Shared + Mac + iOS layouts
```

**Backend dependency:** run `./scripts/dev.sh` (or `uv run uvicorn app.main:app --reload`) so the API is available at `http://127.0.0.1:8000`.

Native apps also use:

- `GET /stats` — dashboard + stats aggregates (requires `review` table; run `uv run python scripts/add_review_table.py` on existing DBs)
- All existing `/subjects` and `/flashcards` routes

## Design fidelity

Tokens are ported from:

- `design_handoff_flashcard_app_ui/tokens/colors.css`
- `design_handoff_flashcard_app_ui/tokens/typography.css`
- `design_handoff_flashcard_app_ui/tokens/spacing.css`
- `design_handoff_flashcard_app_ui/tokens/effects.css`

Layouts follow the desktop (sidebar) and mobile (bottom tab bar) prototypes in the handoff README — two purpose-built layouts, not one responsive reflow.

## Menu bar quick study (macOS)

**PurrfectRecallMac** includes a menu bar extra (cat icon) with a popover window for studying without opening the main app window:

- Pick a deck or tap **Quick Study** (auto-selects the deck with the most due cards)
- Full review flow: reveal answer → confidence slider → submit
- Shares `AppState` with the main app (XP, combos, daily challenges, celebrations)
- **Open App** in the footer brings up the main window if needed

Requires the API at the configured base URL (default `http://127.0.0.1:8000`).

## Gamification (XP, achievements, Game Center)

- **XP & levels** — earned on every review; combo multiplier for strong recalls; level titles (Curious Cat → Legendary Learner)
- **Achievements** — Trophy Room tab (`AppTab.achievements`); ~35 badges (streaks, combos, review/level/XP milestones, daily streaks, early bird / night owl)
- **Daily challenges** — 3 per day (deterministic pool from date); progress on dashboard and Trophy Room; bonus XP on completion; +25 XP when all 3 done; daily streak tracked
- **Celebrations** — popup after each card with XP gained, combo, level-up, daily challenge completions, and unlocks; uses SwiftUI `sensoryFeedback`
- **GameKit** — `GameCenterService` reports scores to leaderboards and unlocks `GKAchievement` when signed in
- **Local fallback** — progress persists in `UserDefaults` even without Game Center

For App Store builds, enable `apps/PurrfectRecall.entitlements` (`com.apple.developer.game-center`) in Xcode Signing & Capabilities and configure matching leaderboard/achievement IDs in App Store Connect (`purrfectrecall.leaderboard.*`, `purrfectrecall.achievement.*`).

## Stats definitions (v1)

| Metric | Rule |
|--------|------|
| Due | `due_date <= now` |
| Mastered | `repetition >= 2` |
| Learning | `repetition == 1` |
| Cards learned | `repetition >= 1` |
| Retention % | reviews with `quality >= 3` / all reviews |
| Streak | consecutive UTC days with ≥1 review |
| Deck color | palette index from `subject_id` (client-side) |

Each review via `POST /flashcards/{id}/review` appends a row to the `review` audit log.

## SM-2 + confidence slider

Same mapping as the web MVP and `docs/sm2-scheduling.md`:

| Confidence | Quality |
|------------|--------:|
| 0–19% | 0 |
| 20–39% | 2 |
| 40–59% | 3 |
| 60–79% | 4 |
| 80–100% | 5 |

**AI Predicted Recall** in Study is presentation-only: `55 + confidence × 0.2` until a real model exists.

## Build and run

### Prerequisites

- Xcode 15+ (project targets macOS 14 / iOS 17)
- Backend running on port 8000

### macOS

```bash
cd apps
xcodegen generate   # if project.yml changed
open PurrfectRecall.xcodeproj
# Select scheme "PurrfectRecallMac" → Run
```

Or from CLI:

```bash
cd apps
xcodebuild -scheme PurrfectRecallMac -destination 'platform=macOS' build
```

### iOS

Open `apps/PurrfectRecall.xcodeproj`, select **PurrfectRecallIOS**, run on simulator or device.

Or from CLI (iPhone simulator):

```bash
cd apps
xcodebuild -scheme PurrfectRecallIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build/DerivedData build

# Install + launch on booted simulator
xcrun simctl install booted build/DerivedData/Build/Products/Debug-iphonesimulator/PurrfectRecallIOS.app
xcrun simctl launch booted com.purrfectrecall.ios
```

**API URL on a physical iPhone:** open Settings (⚙ in the nav/footer) and set the base URL to your Mac's LAN address, e.g. `http://192.168.1.10:8000`. The simulator can use `http://127.0.0.1:8000` (same as macOS).

### Regenerate Xcode project

After editing `apps/project.yml`:

```bash
cd apps && xcodegen generate
```

## Manual test checklist

1. Start API: `./scripts/dev.sh`
2. Run PurrfectRecallMac — app shows as **Purrfect Recall**; Dashboard shows streak/due/deck grid
3. Decks — create deck, add cards, edit/delete via sheets
4. Study — reveal answer, adjust confidence, submit; verify card schedules
5. Stats — 7-day bar chart increments after reviews
6. PurrfectRecallIOS — tab bar navigation, deck drill-down (`‹ All Decks`)
7. Settings — change API URL, confirm requests hit new host

## Web frontend

The vanilla `frontend/index.html` remains for quick browser testing. Native apps are the primary UI for the redesign.
