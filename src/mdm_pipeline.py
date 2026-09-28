"""
Customer Master Data Governance & Integration pipeline
------------------------------------------------------
1. Load 3 source files (different column names) into one staging table
2. Measure data quality BEFORE
3. Standardise, match and de-duplicate using SQL rules
4. Build the master (golden) customer table
5. Measure data quality AFTER and export reports

Run:  python src/mdm_pipeline.py
"""
import re
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW, OUT, SQL = ROOT / "data" / "raw", ROOT / "data" / "output", ROOT / "sql"
OUT.mkdir(parents=True, exist_ok=True)

STD_COLS = ["source_system", "source_id", "full_name", "email", "phone", "city", "country", "created_date"]

# Each source has its own column names -> map to one common schema
SOURCES = {
    "CRM": ("crm_customers.csv", {"crm_id": "source_id", "name": "full_name", "email": "email", "phone": "phone",
                                  "city": "city", "country": "country", "created_on": "created_date"}),
    "SALES": ("sales_customers.csv", {"cust_no": "source_id", "customer_name": "full_name", "email_address": "email",
                                      "mobile": "phone", "town": "city", "country_code": "country",
                                      "signup_date": "created_date"}),
    "SUPPORT": ("support_customers.csv", {"ticket_user_id": "source_id", "user_name": "full_name",
                                          "contact_email": "email", "contact_phone": "phone", "location": "city",
                                          "nation": "country", "first_seen": "created_date"}),
}


def proper_case(value):
    """'  aRUN   kumar ' -> 'Arun Kumar'  (used inside SQL)."""
    if value is None:
        return None
    return " ".join(w.capitalize() for w in re.split(r"\s+", value.strip()) if w)


def run_sql_file(conn, name, **params):
    text = (SQL / name).read_text()
    if params:
        text = text.format(**params)
    conn.executescript(text)


def load_staging(conn):
    frames = []
    for system, (file, mapping) in SOURCES.items():
        df = pd.read_csv(RAW / file, dtype=str).rename(columns=mapping)
        df["source_system"] = system
        frames.append(df[STD_COLS])
    staging = pd.concat(frames, ignore_index=True)
    staging.to_sql("stg_customers", conn, if_exists="replace", index=False)
    counts = staging["source_system"].value_counts().to_dict()
    print(f"Loaded {len(staging)} source records: {counts}")


def build_clusters(conn):
    """Group matched record pairs into clusters (union-find / connected components)."""
    rec_ids = [r[0] for r in conn.execute("SELECT rec_id FROM customers_std ORDER BY rec_id")]
    parent = {r: r for r in rec_ids}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in conn.execute("SELECT rec_a, rec_b FROM match_pairs"):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[max(ra, rb)] = min(ra, rb)

    roots = sorted({find(r) for r in rec_ids})
    master_of = {root: f"M{i + 1:04d}" for i, root in enumerate(roots)}
    cluster_map = pd.DataFrame({"rec_id": rec_ids, "master_id": [master_of[find(r)] for r in rec_ids]})
    cluster_map.to_sql("cluster_map", conn, if_exists="replace", index=False)


def export_reports(conn):
    text = (SQL / "06_reports.sql").read_text()
    blocks = re.split(r"^-- name:\s*(\w+)\s*$", text, flags=re.M)[1:]
    for name, query in zip(blocks[::2], blocks[1::2]):
        df = pd.read_sql_query(query.strip().rstrip(";"), conn)
        df.to_csv(OUT / f"{name}.csv", index=False)
        if name in ("summary", "dq_report"):
            print(f"\n--- {name} ---")
            print(df.to_string(index=False))
    pd.read_sql_query("SELECT * FROM customer_master", conn).to_csv(OUT / "master_customers.csv", index=False)


def main():
    conn = sqlite3.connect(":memory:")
    conn.create_function("proper_case", 1, proper_case)

    load_staging(conn)
    run_sql_file(conn, "01_schema.sql")
    run_sql_file(conn, "02_dq_checks.sql", table="stg_customers", stage="BEFORE")
    run_sql_file(conn, "03_standardize.sql")
    run_sql_file(conn, "04_matching.sql")
    build_clusters(conn)
    run_sql_file(conn, "05_master.sql")
    run_sql_file(conn, "02_dq_checks.sql", table="customer_master", stage="AFTER")
    export_reports(conn)

    conn.commit()
    print(f"\nDone. Output files are in {OUT}")


if __name__ == "__main__":
    main()
