"""FSRS scheduling for Purrfect Recall."""

from __future__ import annotations

from datetime import datetime, timezone

from fsrs import Card, Rating, Scheduler, State

from app.models.flashcard import Flashcard

_scheduler = Scheduler()


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def quality_to_rating(quality: int) -> Rating:
    """Map SM-2 quality (0–5) to FSRS rating."""
    if quality < 1:
        return Rating.Again
    if quality < 3:
        return Rating.Hard
    if quality < 4:
        return Rating.Good
    return Rating.Easy


def flashcard_to_fsrs_card(card: Flashcard) -> Card:
    """Build FSRS Card from ORM row, migrating legacy SM-2 state when needed."""
    if card.memory_stability is not None:
        return Card(
            card_id=card.id,
            state=State(card.memory_state),
            step=card.memory_step,
            stability=card.memory_stability,
            difficulty=card.memory_difficulty,
            due=_ensure_utc(card.due_date),
            last_review=_ensure_utc(card.last_reviewed) if card.last_reviewed else None,
        )

    fsrs_card = Card(card_id=card.id, due=_ensure_utc(card.due_date))

    if card.repetition <= 0:
        return fsrs_card

    if card.repetition >= 2 and card.interval > 0:
        fsrs_card.state = State.Review
        fsrs_card.stability = float(max(card.interval, 1))
        fsrs_card.difficulty = max(
            1.0,
            min(10.0, 11.0 - card.ease_factor * 2.0),
        )
        if card.last_reviewed:
            fsrs_card.last_review = _ensure_utc(card.last_reviewed)
        return fsrs_card

    fsrs_card.state = State.Learning
    fsrs_card.step = min(card.repetition, 2)
    if card.last_reviewed:
        fsrs_card.last_review = _ensure_utc(card.last_reviewed)
    return fsrs_card


def apply_fsrs_card_to_flashcard(card: Flashcard, fsrs_card: Card) -> None:
    """Persist FSRS state and mirror legacy SM-2 columns for stats/UI."""
    now = datetime.now(timezone.utc)
    due = _ensure_utc(fsrs_card.due)

    card.memory_state = int(fsrs_card.state)
    card.memory_step = fsrs_card.step
    card.memory_stability = fsrs_card.stability
    card.memory_difficulty = fsrs_card.difficulty
    card.due_date = due
    card.last_reviewed = (
        _ensure_utc(fsrs_card.last_review) if fsrs_card.last_review else now
    )

    delta_days = max(0, (due - now).total_seconds() / 86_400)
    card.interval = max(1, int(round(delta_days))) if delta_days >= 0.5 else 0

    if fsrs_card.difficulty is not None:
        card.ease_factor = max(1.3, min(3.0, (11.0 - fsrs_card.difficulty) / 2.0))

    if fsrs_card.state == State.Review and fsrs_card.stability and fsrs_card.stability > 0:
        card.repetition = max(card.repetition, 2)
    elif fsrs_card.state == State.Learning:
        card.repetition = max(1, (fsrs_card.step or 0) + 1)


def predicted_recall_pct(card: Flashcard, at: datetime | None = None) -> float | None:
    """Retrievability in [0, 100], or None for unseen cards."""
    at = at or datetime.now(timezone.utc)
    fsrs_card = flashcard_to_fsrs_card(card)
    if fsrs_card.last_review is None and fsrs_card.stability is None:
        return None
    retrievability = _scheduler.get_card_retrievability(fsrs_card, _ensure_utc(at))
    return round(max(0.0, min(1.0, retrievability)) * 100.0, 1)


def schedule_review(card: Flashcard, quality: int, at: datetime | None = None) -> tuple[Flashcard, float | None]:
    """Apply FSRS review; returns updated card and pre-review predicted recall %."""
    at = at or datetime.now(timezone.utc)
    at = _ensure_utc(at)
    fsrs_card = flashcard_to_fsrs_card(card)
    before = predicted_recall_pct(card, at)
    rating = quality_to_rating(quality)
    updated, _log = _scheduler.review_card(fsrs_card, rating, at)
    apply_fsrs_card_to_flashcard(card, updated)
    return card, before


def scheduler() -> Scheduler:
    return _scheduler
