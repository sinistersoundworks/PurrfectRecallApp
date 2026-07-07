# SM-2 spaced repetition

Purrfect Recall uses the **SM-2** algorithm for scheduling flashcard reviews. SM-2 is simpler than FSRS but works well for an Anki-like MVP. The confidence slider in the Study UI maps to SM-2 quality scores so the scheduling engine can be swapped later (e.g. FSRS) without changing the UI.

Implementation: `app/routes/flashcards.py` → `_schedule_next_review()`

---

## Card state

Each flashcard stores its own scheduling fields:

| Field | Column | Meaning |
|-------|--------|---------|
| Interval | `interval` | Days until next review |
| Repetitions | `repetition` | Successful reviews in a row |
| Ease factor | `ease_factor` | How “easy” the card is (starts at 2.5) |
| Due date | `due_date` | Next review datetime |
| Last reviewed | `last_reviewed` | When the card was last graded |

**Brand-new card defaults:**

```
interval      = 0
repetition    = 0
ease_factor   = 2.5
due_date      = today (UTC)
```

---

## Review cycle

### Step 1 — User reviews the card

The user sees the question, reveals the answer, then grades recall.

Classic Anki uses four buttons mapped to SM-2 **quality** (0–5):

| Button | Quality |
|--------|--------:|
| Again | 0 |
| Hard | 3 |
| Good | 4 |
| Easy | 5 |

Purrfect Recall uses a **confidence slider** (0–100%) instead. The frontend converts it in `confidenceToSM2()` (`frontend/index.html`):

| Confidence | SM-2 quality |
|------------|-------------:|
| 0.0–0.2 | 0 |
| 0.2–0.4 | 2 |
| 0.4–0.6 | 3 |
| 0.6–0.8 | 4 |
| 0.8–1.0 | 5 |

The slider value is sent as `quality` in `POST /flashcards/{id}/review`.

---

### Step 2 — Update interval and repetitions

#### If quality &lt; 3 (forgot / poor recall)

```
repetition = 0
interval   = 1
```

The card is due again tomorrow.

#### If quality ≥ 3 (successful recall)

```
repetition += 1
```

Then set the interval:

| Repetition count | Interval |
|------------------|----------|
| 1st success | 1 day |
| 2nd success | 6 days |
| 3rd+ success | `round(interval × ease_factor)` |

Example for the 3rd+ success:

```
Current interval = 20 days
Ease factor      = 2.5
New interval     = 50 days
```

**Note:** For repetitions ≥ 3, the interval is multiplied by the ease factor **before** it is updated for this review (same ordering as the previous implementation).

---

### Step 3 — Update ease factor

After every review, SM-2 updates the ease factor:

```
EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
```

Where `EF` = ease factor, `q` = quality (0–5). The result is clamped to a minimum of **1.3**.

Examples starting from EF = 2.5:

| Grade | Quality | New ease |
|-------|--------:|---------:|
| Easy | 5 | ~2.60 |
| Good | 4 | ~2.50 |
| Hard | 3 | ~2.36 |
| Again | 0 | ~1.70 |

Lower ease → shorter future intervals. Higher ease → longer intervals.

---

### Step 4 — Schedule next review

```
due_date = now + interval days
last_reviewed = now
```

---

## Worked example

Starting with a new card, answering **Good** (quality 4) each time:

| Day | Event | Repetition | Interval | Next due |
|-----|-------|------------|----------|----------|
| 1 | New card | 0 | 0 | Day 1 |
| 1 | Good | 1 | 1 day | Day 2 |
| 2 | Good | 2 | 6 days | Day 8 |
| 8 | Good | 3 | 15 days | Day 23 |
| 23 | Good | 4 | 38 days | Day 61 |
| 61 | Good | 5 | 95 days | Day 156 |

(Interval growth depends on ease factor; values above assume EF ≈ 2.5.)

---

## API

```http
POST /flashcards/{id}/review
Content-Type: application/json

{ "quality": 4 }
```

`quality` must be an integer from 0 to 5 (validated by Pydantic).

Response includes updated `interval`, `ease_factor`, `repetition`, `due_date`, and `last_reviewed`.

---

## Study session behavior

When starting a study session (`frontend/index.html` → `startStudy()`):

1. Load all cards for the selected subject.
2. Prefer cards with `due_date <= now`.
3. If none are due, review all cards in the deck (cram mode).
4. Shuffle the queue.
5. After each confidence submission, call the review endpoint and advance to the next card.

---

## Future: FSRS

The confidence slider is intentionally decoupled from the scheduler. To adopt FSRS later:

1. Replace `_schedule_next_review()` (or move logic to a `services/` module).
2. Keep `POST /flashcards/{id}/review` and the slider UI.
3. Map confidence → FSRS rating internally.

Users keep the same study experience; only the interval math changes.

---

## Implementation checklist

| Spec item | Status |
|-----------|--------|
| Per-card `interval`, `repetition`, `ease_factor`, `due_date` | ✓ |
| New card defaults (0 / 0 / 2.5 / today) | ✓ |
| Reset on quality &lt; 3 | ✓ |
| Intervals 1 → 6 → × ease | ✓ |
| SM-2 ease formula on every review | ✓ |
| Confidence slider → quality mapping | ✓ |
| `due_date = now + interval` | ✓ |
