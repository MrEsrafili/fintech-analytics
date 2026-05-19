"""
01_append_orders.py
--------------------
Reads all orders CSV files from data/raw/orders/,
normalises column names, cleans numeric fields,
and saves the combined table to data/processed/analytics.db.

Schema produced (orders table):
    id              TEXT      -- order identifier
    user            TEXT      -- user identifier (FK → users.id)
    createdat       DATETIME  -- order timestamp
    totalvalue      REAL      -- total transaction value
    requestprice    REAL      -- gold price at order time (per gram)
    requestvolume   REAL      -- gold weight in grams
    fee             REAL      -- fee rate applied to the order
    comefrom        TEXT      -- acquisition channel / traffic source
    source_file     TEXT      -- original CSV filename (audit trail)
"""

import os
import re
import glob
import sqlite3
import pandas as pd

# ── Paths ────────────────────────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_PATH    = os.path.join(BASE_DIR, "data", "raw", "orders")
DB_PATH     = os.path.join(BASE_DIR, "data", "processed", "analytics.db")

# ── Helper: normalise column names ───────────────────────────────────────────
def clean_col(name: str) -> str:
    """Lowercase, strip, replace non-alphanumeric runs with underscore."""
    name = name.strip().lower()
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return name.strip("_")

# ── 1. Discover CSV files ─────────────────────────────────────────────────────
all_files = glob.glob(os.path.join(RAW_PATH, "*.csv"))

if not all_files:
    raise FileNotFoundError(
        f"No CSV files found in: {RAW_PATH}\n"
        "Place your orders CSVs inside data/raw/orders/ and re-run."
    )

print(f"📂  Found {len(all_files)} orders file(s)")

# ── 2. Read & stack ───────────────────────────────────────────────────────────
frames = []
for path in all_files:
    df = pd.read_csv(path, low_memory=False)
    df.columns = [clean_col(c) for c in df.columns]
    df["source_file"] = os.path.basename(path)
    frames.append(df)
    print(f"   ✓ {os.path.basename(path):40s}  {len(df):>7,} rows")

# Align columns across all files before concatenating
all_cols = sorted(set().union(*[df.columns for df in frames]))
frames   = [df.reindex(columns=all_cols) for df in frames]

combined = pd.concat(frames, ignore_index=True)
print(f"\n✅  Combined: {len(combined):,} rows × {len(combined.columns)} columns")

# ── 3. Parse dates ────────────────────────────────────────────────────────────
if "createdat" in combined.columns:
    combined["createdat"] = pd.to_datetime(
        combined["createdat"].astype(str).str.strip(),
        errors="coerce",
        infer_datetime_format=True,
    )
    invalid = combined["createdat"].isna().sum()
    print(f"🕒  Date range: {combined['createdat'].min().date()} → {combined['createdat'].max().date()}")
    if invalid:
        print(f"⚠️   {invalid:,} rows with unparseable dates (set to NaT)")

# ── 4. Clean numeric columns ──────────────────────────────────────────────────
numeric_cols = ["totalvalue", "requestprice", "requestvolume", "fee"]

for col in numeric_cols:
    if col in combined.columns:
        combined[col] = (
            combined[col]
            .astype(str)
            .str.replace(r"[^\d,.\-]", "", regex=True)   # strip currency symbols etc.
            .str.replace(",", ".", regex=False)            # EU decimal comma → period
        )
        combined[col] = pd.to_numeric(combined[col], errors="coerce").fillna(0)

# ── 5. Save to SQLite ─────────────────────────────────────────────────────────
conn = sqlite3.connect(DB_PATH)
combined.to_sql("orders", conn, if_exists="replace", index=False)
conn.execute("CREATE INDEX IF NOT EXISTS idx_orders_user       ON orders(user)")
conn.execute("CREATE INDEX IF NOT EXISTS idx_orders_createdat  ON orders(createdat)")
conn.execute("CREATE INDEX IF NOT EXISTS idx_orders_comefrom   ON orders(comefrom)")
conn.commit()
conn.close()

print(f"\n🎯  orders table saved → {DB_PATH}")
print(    "    Indexes created on: user, createdat, comefrom")
