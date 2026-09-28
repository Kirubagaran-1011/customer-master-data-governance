-- 01_schema.sql : working tables for the MDM pipeline (SQLite dialect)
-- Staging table "stg_customers" is loaded by Python from the 3 source files.

DROP TABLE IF EXISTS dq_results;
CREATE TABLE dq_results (
    stage     TEXT,      -- BEFORE (raw) or AFTER (master)
    rule_id   TEXT,
    rule_name TEXT,
    dimension TEXT,      -- Completeness / Validity / Consistency / Uniqueness
    total     INTEGER,   -- records the rule applies to
    failed    INTEGER    -- records that break the rule
);

DROP TABLE IF EXISTS source_priority;
CREATE TABLE source_priority (source_system TEXT PRIMARY KEY, priority INTEGER);
-- Lower number = more trusted source (used by survivorship rules)
INSERT INTO source_priority VALUES ('CRM', 1), ('SALES', 2), ('SUPPORT', 3);
