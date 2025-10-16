-- ZIS_MD_MARC_MBEW
-- 01EWGRIJFV980UY7TB0B4X9G1KWHU2QU

WITH fieldnames AS (
  SELECT
    ruleid,
    paramnm
  FROM
    `sap-iac-test.bq_toolkit_bw7.rstranfield` t -- 3. Removed comma before FROM
  WHERE
    objvers = 'A'
    AND tranid = '01EWGRIJFV980UY7TB0B4X9G1KWHU2QU'
    AND paramtype is NULL or paramtype = '0'
),
infoobjects AS (
  SELECT
    ruleid,
    paramnm
  FROM
    `sap-iac-test.bq_toolkit_bw7.rstranfield` t
  WHERE
    objvers = 'A'
    AND tranid = '01EWGRIJFV980UY7TB0B4X9G1KWHU2QU'
    AND paramtype = '1'
)
SELECT
CONCAT(lower(field), " AS ", lower(SUBSTR(infoobj, 2)), ",")
FROM(
  SELECT 
    f.ruleid,
    f.paramnm as field,
    i.paramnm as infoobj
  FROM 
    fieldnames f 
      INNER JOIN infoobjects i ON f.ruleid = i.ruleid
  ORDER BY
    ruleid
  );