"""Confidence calibration — compare self-reported confidence to review outcomes."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy.orm import Session

from app.models.review import Review
from app.models.subject import Subject

MIN_REVIEWS = 30
MAX_OFFSET_APPLIED = 25.0
BLEND_FACTOR = 0.35
HINT_THRESHOLD = 5.0


@dataclass(frozen=True)
class CalibrationBucket:
    subject_id: int | None
    subject_name: str
    review_count: int
    ready: bool
    avg_confidence: float | None
    actual_recall_pct: float | None
    overconfidence_pct: float | None
    suggested_offset_pct: float | None
    hint: str | None


def _actual_success(quality: int) -> float:
    return 1.0 if quality >= 3 else 0.0


def _bucket_from_reviews(
    reviews: list[Review],
    *,
    subject_id: int | None,
    subject_name: str,
) -> CalibrationBucket:
    if not reviews:
        return CalibrationBucket(
            subject_id=subject_id,
            subject_name=subject_name,
            review_count=0,
            ready=False,
            avg_confidence=None,
            actual_recall_pct=None,
            overconfidence_pct=None,
            suggested_offset_pct=None,
            hint=None,
        )

    avg_confidence = sum(r.confidence for r in reviews) / len(reviews)
    actual_recall_pct = (
        sum(_actual_success(r.quality) for r in reviews) / len(reviews) * 100.0
    )
    overconfidence = avg_confidence - actual_recall_pct
    suggested_offset = max(-MAX_OFFSET_APPLIED, min(MAX_OFFSET_APPLIED, overconfidence))
    ready = len(reviews) >= MIN_REVIEWS
    hint = format_hint(subject_name, overconfidence) if ready else None

    return CalibrationBucket(
        subject_id=subject_id,
        subject_name=subject_name,
        review_count=len(reviews),
        ready=ready,
        avg_confidence=round(avg_confidence, 1),
        actual_recall_pct=round(actual_recall_pct, 1),
        overconfidence_pct=round(overconfidence, 1),
        suggested_offset_pct=round(suggested_offset, 1),
        hint=hint,
    )


def format_hint(deck_name: str, overconfidence_pct: float) -> str | None:
    label = deck_name if deck_name else "your decks"
    if overconfidence_pct >= HINT_THRESHOLD:
        return f"You tend to overrate {label} by ~{round(overconfidence_pct)}%"
    if overconfidence_pct <= -HINT_THRESHOLD:
        return f"You tend to underrate {label} by ~{round(abs(overconfidence_pct))}%"
    return f"Your self-ratings for {label} match outcomes well"


def build_calibration_snapshot(db: Session) -> dict[int | None, CalibrationBucket]:
    """Build global (None key) and per-deck calibration buckets."""
    reviews = (
        db.query(Review)
        .filter(Review.confidence.isnot(None))
        .all()
    )
    subjects = {s.id: s.name for s in db.query(Subject).all()}

    by_deck: dict[int, list[Review]] = {}
    for review in reviews:
        by_deck.setdefault(review.subject_id, []).append(review)

    snapshot: dict[int | None, CalibrationBucket] = {
        None: _bucket_from_reviews(reviews, subject_id=None, subject_name="all decks"),
    }
    for subject_id, deck_reviews in by_deck.items():
        snapshot[subject_id] = _bucket_from_reviews(
            deck_reviews,
            subject_id=subject_id,
            subject_name=subjects.get(subject_id, f"Deck {subject_id}"),
        )
    return snapshot


def adjust_predicted_recall(
    fsrs_pct: float | None,
    subject_id: int,
    snapshot: dict[int | None, CalibrationBucket],
) -> float | None:
    """Blend FSRS retrievability with deck calibration offset."""
    if fsrs_pct is None:
        return None

    bucket = snapshot.get(subject_id) or snapshot.get(None)
    if bucket is None or not bucket.ready or bucket.suggested_offset_pct is None:
        return fsrs_pct

    adjusted = fsrs_pct - (bucket.suggested_offset_pct * BLEND_FACTOR)
    return round(max(0.0, min(100.0, adjusted)), 1)


def deck_hint_for(
    snapshot: dict[int | None, CalibrationBucket],
    subject_id: int | None,
) -> str | None:
    if subject_id is not None:
        deck = snapshot.get(subject_id)
        if deck and deck.ready:
            return deck.hint
    global_bucket = snapshot.get(None)
    if global_bucket and global_bucket.ready:
        return global_bucket.hint
    return None
