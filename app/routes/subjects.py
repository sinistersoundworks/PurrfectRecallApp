from fastapi import APIRouter, Depends
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.subject import Subject
from app.schemas.subject import SubjectCreate, SubjectResponse

print("SUBJECTS LOADED")

router = APIRouter(prefix="/subjects", tags=["Subjects"])


@router.post("", response_model=SubjectResponse)
def create_subject(subject: SubjectCreate, db: Session = Depends(get_db)):
    print("Subjects Router Loaded")

    db_subject = Subject(
        name=subject.name,
        description=subject.description
    )

    db.add(db_subject)
    db.commit()
    db.refresh(db_subject)

    return db_subject

@router.get("", response_model=list[SubjectResponse])
def get_subjects(db: Session = Depends(get_db)):
    return db.query(Subject).all()


print("Router Loaded")

@router.delete("/{subject_id}")
def delete_subject(subject_id: int, db: Session = Depends(get_db)):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()

    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    db.delete(subject)
    db.commit()

    return {"message": "deleted"}


@router.put("/{subject_id}", response_model=SubjectResponse)
def update_subject(subject_id: int, subject: SubjectCreate, db: Session = Depends(get_db)):
    db_subject = db.query(Subject).filter(Subject.id == subject_id).first()

    if not db_subject:
        raise HTTPException(status_code=404, detail="Subject not found")

    db_subject.name = subject.name
    db_subject.description = subject.description

    db.commit()
    db.refresh(db_subject)

    return db_subject