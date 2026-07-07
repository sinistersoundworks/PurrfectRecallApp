"""Deck weakness insights — retention, lapses, difficulty, trends, study timing."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from app.models.flashcard import Flashcard
from app.models.review import Review
from app.models.subject import Subject

MIN_REVIEWS_FOR_INSIGHT = 5
LAPSE_QUALITY_THRESHOLD = 3
ATTENTION_LAPSE_RATE = 25.0
ATTENTION_RETENTION = 55.0
TREND_DELTA_THRESHOLD = 5.0


@dataclass(frozen=True)
class DeckInsight:
    subject_id: int
    name: str
    retention_pct: float
    lapse_rate_pct: float | None
    avg_difficulty: float | None
    review_count: int
    needs_attention: bool
    trend: str
    study_tip: str | None


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _retention_pct(reviews: list[Review], cards: list[Flashcard]) -> float:
    if reviews:
        success = sum(1 for r in reviews if r.quality >= LAPSE_QUALITY_THRESHOLD)
        return round(100.0 * success / len(reviews), 1)
    learned = sum(1 for c in cards if c.repetition >= 1)
    return round(100.0 * learned / len(cards), 1) if cards else 0.0


def _lapse_rate_pct(reviews: list[Review]) -> float | None:
    if not reviews:
        return None
    lapses = sum(1 for r in reviews if r.quality < LAPSE_QUALITY_THRESHOLD)
    return round(100.0 * lapses / len(reviews), 1)


def _avg_difficulty(cards: list[Flashcard]) -> float | None:
    values = [c.memory_difficulty for c in cards if c.memory_difficulty is not None]
    if not values:
        return None
    return round(sum(values) / len(values), 2)


def _trend(reviews: list[Review], now: datetime) -> str:
    if len(reviews) < MIN_REVIEWS_FOR_INSIGHT:
        return "insufficient_data"

    today = _ensure_utc(now).date()
    recent_start = today - timedelta(days=7)
    prior_start = today - timedelta(days=14)

    recent = [r for r in reviews if recent_start <= _ensure_utc(r.reviewed_at).date() <= today]
    prior = [
        r
        for r in reviews
        if prior_start <= _ensure_utc(r.reviewed_at).date() < recent_start
    ]

    if len(recent) < 3 or len(prior) < 3:
        return "insufficient_data"

    recent_rate = sum(1 for r in recent if r.quality >= LAPSE_QUALITY_THRESHOLD) / len(recent)
    prior_rate = sum(1 for r in prior if r.quality >= LAPSE_QUALITY_THRESHOLD) / len(prior)
    delta = (recent_rate - prior_rate) * 100.0

    if delta >= TREND_DELTA_THRESHOLD:
        return "improving"
    if delta <= -TREND_DELTA_THRESHOLD:
        return "declining"
    return "stable"


def _study_tip_for_reviews(reviews: list[Review]) -> str | None:
    if len(reviews) < MIN_REVIEWS_FOR_INSIGHT:
        return None

    by_hour: dict[int, list[Review]] = {}
    for review in reviews:
        hour = _ensure_utc(review.reviewed_at).hour
        by_hour.setdefault(hour, []).append(review)

    best_hour: int | None = None
    best_rate = -1.0
    for hour, hour_reviews in by_hour.items():
        if len(hour_reviews) < 3:
            continue
        rate = sum(1 for r in hour_reviews if r.quality >= LAPSE_QUALITY_THRESHOLD) / len(
            hour_reviews
        )
        if rate > best_rate:
            best_rate = rate
            best_hour = hour

    if best_hour is None:
        return None

    label = f"{best_hour:02d}:00–{(best_hour + 1) % 24:02d}:00 UTC"
    return f"You recall best around {label}"


def build_deck_insights(
    subjects: list[Subject],
    cards: list[Flashcard],
    reviews: list[Review],
    now: datetime | None = None,
) -> list[DeckInsight]:
    now = now or datetime.now(timezone.utc)
    cards_by_subject: dict[int, list[Flashcard]] = {}
    reviews_by_subject: dict[int, list[Review]] = {}
    for card in cards:
        cards_by_subject.setdefault(card.subject_id, []).append(card)
    for review in reviews:
        reviews_by_subject.setdefault(review.subject_id, []).append(review)

    insights: list[DeckInsight] = []
    for subject in subjects:
        subject_cards = cards_by_subject.get(subject.id, [])
        subject_reviews = reviews_by_subject.get(subject.id, [])
        if not subject_cards:
            continue

        retention = _retention_pct(subject_reviews, subject_cards)
        lapse_rate = _lapse_rate_pct(subject_reviews)
        review_count = len(subject_reviews)
        needs_attention = review_count >= MIN_REVIEWS_FOR_INSIGHT and (
            (lapse_rate is not None and lapse_rate >= ATTENTION_LAPSE_RATE)
            or retention < ATTENTION_RETENTION
        )

        insights.append(
            DeckInsight(
                subject_id=subject.id,
                name=subject.name,
                retention_pct=retention,
                lapse_rate_pct=lapse_rate,
                avg_difficulty=_avg_difficulty(subject_cards),
                review_count=review_count,
                needs_attention=needs_attention,
                trend=_trend(subject_reviews, now),
                study_tip=_study_tip_for_reviews(subject_reviews),
            )
        )

    return sorted(insights, key=lambda item: item.retention_pct)


def pick_weakest(insights: list[DeckInsight]) -> DeckInsight | None:
    eligible = [i for i in insights if i.review_count >= MIN_REVIEWS_FOR_INSIGHT]
    return min(eligible, key=lambda i: i.retention_pct) if eligible else None


def pick_improving(insights: list[DeckInsight]) -> DeckInsight | None:
    improving = [i for i in insights if i.trend == "improving"]
    if not improving:
        return None
    return max(improving, key=lambda i: i.retention_pct)


def global_study_tip(insights: list[DeckInsight]) -> str | None:
    tips = [i.study_tip for i in insights if i.study_tip]
    return tips[0] if tips else None
