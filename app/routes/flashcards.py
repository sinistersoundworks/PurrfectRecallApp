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
    FlashcardReviewResult,
    FlashcardUpdate,
)
from app.services.fsrs_scheduler import predicted_recall_pct, schedule_review
from app.services.session_queue import build_study_queue

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


def _to_response(card: Flashcard) -> FlashcardResponse:
    data = FlashcardResponse.model_validate(card)
    return data.model_copy(
        update={"predicted_recall_pct": predicted_recall_pct(card)}
    )


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

    return _to_response(db_card)


@router.get("", response_model=list[FlashcardResponse])
def get_flashcards(
    subject_id: int | None = Query(None, description="Filter flashcards by subject id"),
    db: Session = Depends(get_db),
):
    query = db.query(Flashcard)
    if subject_id is not None:
        query = query.filter(Flashcard.subject_id == subject_id)
    cards = query.order_by(Flashcard.due_date).all()
    return [_to_response(card) for card in cards]


@router.get("/due", response_model=list[FlashcardResponse])
def get_due_flashcards(db: Session = Depends(get_db)):
    now = datetime.now(timezone.utc)
    cards = (
        db.query(Flashcard)
        .filter(Flashcard.due_date <= now)
        .order_by(Flashcard.due_date)
        .all()
    )
    return [_to_response(card) for card in cards]


@router.get("/study-queue", response_model=list[FlashcardResponse])
def get_study_queue(
    subject_id: int | None = Query(None, description="Limit queue to one deck"),
    limit: int = Query(50, ge=1, le=200),
    db: Session = Depends(get_db),
):
    """Prioritized study queue (FSRS retrievability + overdue weighting)."""
    now = datetime.now(timezone.utc)
    query = db.query(Flashcard)
    if subject_id is not None:
        query = query.filter(Flashcard.subject_id == subject_id)
    cards = query.filter(Flashcard.due_date <= now).all()
    if not cards and subject_id is not None:
        cards = query.all()
    ordered = build_study_queue(cards, limit=limit)
    return [_to_response(card) for card in ordered]


@router.get("/{flashcard_id}", response_model=FlashcardResponse)
def get_flashcard(flashcard_id: int, db: Session = Depends(get_db)):
    return _to_response(_get_card(db, flashcard_id))


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
    return _to_response(db_card)


@router.delete("/{flashcard_id}")
def delete_flashcard(flashcard_id: int, db: Session = Depends(get_db)):
    db_card = _get_card(db, flashcard_id)
    db.delete(db_card)
    db.commit()
    return {"message": "deleted"}


def _log_review(
    db: Session,
    card: Flashcard,
    review: FlashcardReview,
    predicted_before: float | None,
) -> None:
    db.add(
        Review(
            flashcard_id=card.id,
            subject_id=card.subject_id,
            quality=review.quality,
            confidence=review.confidence,
            response_ms=review.response_ms,
            session_id=review.session_id,
            predicted_recall_pct=predicted_before,
            reviewed_at=datetime.now(timezone.utc),
        )
    )


@router.post("/{flashcard_id}/review", response_model=FlashcardReviewResult)
def review_flashcard(
    flashcard_id: int,
    review: FlashcardReview,
    db: Session = Depends(get_db),
):
    card = _get_card(db, flashcard_id)
    card, predicted_before = schedule_review(card, review.quality)
    _log_review(db, card, review, predicted_before)

    db.commit()
    db.refresh(card)
    response = _to_response(card)
    return FlashcardReviewResult(
        card=response,
        predicted_recall_before_pct=predicted_before,
        predicted_recall_after_pct=response.predicted_recall_pct,
    )
