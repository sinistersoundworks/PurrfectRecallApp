"""Seed bundled starter decks shipped with Purrfect Recall.

Deck definitions live in ``bundled_decks/decks.json``. On API startup we add any
bundled deck that is not already present (matched by name).
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models import review as _review_model  # noqa: F401 — register ORM relationships
from app.models.flashcard import Flashcard
from app.models.subject import Subject

ROOT = Path(__file__).resolve().parents[1]
BUNDLED_DECKS_PATH = ROOT / "bundled_decks" / "decks.json"

_CARD_FIELDS = (
    "example",
    "ipa",
    "image_path",
    "audio_word",
    "audio_meaning",
    "audio_example",
)


def load_bundled_decks() -> list[dict]:
    with BUNDLED_DECKS_PATH.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    return payload.get("decks", [])


def ensure_bundled_decks(db: Session | None = None) -> int:
    """Insert bundled decks missing from the database. Returns decks added."""
    owns_session = db is None
    session = db or SessionLocal()
    added = 0
    try:
        for deck_def in load_bundled_decks():
            name = deck_def["name"]
            if session.query(Subject).filter(Subject.name == name).first():
                continue
            subject = Subject(name=name, description=deck_def.get("description"))
            session.add(subject)
            session.flush()

            for card_def in deck_def.get("cards", []):
                card = Flashcard(
                    subject_id=subject.id,
                    question=card_def["question"],
                    answer=card_def["answer"],
                    due_date=datetime.now(timezone.utc),
                )
                for field in _CARD_FIELDS:
                    if value := card_def.get(field):
                        setattr(card, field, value)
                session.add(card)

            added += 1

        if added:
            session.commit()
        elif owns_session:
            session.rollback()
    except Exception:
        session.rollback()
        raise
    finally:
        if owns_session:
            session.close()
    return added


def bundled_deck_names() -> list[str]:
    return [deck["name"] for deck in load_bundled_decks()]
