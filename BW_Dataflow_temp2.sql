  -- get list of datasources and info sources & mapping with transformation IDs
SELECT
  sourcename,
  targetname,
  tranid
FROM
  sap-iac-test.bq_toolkit_bw7.rstran
WHERE
  sourcename LIKE 'ZBW_MD_MARC_MBEW%GS4%'
  AND objvers = 'A';

-- get list of 1st layer DSOs from info sources & mapping with transformation IDs
SELECT
  sourcename,
  targetname, -- DSOs
  tranid
FROM
  sap-iac-test.bq_toolkit_bw7.rstran
WHERE
  objvers = 'A'
  AND sourcename IN (
  SELECT
    targetname -- infosources
  FROM
    sap-iac-test.bq_toolkit_bw7.rstran
  WHERE
    sourcename LIKE 'ZBW_MD_MARC_MBEW%GS4%'
    AND objvers = 'A');

-- get list of 2st layer DSOs/cube from 1st layer dsos & mapping with transformation IDs
    SELECT
  sourcename,
  targetname, -- DSOs/cubes
  tranid,
sourcetype,
targettype
FROM
  sap-iac-test.bq_toolkit_bw7.rstran
WHERE
  objvers = 'A'
  AND sourcename IN (
      SELECT
  targetname, -- DSOs
FROM
  sap-iac-test.bq_toolkit_bw7.rstran
WHERE
  objvers = 'A'
  AND sourcename IN (
  SELECT
    targetname -- infosources
  FROM
    sap-iac-test.bq_toolkit_bw7.rstran
  WHERE
    sourcename LIKE '2LIS_12_VCHDR%GS4%'
    AND objvers = 'A'));