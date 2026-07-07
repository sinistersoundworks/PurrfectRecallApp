from pathlib import Path

# Repo-root media directory (images, audio). Served at GET /media/{path}.
MEDIA_ROOT = Path(__file__).resolve().parents[1] / "media"


def ensure_media_root() -> Path:
    MEDIA_ROOT.mkdir(parents=True, exist_ok=True)
    return MEDIA_ROOT


def resolve_media_path(relative: str) -> Path:
    """Resolve a stored relative path safely inside MEDIA_ROOT."""
    clean = relative.strip().lstrip("/").replace("\\", "/")
    target = (MEDIA_ROOT / clean).resolve()
    root = MEDIA_ROOT.resolve()
    if not str(target).startswith(str(root)):
        raise ValueError("Invalid media path")
    return target
