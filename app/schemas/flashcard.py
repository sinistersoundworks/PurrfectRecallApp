from pydantic import BaseModel, Field
from datetime import datetime


class FlashcardBase(BaseModel):
    subject_id: int
    question: str
    answer: str
    example: str | None = None
    ipa: str | None = None
    image_path: str | None = None
    audio_word: str | None = None
    audio_meaning: str | None = None
    audio_example: str | None = None


class FlashcardCreate(FlashcardBase):
    pass


class FlashcardUpdate(BaseModel):
    subject_id: int | None = None
    question: str | None = None
    answer: str | None = None
    example: str | None = None
    ipa: str | None = None
    image_path: str | None = None
    audio_word: str | None = None
    audio_meaning: str | None = None
    audio_example: str | None = None


class FlashcardReview(BaseModel):
    quality: int = Field(..., ge=0, le=5)
    confidence: int | None = Field(None, ge=0, le=100)
    response_ms: int | None = Field(None, ge=0)
    session_id: str | None = None


class FlashcardResponse(FlashcardBase):
    id: int
    created_at: datetime
    last_reviewed: datetime | None
    interval: int
    ease_factor: float
    repetition: int
    due_date: datetime
    memory_state: int = 0
    memory_step: int | None = None
    memory_stability: float | None = None
    memory_difficulty: float | None = None
    predicted_recall_pct: float | None = None

    class Config:
        from_attributes = True


class FlashcardReviewResult(BaseModel):
    card: FlashcardResponse
    predicted_recall_before_pct: float | None
    predicted_recall_after_pct: float | None

    class Config:
        from_attributes = True
