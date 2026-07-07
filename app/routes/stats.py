from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.flashcard import Flashcard
from app.models.review import Review
from app.models.subject import Subject
from app.schemas.stats import DeckStats, ReviewDayCount, StatsResponse

router = APIRouter(prefix="/stats", tags=["Stats"])


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _is_due(due_date: datetime | None, now: datetime) -> bool:
    if due_date is None:
        return False
    return _ensure_utc(due_date) <= now

def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _utc_date(dt: datetime) -> datetime.date:
    return _ensure_utc(dt).date()


def _compute_streak(review_dates: set[datetime.date], today: datetime.date) -> int:
    streak = 0
    day = today
    while day in review_dates:
        streak += 1
        day -= timedelta(days=1)
    return streak


@router.get("", response_model=StatsResponse)
def get_stats(db: Session = Depends(get_db)):
    now = _utc_now()
    today = _utc_date(now)

    cards = db.query(Flashcard).all()
    reviews = db.query(Review).all()
    subjects = db.query(Subject).all()

    due_today = sum(1 for c in cards if _is_due(c.due_date, now))
    cards_learned = sum(1 for c in cards if c.repetition >= 1)
    avg_ease = round(sum(c.ease_factor for c in cards) / len(cards), 2) if cards else 2.5

    if reviews:
        successful = sum(1 for r in reviews if r.quality >= 3)
        retention_pct = round(100.0 * successful / len(reviews), 1)
    else:
        learned = [c for c in cards if c.repetition >= 1]
        retention_pct = round(100.0 * len(learned) / len(cards), 1) if cards else 0.0

    review_dates = {_utc_date(r.reviewed_at) for r in reviews}
    streak_days = _compute_streak(review_dates, today)

    day_counts: dict[str, int] = defaultdict(int)
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        day_counts[day.isoformat()] = 0
    for review in reviews:
        key = _utc_date(review.reviewed_at).isoformat()
        if key in day_counts:
            day_counts[key] += 1
    reviews_last_7_days = [
        ReviewDayCount(date=date, count=count)
        for date, count in day_counts.items()
    ]

    deck_stats: list[DeckStats] = []
    for subject in subjects:
        subject_cards = [c for c in cards if c.subject_id == subject.id]
        subject_reviews = [r for r in reviews if r.subject_id == subject.id]
        total = len(subject_cards)
        mastered = sum(1 for c in subject_cards if c.repetition >= 2)
        due = sum(1 for c in subject_cards if _is_due(c.due_date, now))
        if subject_reviews:
            sub_retention = round(
                100.0 * sum(1 for r in subject_reviews if r.quality >= 3) / len(subject_reviews),
                1,
            )
        else:
            learned = sum(1 for c in subject_cards if c.repetition >= 1)
            sub_retention = round(100.0 * learned / total, 1) if total else 0.0

        deck_stats.append(
            DeckStats(
                subject_id=subject.id,
                name=subject.name,
                total=total,
                mastered=mastered,
                due=due,
                retention_pct=sub_retention,
            )
        )

    seven_day_total = sum(day_counts.values())
    daily_pace = max(5, int(round(seven_day_total / 7))) if seven_day_total else 15
    if due_today > 0:
        recommended_daily = min(due_today, max(daily_pace, 15))
    else:
        recommended_daily = daily_pace

    return StatsResponse(
        streak_days=streak_days,
        due_today=due_today,
        cards_learned=cards_learned,
        retention_pct=retention_pct,
        avg_ease=avg_ease,
        recommended_daily_reviews=recommended_daily,
        reviews_last_7_days=reviews_last_7_days,
        deck_stats=deck_stats,
    )
