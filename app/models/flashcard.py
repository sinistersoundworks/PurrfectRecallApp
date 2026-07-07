from sqlalchemy import Column, Integer, String, DateTime, Float, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base


class Flashcard(Base):
    __tablename__ = "flashcard"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subject.id"), nullable=False)
    question = Column(String, nullable=False)
    answer = Column(String, nullable=False)
    example = Column(String, nullable=True)
    ipa = Column(String, nullable=True)
    image_path = Column(String, nullable=True)
    audio_word = Column(String, nullable=True)
    audio_meaning = Column(String, nullable=True)
    audio_example = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_reviewed = Column(DateTime, nullable=True)
    interval = Column(Integer, default=0)
    ease_factor = Column(Float, default=2.5)
    repetition = Column(Integer, default=0)
    due_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    memory_state = Column(Integer, default=0)
    memory_step = Column(Integer, nullable=True)
    memory_stability = Column(Float, nullable=True)
    memory_difficulty = Column(Float, nullable=True)

    subject = relationship("Subject", back_populates="flashcards")
    reviews = relationship("Review", back_populates="flashcard", cascade="all, delete-orphan")
