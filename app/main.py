from fastapi import FastAPI
from app.database import engine, Base
# from app.models.subject import Subject
from app.routes import subjects
# print(subjects)

print("MAIN LOADED")

# Importuje router pro práci s předměty (Subject).
# Router obsahuje všechny endpointy související s předměty,
# například GET /subjects nebo POST /subjects.
from app.routes.subjects import router as subject_router

app = FastAPI()


print("REGISTERING ROUTER")
# Připojí router k hlavní FastAPI aplikaci.
# Díky tomu se všechny endpointy definované v subject_router
# stanou součástí aplikace a budou dostupné přes HTTP.
app.include_router(subject_router)
print("ROUTER REGISTERED")
print(app.routes)

@app.get("/")
def root():
    return {"status": "ok"}


# vytvoří tabulky při startu (MVP přístup)
Base.metadata.create_all(bind=engine)