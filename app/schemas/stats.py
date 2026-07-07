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


class DeckInsight(BaseModel):
    subject_id: int
    name: str
    retention_pct: float
    lapse_rate_pct: float | None = None
    avg_difficulty: float | None = None
    review_count: int
    needs_attention: bool
    trend: str
    study_tip: str | None = None


class StatsResponse(BaseModel):
    streak_days: int
    due_today: int
    cards_learned: int
    retention_pct: float
    avg_ease: float
    recommended_daily_reviews: int
    reviews_last_7_days: list[ReviewDayCount]
    deck_stats: list[DeckStats]
    deck_insights: list[DeckInsight] = []
    weakest_deck_id: int | None = None
    weakest_deck_name: str | None = None
    improving_deck_id: int | None = None
    improving_deck_name: str | None = None
    global_study_tip: str | None = None


class ForecastPoint(BaseModel):
    date: str
    expected_retention_pct: float | None = None
    studied_card_count: int


class ForecastResponse(BaseModel):
    days: int
    points: list[ForecastPoint]


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
