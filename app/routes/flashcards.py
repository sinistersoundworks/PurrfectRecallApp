from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.flashcard import Flashcard
from app.models.review import Review
from app.models.subject import Subject
from app.schemas.flashcard import (
    FlashcardCreate,
    FlashcardResponse,
    FlashcardReview,
    FlashcardUpdate,
)

router = APIRouter(prefix="/flashcards", tags=["Flashcards"])


def _get_card(db: Session, flashcard_id: int) -> Flashcard:
    card = db.query(Flashcard).filter(Flashcard.id == flashcard_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Flashcard not found")
    return card


def _validate_subject(db: Session, subject_id: int) -> Subject:
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    return subject


@router.post("", response_model=FlashcardResponse)
def create_flashcard(card: FlashcardCreate, db: Session = Depends(get_db)):
    _validate_subject(db, card.subject_id)

    db_card = Flashcard(
        subject_id=card.subject_id,
        question=card.question,
        answer=card.answer,
        example=card.example,
        ipa=card.ipa,
        image_path=card.image_path,
        audio_word=card.audio_word,
        audio_meaning=card.audio_meaning,
        audio_example=card.audio_example,
    )

    db.add(db_card)
    db.commit()
    db.refresh(db_card)

    return db_card


@router.get("", response_model=list[FlashcardResponse])
def get_flashcards(
    subject_id: int | None = Query(None, description="Filter flashcards by subject id"),
    db: Session = Depends(get_db),
):
    query = db.query(Flashcard)
    if subject_id is not None:
        query = query.filter(Flashcard.subject_id == subject_id)
    return query.order_by(Flashcard.due_date).all()


@router.get("/due", response_model=list[FlashcardResponse])
def get_due_flashcards(db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    cards = (
        db.query(Flashcard)
        .filter(Flashcard.due_date <= now)
        .order_by(Flashcard.due_date)
        .all()
    )
    return cards


@router.get("/{flashcard_id}", response_model=FlashcardResponse)
def get_flashcard(flashcard_id: int, db: Session = Depends(get_db)):
    return _get_card(db, flashcard_id)


@router.put("/{flashcard_id}", response_model=FlashcardResponse)
def update_flashcard(
    flashcard_id: int,
    patch: FlashcardUpdate,
    db: Session = Depends(get_db),
):
    db_card = _get_card(db, flashcard_id)
    if patch.subject_id is not None and patch.subject_id != db_card.subject_id:
        _validate_subject(db, patch.subject_id)
        db_card.subject_id = patch.subject_id

    if patch.question is not None:
        db_card.question = patch.question
    if patch.answer is not None:
        db_card.answer = patch.answer
    if patch.example is not None:
        db_card.example = patch.example
    if patch.ipa is not None:
        db_card.ipa = patch.ipa
    if patch.image_path is not None:
        db_card.image_path = patch.image_path
    if patch.audio_word is not None:
        db_card.audio_word = patch.audio_word
    if patch.audio_meaning is not None:
        db_card.audio_meaning = patch.audio_meaning
    if patch.audio_example is not None:
        db_card.audio_example = patch.audio_example

    db.commit()
    db.refresh(db_card)
    return db_card


@router.delete("/{flashcard_id}")
def delete_flashcard(flashcard_id: int, db: Session = Depends(get_db)):
    db_card = _get_card(db, flashcard_id)
    db.delete(db_card)
    db.commit()
    return {"message": "deleted"}


def _schedule_next_review(card: Flashcard, quality: int) -> None:
    """Apply SM-2 scheduling. See docs/sm2-scheduling.md."""
    now = datetime.now(timezone.utc)

    if quality < 3:
        card.repetition = 0
        card.interval = 1
    else:
        card.repetition += 1
        if card.repetition == 1:
            card.interval = 1
        elif card.repetition == 2:
            card.interval = 6
        else:
            card.interval = max(1, round(card.interval * card.ease_factor))

    # SM-2 ease factor formula (applied after every review)
    ease = card.ease_factor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
    card.ease_factor = max(1.3, ease)

    card.last_reviewed = now
    card.due_date = now + timedelta(days=card.interval)


def _log_review(db: Session, card: Flashcard, quality: int) -> None:
    db.add(
        Review(
            flashcard_id=card.id,
            subject_id=card.subject_id,
            quality=quality,
            reviewed_at=datetime.now(timezone.utc),
        )
    )


@router.post("/{flashcard_id}/review", response_model=FlashcardResponse)
def review_flashcard(
    flashcard_id: int,
    review: FlashcardReview,
    db: Session = Depends(get_db),
):
    card = _get_card(db, flashcard_id)
    _schedule_next_review(card, review.quality)
    _log_review(db, card, review.quality)

    db.commit()
    db.refresh(card)
    return card
