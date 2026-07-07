from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, Float, String
from sqlalchemy.orm import relationship

from app.database import Base


class Review(Base):
    __tablename__ = "review"

    id = Column(Integer, primary_key=True, index=True)
    flashcard_id = Column(Integer, ForeignKey("flashcard.id"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subject.id"), nullable=False)
    quality = Column(Integer, nullable=False)
    confidence = Column(Integer, nullable=True)
    response_ms = Column(Integer, nullable=True)
    session_id = Column(String, nullable=True)
    predicted_recall_pct = Column(Float, nullable=True)
    reviewed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    flashcard = relationship("Flashcard", back_populates="reviews")
    subject = relationship("Subject", back_populates="reviews")
