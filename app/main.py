from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, Base
from app.routes.subjects import router as subject_router
from app.routes.flashcards import router as flashcard_router
from app.routes.stats import router as stats_router
from app.routes.media import router as media_router
from app.seed_bundled_decks import ensure_bundled_decks
from app.models import review as _review_model  # noqa: F401 — register ORM table


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(bind=engine)
    added = ensure_bundled_decks()
    if added:
        print(f"Seeded {added} bundled deck(s)")
    yield


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
