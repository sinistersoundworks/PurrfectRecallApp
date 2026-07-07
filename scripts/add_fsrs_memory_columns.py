#!/usr/bin/env python3
"""Add FSRS memory columns to flashcard and ML fields to review."""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "study.db"

FLASHCARD_COLUMNS = [
    ("memory_state", "INTEGER NOT NULL DEFAULT 0"),
    ("memory_step", "INTEGER"),
    ("memory_stability", "REAL"),
    ("memory_difficulty", "REAL"),
]

REVIEW_COLUMNS = [
    ("confidence", "INTEGER"),
    ("response_ms", "INTEGER"),
    ("session_id", "TEXT"),
    ("predicted_recall_pct", "REAL"),
]


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit(f"Database not found: {DB_PATH}")

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("PRAGMA table_info(flashcard)")
    flashcard_cols = {row[1] for row in cur.fetchall()}
    for name, typedef in FLASHCARD_COLUMNS:
        if name not in flashcard_cols:
            print(f"ALTER TABLE flashcard ADD COLUMN {name} {typedef}")
            cur.execute(f"ALTER TABLE flashcard ADD COLUMN {name} {typedef}")

    cur.execute("PRAGMA table_info(review)")
    review_cols = {row[1] for row in cur.fetchall()}
    for name, typedef in REVIEW_COLUMNS:
        if name not in review_cols:
            print(f"ALTER TABLE review ADD COLUMN {name} {typedef}")
            cur.execute(f"ALTER TABLE review ADD COLUMN {name} {typedef}")

    conn.commit()
    conn.close()
    print("Done — FSRS memory + review ML columns ready.")


if __name__ == "__main__":
    main()
