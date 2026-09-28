-- 02_dq_checks.sql : data quality rules (see docs/governance_framework.md)
-- Template file: {table} and {stage} are filled in by src/mdm_pipeline.py
-- Run once on the raw staging table (BEFORE) and once on the master table (AFTER).

INSERT INTO dq_results
SELECT '{stage}', 'DQ01', 'Full name is present', 'Completeness', COUNT(*),
       COALESCE(SUM(CASE WHEN full_name IS NULL OR TRIM(full_name) = '' THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ02', 'Email is present', 'Completeness', COUNT(*),
       COALESCE(SUM(CASE WHEN email IS NULL OR TRIM(email) = '' THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ03', 'Email format is valid', 'Validity',
       COALESCE(SUM(CASE WHEN email IS NOT NULL AND TRIM(email) <> '' THEN 1 ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN email IS NOT NULL AND TRIM(email) <> ''
                          AND (email NOT LIKE '%_@_%._%' OR email LIKE '% %' OR email <> LOWER(email)) THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ04', 'Phone is present', 'Completeness', COUNT(*),
       COALESCE(SUM(CASE WHEN phone IS NULL OR TRIM(phone) = '' THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ05', 'Phone is standard 10-digit format', 'Validity',
       COALESCE(SUM(CASE WHEN phone IS NOT NULL AND TRIM(phone) <> '' THEN 1 ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN phone IS NOT NULL AND TRIM(phone) <> ''
                          AND phone NOT GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ06', 'City uses standard name and casing', 'Consistency',
       COALESCE(SUM(CASE WHEN city IS NOT NULL AND TRIM(city) <> '' THEN 1 ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN city IS NOT NULL AND TRIM(city) <> ''
                          AND (city <> proper_case(city) OR LOWER(TRIM(city)) IN ('madras', 'bangalore', 'trichy')) THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ07', 'Country uses standard name (India)', 'Consistency',
       COALESCE(SUM(CASE WHEN country IS NOT NULL AND TRIM(country) <> '' THEN 1 ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN country IS NOT NULL AND TRIM(country) <> '' AND country <> 'India' THEN 1 ELSE 0 END), 0)
FROM {table};

INSERT INTO dq_results
SELECT '{stage}', 'DQ08', 'Email is unique (no duplicate customers)', 'Uniqueness',
       (SELECT COUNT(*) FROM {table} WHERE email IS NOT NULL AND TRIM(email) <> ''),
       (SELECT COUNT(*) FROM {table} t
         WHERE t.email IS NOT NULL AND TRIM(t.email) <> ''
           AND (SELECT COUNT(*) FROM {table} x WHERE LOWER(TRIM(x.email)) = LOWER(TRIM(t.email))) > 1);
