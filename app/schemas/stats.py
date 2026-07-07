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
    recommended_daily_reviews: int
    reviews_last_7_days: list[ReviewDayCount]
    deck_stats: list[DeckStats]


class DeckCalibration(BaseModel):
    subject_id: int
    subject_name: str
    review_count: int
    ready: bool
    avg_confidence: float | None = None
    actual_recall_pct: float | None = None
    overconfidence_pct: float | None = None
    suggested_offset_pct: float | None = None
    hint: str | None = None


class CalibrationResponse(BaseModel):
    min_reviews_required: int = 30
    total_reviews_with_confidence: int
    global_ready: bool
    global_overconfidence_pct: float | None = None
    global_suggested_offset_pct: float | None = None
    global_hint: str | None = None
    deck_hint: str | None = None
    decks: list[DeckCalibration]
