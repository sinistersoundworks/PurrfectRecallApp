# ML Roadmap — Purrfect Recall

Plan for features **1–11**, implemented in ROI order. Each phase builds on the `review` audit log and FSRS memory state on `flashcard`.

**Status key:** `planned` | `in_progress` | `shipped`

---

## Architecture target

```
Clients (Web / macOS / iOS)
        │
        ▼
FastAPI routes
        │
        ├── SchedulerService      ← FSRS (Phase 1)
        ├── SessionQueueService   ← smart ordering (Phase 2)
        ├── CalibrationService    ← confidence vs outcome (Phase 3)
        ├── InsightsService       ← deck weakness (Phase 4)
        ├── GenerationService     ← LLM decks (Phase 5)
        └── GradingService        ← typed/speech (Phase 6)
        │
        ▼
SQLite: flashcard (memory_*), review (quality, confidence, response_ms, session_id)
```

---

## Feature catalog (1–11)

### 1. FSRS scheduler + real predicted recall — `shipped`

**Goal:** Replace SM-2 as the primary scheduler; make “AI Predicted Recall” a real retrievability estimate.

| Area | Work |
|------|------|
| Backend | `app/services/fsrs_scheduler.py` using `fsrs` PyPI package |
| Schema | `memory_state`, `memory_step`, `memory_stability`, `memory_difficulty` on `flashcard` |
| API | `predicted_recall_pct` on card reads; `ReviewResult` on `POST …/review` |
| Migration | SM-2 cards converted on first FSRS review; `scripts/add_fsrs_memory_columns.py` |
| Clients | Swift + web consume API prediction instead of `55 + confidence × 0.2` |

**Acceptance:** After review, `due_date` follows FSRS; UI shows model retrievability before grading.

---

### 2. Smart session queue — `shipped` (v1)

**Goal:** Order today’s cards by learning value, not random shuffle.

**Scoring (v1 — weighted rules):**

```text
priority = w1 × overdue_days
         + w2 × (1 − predicted_recall)
         + w3 × lapse_rate
         + w4 × interleave_penalty(same_deck_streak)
```

| Area | Work |
|------|------|
| API | `GET /flashcards/study-queue?subject_id=&limit=30` |
| Backend | `app/services/session_queue.py` |
| Clients | `StudyViewModel.start()` uses study-queue instead of client-side shuffle |
| Logging | Optional `session_id` on reviews for A/B tuning later |

**Acceptance:** Queue surfaces hardest/overdue cards first; no more than 3 consecutive cards from same deck when studying “all due”.

---

### 3. Confidence calibration — `shipped`

**Goal:** Learn how each user’s slider maps to actual recall; improve predictions and nudges.

| Area | Work |
|------|------|
| Schema | `review.confidence` (0–100), `review.response_ms` |
| API | Accept `confidence` on `POST …/review` |
| Backend | `app/services/calibration.py` — per-user/deck logistic fit |
| API | `GET /stats/calibration` — overconfidence score, suggested offset |
| UI | Show “You tend to overrate this deck by ~12%” on study screen |

**Acceptance:** Calibration updates after 30+ reviews with confidence; predicted recall blends FSRS + calibration.

---

### 4. Deck weakness insights — `planned`

**Goal:** Dashboard tells users where they’re weak.

| Signals | Use |
|---------|-----|
| Deck retention % | Rank decks |
| Lapse rate | “Needs attention” badge |
| FSRS difficulty avg | Hard deck indicator |
| Time-of-day performance | Study timing tip |

| Area | Work |
|------|------|
| API | Extend `GET /stats` with `deck_insights[]` |
| Backend | `app/services/insights.py` |
| Clients | Dashboard cards: “Weakest deck”, “Improving deck” |

---

### 5. Optimal daily load — `shipped` (v1)

**Goal:** Replace scary due counts with a achievable daily target.

| Area | Work |
|------|------|
| Backend | `recommended_daily_reviews` from 7-day pace + backlog |
| API | Field on `GET /stats` |
| UI | Dashboard: “15 cards today keeps you on track” |
| Gamification | Daily challenges use recommended load as dynamic target |

---

### 6. Forgetting curve / retention forecast — `planned`

**Goal:** Stats view shows expected retention over next 7 days.

| Area | Work |
|------|------|
| Backend | Sum per-deck `R(t)` from FSRS stability |
| API | `GET /stats/forecast?days=7` |
| UI | Chart overlay on existing 7-day review chart |

---

