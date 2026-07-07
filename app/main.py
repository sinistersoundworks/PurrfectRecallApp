from contextlib import asynccontextmanager
import atexit
import os
import signal
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, Base
from app.routes.subjects import router as subject_router
from app.routes.flashcards import router as flashcard_router
from app.routes.stats import router as stats_router
from app.routes.media import router as media_router
from app.seed_bundled_decks import ensure_bundled_decks
from app.models import review as _review_model  # noqa: F401 — register ORM table

_TRACE_PATH = Path(__file__).resolve().parent.parent / ".dev" / "api-trace.log"


def _api_trace(message: str) -> None:
    _TRACE_PATH.parent.mkdir(parents=True, exist_ok=True)
    from datetime import datetime, timezone

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    line = f"[{ts}] PYTHON pid={os.getpid()} {message}\n"
    with _TRACE_PATH.open("a", encoding="utf-8") as f:
        f.write(line)


def _on_signal(signum: int, _frame) -> None:
    try:
        name = signal.Signals(signum).name
    except ValueError:
        name = str(signum)
    _api_trace(f"SIGNAL {name} ({signum}) — shutting down")
    raise SystemExit(128 + signum)


for _sig in (signal.SIGTERM, signal.SIGINT):
    signal.signal(_sig, _on_signal)

atexit.register(lambda: _api_trace("atexit — process ending"))


@asynccontextmanager
async def lifespan(_app: FastAPI):
    _api_trace("lifespan START")
    Base.metadata.create_all(bind=engine)
    added = ensure_bundled_decks()
    if added:
        print(f"Seeded {added} bundled deck(s)")
    yield
    _api_trace("lifespan STOP")


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(subject_router)
app.include_router(flashcard_router)
app.include_router(stats_router)
app.include_router(media_router)


@app.get("/")
def root():
    return {"status": "ok"}
