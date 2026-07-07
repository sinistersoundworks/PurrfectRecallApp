# FSRS scheduling

Purrfect Recall uses **[FSRS](https://github.com/open-spaced-repetition/fsrs4anki)** (via the `fsrs` Python package) as the primary scheduler. SM-2 columns (`interval`, `ease_factor`, `repetition`) are kept in sync for stats and legacy UI.

Implementation: `app/services/fsrs_scheduler.py` → `POST /flashcards/{id}/review`

---

## Quality → FSRS rating

The confidence slider still maps to SM-2 **quality** (0–5). The backend maps quality to FSRS ratings:

| Quality | FSRS rating |
|--------:|-------------|
| 0 | Again |
| 1–2 | Hard |
| 3 | Good |
| 4–5 | Easy |

See `docs/sm2-scheduling.md` for the confidence → quality mapping.

---

## Memory state on `flashcard`

| Column | Meaning |
|--------|---------|
| `memory_state` | FSRS `State` (Learning / Review / …) |
| `memory_step` | Learning step index |
| `memory_stability` | FSRS stability (days) |
| `memory_difficulty` | FSRS difficulty |

Legacy SM-2 cards are converted on first FSRS review.

---

## Predicted recall

`predicted_recall_pct` is **retrievability × 100** from FSRS at the current time, lightly adjusted by deck calibration when 30+ confidence-rated reviews exist:

- Returned on `GET /flashcards`, `GET /flashcards/study-queue`, and `POST …/review`
- `null` for cards never reviewed
- Calibration offset from `GET /stats/calibration` (see `app/services/calibration.py`)

---

## Confidence calibration

After **30+ reviews** with a confidence slider value, the API learns per-deck bias:

- `GET /stats/calibration?subject_id=` — overconfidence score, suggested offset, UI hint
- Predicted recall blends FSRS with up to ±25% offset (35% blend factor)
- Study UI shows hints like “You tend to overrate Spanish Essentials by ~12%”

---

## Study queue

`GET /flashcards/study-queue?subject_id=&limit=50` returns due cards ordered by:

1. Overdue severity  
2. Low predicted recall  
3. Light deck interleaving (no 4+ cards in a row from the same deck)

---

## Review payload (Phase 3 ready)

```json
{
  "quality": 4,
  "confidence": 72,
  "response_ms": 3200,
  "session_id": "optional-uuid"
}
```

`confidence` and timing fields are stored on the `review` row for calibration (see `docs/ml-roadmap.md`).

---

## Migration

```bash
uv run python scripts/add_fsrs_memory_columns.py
```

Run on existing `study.db` before upgrading the API.
