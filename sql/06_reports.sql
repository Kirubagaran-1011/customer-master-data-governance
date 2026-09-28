-- 06_reports.sql : reporting queries. Blocks start with "-- name: <output_file>"
-- and are exported to data/output/<output_file>.csv by the pipeline.

-- name: dq_report
SELECT b.rule_id, b.rule_name, b.dimension,
       ROUND(100.0 * (b.total - b.failed) / NULLIF(b.total, 0), 1) AS pass_pct_before,
       ROUND(100.0 * (a.total - a.failed) / NULLIF(a.total, 0), 1) AS pass_pct_after,
       b.failed AS failed_before, a.failed AS failed_after
FROM dq_results b
JOIN dq_results a ON a.rule_id = b.rule_id AND a.stage = 'AFTER'
WHERE b.stage = 'BEFORE'
ORDER BY b.rule_id;

-- name: summary
SELECT
    (SELECT COUNT(*) FROM stg_customers)                                    AS source_records,
    (SELECT COUNT(*) FROM customer_master)                                  AS master_records,
    (SELECT COUNT(*) FROM stg_customers) - (SELECT COUNT(*) FROM customer_master) AS duplicates_removed,
    ROUND(100.0 * ((SELECT COUNT(*) FROM stg_customers) - (SELECT COUNT(*) FROM customer_master))
          / (SELECT COUNT(*) FROM stg_customers), 1)                        AS duplicate_rate_pct,
    (SELECT COUNT(*) FROM customer_master WHERE source_record_count > 1)    AS customers_in_multiple_records;

-- name: source_coverage
SELECT source_system, COUNT(*) AS records, COUNT(DISTINCT master_id) AS distinct_customers
FROM cluster_records
GROUP BY source_system
ORDER BY source_system;

-- name: customer_crosswalk
SELECT master_id, source_system, source_id, full_name, email, phone, city
FROM cluster_records
ORDER BY master_id, priority;
