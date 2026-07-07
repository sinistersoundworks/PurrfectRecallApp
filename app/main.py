from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routes.subjects import router as subject_router
from app.routes.flashcards import router as flashcard_router
from app.routes.stats import router as stats_router
from app.routes.media import router as media_router
from app.models import review as _review_model  # noqa: F401 — register ORM table

print("MAIN LOADED")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("REGISTERING ROUTER")
app.include_router(subject_router)
app.include_router(flashcard_router)
app.include_router(stats_router)
app.include_router(media_router)
print("ROUTER REGISTERED")
print(app.routes)

@app.get("/")
def root():
    return {"status": "ok"}


# vytvoří tabulky při startu (MVP přístup)
Base.metadata.create_all(bind=engine)