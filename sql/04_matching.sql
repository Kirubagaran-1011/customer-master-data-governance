-- 04_matching.sql : deterministic match rules (each pair listed once: rec_a < rec_b)
--   M1  same email
--   M2  same 10-digit phone
--   M3  same name AND same city
-- Python then groups the pairs into clusters (connected components).

DROP TABLE IF EXISTS match_pairs;
CREATE TABLE match_pairs AS
SELECT a.rec_id AS rec_a, b.rec_id AS rec_b, 'M1_EMAIL' AS rule
FROM customers_std a JOIN customers_std b
  ON a.email = b.email AND a.rec_id < b.rec_id
UNION ALL
SELECT a.rec_id, b.rec_id, 'M2_PHONE'
FROM customers_std a JOIN customers_std b
  ON a.phone = b.phone AND a.rec_id < b.rec_id
UNION ALL
SELECT a.rec_id, b.rec_id, 'M3_NAME_CITY'
FROM customers_std a JOIN customers_std b
  ON a.name_key = b.name_key AND a.city = b.city AND a.rec_id < b.rec_id;
