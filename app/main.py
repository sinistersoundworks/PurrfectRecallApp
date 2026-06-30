from fastapi import FastAPI
from app.database import engine, Base
from app.models.subject import Subject

# vytvoří tabulky při startu (MVP přístup)
Base.metadata.create_all(bind=engine)

app = FastAPI()


@app.get("/")
def root():
    return {"status": "ok"}