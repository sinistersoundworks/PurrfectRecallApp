import uuid
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import FileResponse

from app.media_storage import ensure_media_root, resolve_media_path

router = APIRouter(prefix="/media", tags=["Media"])

ALLOWED_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".webp",
    ".mp3",
    ".m4a",
    ".wav",
    ".ogg",
    ".aac",
}


@router.get("/{file_path:path}")
def get_media(file_path: str):
    try:
        path = resolve_media_path(file_path)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if not path.is_file():
        raise HTTPException(status_code=404, detail="Media not found")

    return FileResponse(path)


@router.post("/upload")
async def upload_media(file: UploadFile = File(...)):
    ensure_media_root()
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    uploads_dir = ensure_media_root() / "uploads"
    uploads_dir.mkdir(parents=True, exist_ok=True)

    stored_name = f"{uuid.uuid4().hex}{suffix}"
    dest = uploads_dir / stored_name
    content = await file.read()
    dest.write_bytes(content)

    relative = f"uploads/{stored_name}"
    return {"path": relative, "url": f"/media/{relative}"}
