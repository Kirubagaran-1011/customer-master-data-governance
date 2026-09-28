# Customer Master Data Governance & Integration Framework

An academic project that designs a **data governance framework** and builds a **master data management (MDM) pipeline**. It consolidates customer records from three source systems into one trusted master customer table using SQL and Python.

## What it does
1. Loads customer records from **CRM, Sales and Support** files (each with different column names).
2. Measures **data quality** with 8 rules (completeness, validity, consistency, uniqueness).
3. **Standardises** names, emails, phones, cities and countries.
4. **Matches and de-duplicates** records (email, phone, name + city).
5. Builds a **golden record** using survivorship rules (CRM is the most trusted source).
6. Re-measures quality and exports a before/after report.

## Sample result (synthetic data)
| Metric | Value |
|--------|-------|
| Source records | 127 |
| Master customers | 60 |
| Duplicates removed | 67 (52.8%) |
| Phone format pass rate | 12.6% to 100% |
| Email format pass rate | 20.0% to 100% |

## Project structure
```
data/raw/        3 source files (synthetic sample)
data/output/     master_customers.csv, dq_report.csv, summary.csv, customer_crosswalk.csv
sql/             01_schema ... 06_reports (the data quality, matching and master logic)
src/             generate_sample_data.py, mdm_pipeline.py
docs/            governance_framework.md (roles, rules, matching, survivorship)
access/          same steps done manually in Microsoft Access
```

## Run it
```bash
pip install -r requirements.txt
python src/generate_sample_data.py   # optional: recreate sample data
python src/mdm_pipeline.py
```
Results appear in `data/output/`. To use your own data, put files with the same columns in `data/raw/`.

## Tech
SQL (SQLite dialect, window functions, CTEs), Python (pandas, sqlite3), Microsoft Access, MDM and data governance concepts.

## Author
Kirubagaran S
