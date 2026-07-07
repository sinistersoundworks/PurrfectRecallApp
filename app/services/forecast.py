"""Retention forecast from FSRS retrievability."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from app.models.flashcard import Flashcard
from app.services.fsrs_scheduler import predicted_recall_pct


@dataclass(frozen=True)
class ForecastPoint:
    date: str
    expected_retention_pct: float | None
    studied_card_count: int


def _studied_cards(cards: list[Flashcard]) -> list[Flashcard]:
    return [
        card
        for card in cards
        if card.repetition >= 1 or card.last_reviewed is not None or card.memory_stability
    ]


def build_retention_forecast(
    cards: list[Flashcard],
    *,
    days: int = 7,
    now: datetime | None = None,
) -> list[ForecastPoint]:
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)

    studied = _studied_cards(cards)
    points: list[ForecastPoint] = []

    for offset in range(days + 1):
        at = now + timedelta(days=offset)
        recalls = [predicted_recall_pct(card, at) for card in studied]
        valid = [value for value in recalls if value is not None]
        avg = round(sum(valid) / len(valid), 1) if valid else None
        points.append(
            ForecastPoint(
                date=at.date().isoformat(),
                expected_retention_pct=avg,
                studied_card_count=len(valid),
            )
        )

    return points
