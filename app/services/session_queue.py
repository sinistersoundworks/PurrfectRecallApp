"""Build prioritized study queues."""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.flashcard import Flashcard
from app.services.fsrs_scheduler import predicted_recall_pct


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _overdue_days(card: Flashcard, now: datetime) -> float:
    due = _ensure_utc(card.due_date)
    if due > now:
        return 0.0
    return (now - due).total_seconds() / 86_400


def queue_priority(card: Flashcard, now: datetime) -> float:
    """Higher = study sooner. Weighted heuristic (Phase 2 v1)."""
    overdue = _overdue_days(card, now)
    recall = predicted_recall_pct(card, now)
    recall_gap = 1.0 - ((recall or 50.0) / 100.0)
    lapse_penalty = 0.5 if card.repetition >= 2 and overdue > 0 else 0.0
    new_card_boost = 0.3 if card.repetition == 0 else 0.0
    return overdue * 2.0 + recall_gap * 3.0 + lapse_penalty + new_card_boost


def build_study_queue(
    cards: list[Flashcard],
    *,
    limit: int = 50,
    interleave_decks: bool = True,
) -> list[Flashcard]:
    """Return cards ordered for study, with light deck interleaving."""
    now = datetime.now(timezone.utc)
    ranked = sorted(cards, key=lambda c: queue_priority(c, now), reverse=True)
    if not interleave_decks or len(ranked) <= 1:
        return ranked[:limit]

    result: list[Flashcard] = []
    pool = ranked[:]
    last_subject: int | None = None
    streak = 0

    while pool and len(result) < limit:
        picked_idx = 0
        if last_subject is not None and streak >= 3:
            alt = next((i for i, c in enumerate(pool) if c.subject_id != last_subject), None)
            if alt is not None:
                picked_idx = alt
        card = pool.pop(picked_idx)
        if card.subject_id == last_subject:
            streak += 1
        else:
            last_subject = card.subject_id
            streak = 1
        result.append(card)

    return result
