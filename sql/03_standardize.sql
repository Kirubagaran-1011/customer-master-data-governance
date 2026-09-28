-- 03_standardize.sql : apply standardisation rules and build match keys
-- proper_case() is a small helper function registered from Python (SQLite has no INITCAP).

DROP TABLE IF EXISTS customers_std;
CREATE TABLE customers_std AS
WITH cleaned AS (
    SELECT s.*,
           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(s.phone, ''),
               ' ', ''), '-', ''), '(', ''), ')', ''), '+', ''), '.', '') AS digits
    FROM stg_customers s
)
SELECT
    ROW_NUMBER() OVER (ORDER BY c.source_system, c.source_id)          AS rec_id,
    c.source_system,
    c.source_id,
    p.priority,
    proper_case(TRIM(c.full_name))                                     AS full_name,
    NULLIF(LOWER(TRIM(c.email)), '')                                   AS email,
    CASE WHEN LENGTH(c.digits) >= 10 THEN SUBSTR(c.digits, -10) END    AS phone,
    CASE LOWER(TRIM(c.city))
         WHEN 'madras'    THEN 'Chennai'
         WHEN 'bangalore' THEN 'Bengaluru'
         WHEN 'trichy'    THEN 'Tiruchirappalli'
         WHEN ''          THEN NULL
         ELSE proper_case(TRIM(c.city))
    END                                                                AS city,
    CASE WHEN LOWER(TRIM(c.country)) IN ('india', 'in', 'ind', 'bharat') THEN 'India'
         WHEN TRIM(COALESCE(c.country, '')) = '' THEN NULL
         ELSE proper_case(TRIM(c.country))
    END                                                                AS country,
    c.created_date,
    -- match key: name without spaces, lower case
    REPLACE(LOWER(TRIM(c.full_name)), ' ', '')                         AS name_key
FROM cleaned c
JOIN source_priority p ON p.source_system = c.source_system;
