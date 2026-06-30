from pydantic import BaseModel
from datetime import datetime


class SubjectCreate(BaseModel):
    name: str
    description: str | None = None


class SubjectResponse(BaseModel):
    id: int
    name: str
    description: str | None
    created_at: datetime

    class Config:
        from_attributes = True