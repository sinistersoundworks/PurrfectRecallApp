#!/usr/bin/env python3
"""Create the review audit log table if it does not exist."""
import sqlite3
import sys
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "study.db"

CREATE_REVIEW_TABLE = """
CREATE TABLE IF NOT EXISTS review (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    flashcard_id INTEGER NOT NULL,
    subject_id INTEGER NOT NULL,
    quality INTEGER NOT NULL,
    reviewed_at DATETIME NOT NULL,
    FOREIGN KEY(flashcard_id) REFERENCES flashcard(id),
    FOREIGN KEY(subject_id) REFERENCES subject(id)
);
"""


def main():
    if not DB_PATH.exists():
        print(f"Database not found at {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()
    cur.execute(CREATE_REVIEW_TABLE)
    conn.commit()
    conn.close()
    print("Review table is ready.")


if __name__ == "__main__":
    main()
