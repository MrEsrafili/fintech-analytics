"""
03_run_analysis.py
-------------------
Executes all SQL analysis files against analytics.db
and prints a formatted summary of each result set.

Run this after 01_append_orders.py and 02_append_users.py.

Usage:
    python scripts/03_run_analysis.py
"""

import os
import sqlite3
import pandas as pd

# ── Paths ────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH  = os.path.join(BASE_DIR, "data", "processed", "analytics.db")
SQL_DIR  = os.path.join(BASE_DIR, "sql")

# ── SQL files to run (in order) ───────────────────────────────────────────────
SQL_FILES = [
    ("01_cohort_retention.sql",  "Cohort Retention Analysis"),
    ("02_funnel_analysis.sql",   "Funnel Conversion Analysis"),
    ("03_revenue_analysis.sql",  "Revenue Analysis"),
    ("04_user_behavior.sql",     "User Behavior Analysis"),
]

# ── Helpers ───────────────────────────────────────────────────────────────────
def banner(title: str) -> None:
    width = 70
    print("\n" + "═" * width)
    print(f"  {title}")
    print("═" * width)

def run_sql_file(conn: sqlite3.Connection, filepath: str) -> pd.DataFrame:
    """Read a .sql file and execute it; return results as a DataFrame."""
    with open(filepath, "r", encoding="utf-8") as f:
        sql = f.read()
    return pd.read_sql_query(sql, conn)

# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> None:
    if not os.path.exists(DB_PATH):
        raise FileNotFoundError(
            f"Database not found: {DB_PATH}\n"
            "Run 01_append_orders.py and 02_append_users.py first."
        )

    conn = sqlite3.connect(DB_PATH)

    # Verify tables exist
    tables = pd.read_sql_query(
        "SELECT name FROM sqlite_master WHERE type='table'", conn
    )["name"].tolist()
    print(f"✅  Connected to {DB_PATH}")
    print(f"📋  Tables found: {', '.join(tables)}")

    pd.set_option("display.max_columns", 20)
    pd.set_option("display.width", 120)
    pd.set_option("display.float_format", "{:,.2f}".format)

    for filename, label in SQL_FILES:
        filepath = os.path.join(SQL_DIR, filename)
        if not os.path.exists(filepath):
            print(f"\n⚠️  Skipping (file not found): {filename}")
            continue

        banner(label)
        try:
            df = run_sql_file(conn, filepath)
            print(df.to_string(index=False))
            print(f"\n   → {len(df):,} rows returned")
        except Exception as exc:
            print(f"❌  Error running {filename}: {exc}")

    conn.close()
    print("\n✅  Analysis complete.")

if __name__ == "__main__":
    main()
