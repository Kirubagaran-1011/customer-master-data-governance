-- 05_master.sql : build the golden record (one row per real customer)
-- Requires table cluster_map(rec_id, master_id) created by Python.
--
-- Survivorship rules:
--   full_name : longest (most complete) name
--   email / phone / city / country : first non-null value from the most trusted source
--                                    (CRM > SALES > SUPPORT), newest record wins ties
--   created_date : earliest date across all sources

DROP VIEW IF EXISTS cluster_records;
CREATE VIEW cluster_records AS
SELECT c.*, k.master_id FROM customers_std c JOIN cluster_map k USING (rec_id);

DROP TABLE IF EXISTS customer_master;
CREATE TABLE customer_master AS
SELECT
    m.master_id,
    (SELECT full_name FROM cluster_records r WHERE r.master_id = m.master_id AND r.full_name IS NOT NULL
      ORDER BY LENGTH(r.full_name) DESC, r.priority LIMIT 1) AS full_name,
    (SELECT email FROM cluster_records r WHERE r.master_id = m.master_id AND r.email IS NOT NULL
      ORDER BY r.priority, r.created_date DESC LIMIT 1) AS email,
    (SELECT phone FROM cluster_records r WHERE r.master_id = m.master_id AND r.phone IS NOT NULL
      ORDER BY r.priority, r.created_date DESC LIMIT 1) AS phone,
    (SELECT city FROM cluster_records r WHERE r.master_id = m.master_id AND r.city IS NOT NULL
      ORDER BY r.priority, r.created_date DESC LIMIT 1) AS city,
    (SELECT country FROM cluster_records r WHERE r.master_id = m.master_id AND r.country IS NOT NULL
      ORDER BY r.priority, r.created_date DESC LIMIT 1) AS country,
    (SELECT MIN(created_date) FROM cluster_records r WHERE r.master_id = m.master_id) AS customer_since,
    (SELECT COUNT(*) FROM cluster_records r WHERE r.master_id = m.master_id) AS source_record_count,
    (SELECT GROUP_CONCAT(r.source_system || ':' || r.source_id, '; ') FROM cluster_records r
      WHERE r.master_id = m.master_id) AS source_records
FROM (SELECT DISTINCT master_id FROM cluster_map) m
ORDER BY m.master_id;
