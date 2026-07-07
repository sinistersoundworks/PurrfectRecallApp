from pydantic import BaseModel


class ReviewDayCount(BaseModel):
    date: str
    count: int


class DeckStats(BaseModel):
    subject_id: int
    name: str
    total: int
    mastered: int
    due: int
    retention_pct: float


class StatsResponse(BaseModel):
    streak_days: int
    due_today: int
    cards_learned: int
    retention_pct: float
    avg_ease: float
    reviews_last_7_days: list[ReviewDayCount]
    deck_stats: list[DeckStats]
