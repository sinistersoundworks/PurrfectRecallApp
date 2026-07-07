#!/usr/bin/env python3
"""Add optional media columns to flashcard (images + audio paths, example, IPA).

Safe to run multiple times.
"""
import sqlite3
from pathlib import Path
import sys

DB_PATH = Path(__file__).resolve().parents[1] / "study.db"

COLUMNS = [
    ("example", "TEXT", None),
    ("ipa", "TEXT", None),
    ("image_path", "TEXT", None),
    ("audio_word", "TEXT", None),
    ("audio_meaning", "TEXT", None),
    ("audio_example", "TEXT", None),
]


def main():
    if not DB_PATH.exists():
        print(f"Database not found at {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(flashcard);")
    existing = {r[1] for r in cur.fetchall()}

    to_add = [c for c in COLUMNS if c[0] not in existing]
    if not to_add:
        print("Media columns already present.")
        conn.close()
        return

    for name, coltype, default in to_add:
        ddl = f"ALTER TABLE flashcard ADD COLUMN {name} {coltype}"
        if default is not None:
            ddl += f" DEFAULT {default}"
        print("Executing:", ddl)
        cur.execute(ddl)

    conn.commit()
    conn.close()
    print("Done — added:", ", ".join(c[0] for c in to_add))


if __name__ == "__main__":
    main()
