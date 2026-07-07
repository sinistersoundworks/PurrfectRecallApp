
#příkaz, který spustí tvůj FastAPI backend jako web server a při vývoji ho automaticky restartuje při změnách kódu.
uvicorn app.main:app --reload

uv run uvicorn app.main:app --reload  # uv is managing everything - so run this