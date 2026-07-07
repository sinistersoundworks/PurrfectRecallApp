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


class FlashcardResponse(FlashcardBase):
    id: int
    created_at: datetime
    last_reviewed: datetime | None
    interval: int
    ease_factor: float
    repetition: int
    due_date: datetime

    class Config:
        from_attributes = True
