# AGENTS.md — StudyWeb / AnkiLikeWeb

Instructions for AI agents (Cursor, Claude, etc.) working in this repository.

## What this project is

**StudyWeb** (repo name: AnkiLikeWeb) is a minimal spaced-repetition flashcard application:

- **Subjects** = decks (name + description)
- **Flashcards** = question/answer pairs belonging to a subject
- **Reviews** = SM-2 scheduling via `POST /flashcards/{id}/review`

There is **no user authentication on the backend** yet. The frontend simulates login/register in `localStorage` when `/auth/*` endpoints are absent.

---

## Architecture (current, not aspirational)

```
Browser (frontend/index.html)
    → fetch() → FastAPI (app/main.py)
                    → routes/ (subjects, flashcards)
                    → schemas/ (Pydantic validation)
                    → models/ (SQLAlchemy ORM)
                    → SQLite (study.db)
```

- **Backend entrypoint:** `app.main:app` (run with uvicorn, not root `main.py`)
- **Frontend:** static files under `frontend/` — **not** mounted by FastAPI; legacy dev UI. Primary UX: native SwiftUI apps in `apps/`
- **Database:** SQLite file at repo root; URL in `app/database.py`
- **Schema creation:** `Base.metadata.create_all()` on app startup (MVP — no Alembic)

Do **not** assume the richer layout shown in `app_scheme_images/SHOWCASES/` (React, FSRS service layer, auth middleware) exists unless you are explicitly building it.

---

## How to run

```bash
# Install
uv sync

# Backend + frontend together
./scripts/dev.sh
```

Or run separately:

```bash
# API (port 8000)
uv run uvicorn app.main:app --reload

# Frontend (separate terminal, port 5500)
cd frontend && python -m http.server 5500
```

Verify: `GET http://127.0.0.1:8000/` → `{"status":"ok"}`

---

## Code conventions

### Backend (Python)

| Area | Convention |
|------|------------|
| Routes | `APIRouter` in `app/routes/`, prefix `/subjects` or `/flashcards` |
| DB sessions | Inject via `Depends(get_db)` from `app/database.py` |
| Request bodies | Pydantic models in `app/schemas/` |
| ORM models | SQLAlchemy classes in `app/models/` |
| Errors | `HTTPException(status_code=404, …)` for missing resources |
| Private helpers | Leading underscore (e.g. `_get_card`, `_schedule_next_review`) |

When adding endpoints:

1. Add/update Pydantic schema in `app/schemas/`
2. Add route handler in `app/routes/`
3. Register router in `app/main.py` if new module
4. Add model fields in `app/models/` and migration script or `create_all` as appropriate

### Frontend (JavaScript)

- All logic is inline in `frontend/index.html` (no bundler, no modules)
- API base URL: `const API = "http://127.0.0.1:8000"`
- View switching via `showHome()`, `showStudy()`, `showDecks()` toggling `.hidden` on sections
- Study flow: `startStudy()` → `submitConfidence()` → `reviewCurrent()` → `POST …/review`

Match existing patterns (plain `fetch`, `alert()` for errors, no framework) unless the user requests a frontend rewrite.

### Database changes

- **New projects:** `create_all` on startup is enough
- **Existing `study.db`:** use or extend `scripts/add_flashcard_columns.py` for additive SQLite `ALTER TABLE` changes
- Do not commit `study.db` with sensitive data; it may exist locally

---

## Key files

| File | Role |
|------|------|
| `app/main.py` | FastAPI app, CORS, router includes, `create_all` |
| `app/database.py` | SQLite engine, `SessionLocal`, `get_db` |
| `app/routes/flashcards.py` | CRUD + SM-2 `_schedule_next_review` |
| `app/routes/stats.py` | Aggregated stats for native dashboard/stats views |
| `app/routes/subjects.py` | Subject CRUD |
| `app/models/flashcard.py` | Card + SRS fields (`interval`, `ease_factor`, `repetition`, `due_date`) |
| `app/models/review.py` | Review audit log (one row per graded review) |
| `apps/StudyWebKit/` | Shared SwiftUI library (design system, API client, views) |
| `apps/StudyWeb.xcodeproj` | Native macOS + iOS app targets |
| `frontend/index.html` | Legacy browser UI |

---

## SM-2 review contract

See **`docs/sm2-scheduling.md`** for the full algorithm, worked examples, and FSRS migration notes.

`POST /flashcards/{id}/review` body: `{ "quality": 0–5 }`

Frontend maps confidence slider (0–100%) in `confidenceToSM2()`:

| Confidence | Quality |
|------------|--------:|
| &lt; 20% | 0 |
| 20–40% | 2 |
| 40–60% | 3 |
| 60–80% | 4 |
| ≥ 80% | 5 |

Preserve this mapping unless changing both frontend and `docs/sm2-scheduling.md`.

---

## Known gaps (from codebase)

- **Stats view** — native apps implement full stats; web `showStats()` is still a stub
- **Auth** — frontend only; no `/auth` routes on backend
- **Edit button** — noted in `app/ToDoList.txt` as needing a fix
- **Debug prints** — `print("MAIN LOADED")` etc. in main and subjects routes
- **CORS** — `allow_origins=["*"]` — fine for local dev, tighten for production
- **Frontend XSS risk** — card text interpolated into `innerHTML` without escaping in some places; use `escapeJs()` pattern when touching edit flows

---

## What agents should do

- Keep changes **minimal and focused** — this is a small MVP
- Match existing layering: routes → schemas → models
- Run the API after backend changes: `uv run uvicorn app.main:app --reload`
- Update `README.md` when adding endpoints or changing setup
- Use `uv` for dependency and run commands (`uv sync`, `uv run …`)

## What agents should not do

- Do not introduce heavy frameworks without user request
- Do not replace `create_all` with Alembic unless asked
- Do not mount the frontend in FastAPI unless asked (currently served separately)
- Do not commit `.DS_Store`, `__pycache__/`, or `.venv/`
- Do not create git commits unless the user explicitly asks

---

## Testing changes manually

1. Start API and frontend (see above)
2. **My Decks** — create a subject, add flashcards
3. **Study** — start session, reveal answer, submit confidence
4. Confirm `due_date` advances via `GET /flashcards?subject_id=…` or Swagger UI at `/docs`

---

## Related docs

- `README.md` — user-facing setup, API table, architecture diagrams
- `docs/sm2-scheduling.md` — SM-2 algorithm spec, confidence mapping, FSRS migration path
- `docs/native-apps.md` — native macOS/iOS apps, design tokens, build/run
- `app/ToDoList.txt` — maintainer TODO notes
- `app_scheme_images/` — future architecture reference (not current code)