### 7. LLM deck generation — `planned`

**Goal:** Topic → draft deck in seconds; human approves before study.

| Area | Work |
|------|------|
| API | `POST /decks/generate` `{ topic, count, style }` |
| API | `POST /decks/{id}/import-candidates` |
| Backend | `app/services/generation.py` — OpenAI/Anthropic adapter behind interface |
| UI | “Generate deck” sheet in Decks tab; staging list with approve/reject |
| Safety | Rate limit; no auto-add to study queue |

---

### 8. Mnemonic / example enrichment — `planned`

**Goal:** On-demand LLM suggestions for `example`, IPA, memory hook.

| Area | Work |
|------|------|
| API | `POST /flashcards/{id}/enrich` `{ fields: ["example","ipa"] }` |
| UI | “Suggest example” on card edit |
| Storage | Write only on user accept |

---

### 9. Typed-answer grading assist — `planned`

**Goal:** Optional type-the-answer mode with fuzzy + LLM fallback.

| v1 | Exact + Levenshtein for short answers |
| v2 | Embedding similarity (`sentence-transformers` small model) |
| v3 | LLM judge for long-form answers only |

| Area | Work |
|------|------|
| API | `POST /flashcards/{id}/grade` `{ user_answer }` → `{ correct, score, suggested_quality }` |
| UI | Study mode toggle: “Self-grade” / “Type answer” |
| ML | Start rule-based; add embeddings server-side |

---

### 10. Pronunciation scoring (Apple platforms) — `planned`

**Goal:** Speak-the-answer mode using on-device Speech framework.

| Area | Work |
|------|------|
| iOS/macOS | `Speech` framework — compare transcript to `question` / `ipa` |
| Kit | `SpeechGrader` in PurrfectRecallKit |
| API | Optional `POST …/review` with `pronunciation_score` for calibration |
| Privacy | On-device only; no audio uploaded |

---

### 11. Image → cards (OCR pipeline) — `planned`

**Goal:** Photo of textbook → draft flashcards.

| Pipeline | Vision OCR → LLM structuring → candidate cards |
| API | `POST /import/image` (multipart) |
| UI | Drag-and-drop on Decks |
| v1 | macOS/iOS only; server-side OCR later |

---

## Implementation phases (ROI order)

| Phase | Items | Est. effort | Status |
|-------|-------|-------------|--------|
| **1** | FSRS + predicted recall (#1) | 2–3 days | `shipped` |
| **2** | Smart queue (#2) + daily load (#5) | 2 days | `shipped` (v1 heuristics) |
| **3** | Confidence calibration (#3) | 1–2 days | `shipped` |
| **4** | Deck insights (#4) + forecast (#6) | 2 days | `planned` |
| **5** | LLM generation (#7) + enrichment (#8) | 3–4 days | `planned` |
| **6** | Typed grading (#9) + speech (#10) + OCR (#11) | 1–2 weeks | `planned` |

---

## Data contract (review log)

All ML features share one event shape:

```json
{
  "flashcard_id": 1,
  "quality": 4,
  "confidence": 72,
  "response_ms": 3400,
  "session_id": "uuid",
  "predicted_recall_pct": 68.2,
  "reviewed_at": "2026-07-07T20:00:00Z"
}
```

Phase 1 ships `quality` + `predicted_recall_pct`; later phases add fields incrementally.

---

## API additions summary

| Endpoint | Phase |
|----------|-------|
| `POST /flashcards/{id}/review` → `ReviewResult` | 1 |
| `GET /flashcards/study-queue` | 2 |
| `GET /stats` → `recommended_daily_reviews` | 2 |
| `POST /flashcards/{id}/review` + `confidence` | 3 |
| `GET /stats/calibration` | 3 |
| `GET /stats` → `deck_insights` | 4 |
| `GET /stats/forecast` | 6 |
| `POST /decks/generate` | 7 |
| `POST /flashcards/{id}/enrich` | 8 |
| `POST /flashcards/{id}/grade` | 9 |

---

## What we are not doing (yet)

- Custom neural scheduler before FSRS is tuned
- LLM auto-grading on every card (cost + latency)
- Server-side audio storage for pronunciation
- Full Anki `.apkg` import (separate project)

---

## Related docs

- `docs/sm2-scheduling.md` — legacy SM-2 spec (superseded by FSRS for scheduling)
- `docs/fsrs-scheduling.md` — FSRS mapping and quality → rating (Phase 1)
- `AGENTS.md` — agent conventions
