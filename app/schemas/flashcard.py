from pydantic import BaseModel, Field
from datetime import datetime


class FlashcardBase(BaseModel):
    subject_id: int
    question: str
    answer: str


class FlashcardCreate(FlashcardBase):
    pass


class FlashcardUpdate(BaseModel):
    subject_id: int | None = None
    question: str | None = None
    answer: str | None = None


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
