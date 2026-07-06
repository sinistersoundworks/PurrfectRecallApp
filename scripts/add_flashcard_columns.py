#!/usr/bin/env python3
"""Ensure required flashcard columns exist in the SQLite database.

This script is safe to run multiple times — it only issues ALTER TABLE
for columns that are missing.
"""
import sqlite3
from pathlib import Path
import sys


DB_PATH = Path(__file__).resolve().parents[1] / "study.db"


def main():
    if not DB_PATH.exists():
        print(f"Database not found at {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(str(DB_PATH))
    cur = conn.cursor()

    cur.execute("PRAGMA table_info(flashcard);")
    existing = [r[1] for r in cur.fetchall()]

    to_add = []
    if 'last_reviewed' not in existing:
        to_add.append(("last_reviewed", "DATETIME", None))
    if 'interval' not in existing:
        to_add.append(("interval", "INTEGER", "1"))
    if 'ease_factor' not in existing:
        to_add.append(("ease_factor", "REAL", "2.5"))
    if 'repetition' not in existing:
        to_add.append(("repetition", "INTEGER", "0"))
    if 'due_date' not in existing:
        # default to now
        to_add.append(("due_date", "DATETIME", "(datetime('now'))"))

    if not to_add:
        print("No columns to add; flashcard table already up-to-date.")
        return

    for name, coltype, default in to_add:
        ddl = f"ALTER TABLE flashcard ADD COLUMN {name} {coltype}"
        if default is not None:
            ddl += f" DEFAULT {default}"
        print("Executing:", ddl)
        cur.execute(ddl)

    conn.commit()
    print("Done — added columns:", ", ".join([c[0] for c in to_add]))
    conn.close()


if __name__ == '__main__':
    main()
