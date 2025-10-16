DECLARE v_datasource string default 'ZBW_MD_MARC_MBEW%GS4%';
DECLARE v_infosource string;
DECLARE v_transformation string;
-- get technical name of infosource in BW which is connected to extractor
Set v_infosource = (
  SELECT
targetname
FROM
  `sap-iac-test.bq_toolkit_bw7.rstran`
WHERE
  sourcename LIKE v_datasource
  AND objvers = 'A');

SET v_transformation = (

--get ID of Transformation between extractor and infosource
Select tranid
FROM
  sap-iac-test.bq_toolkit_bw7.rstran
WHERE
  sourcename LIKE v_datasource
  and targetname like v_infosource
  AND objvers = 'A'
);

-- based on tarsformation id we can get rules from below
SELECT
  DISTINCT ruleid,
  CASE
    WHEN paramtype = '0' THEN paramnm
  END AS fieldname, -- 1. Added AS fieldname, 2. Added comma
  CASE
    WHEN paramtype = '1' THEN paramnm
  END AS infoobject -- 1. Added AS infoobject
FROM
  `sap-iac-test.bq_toolkit_bw7.rstranfield` -- 3. Removed comma before FROM
WHERE
  objvers = 'A'
  AND tranid = v_transformation
  group by ruleid, fieldname, infoobject;