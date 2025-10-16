SELECT COUNT(*) FROM `sap-iac-test.scct_gold_analytics.zbw_s_marc_mbew_bq`; -- 4171
SELECT COUNT(*) FROM (SELECT DISTINCT matnr, werks FROM `sap-iac-test.scct_gold_analytics.zbw_s_marc_mbew_bq`); -- 4169
SELECT COUNT(*) FROM `sap-iac-test.scct_bronze_sap.zbw_s_marc_mbew`; -- 5376
SELECT COUNT(*) FROM (SELECT DISTINCT matnr, werks FROM `sap-iac-test.scct_bronze_sap.zbw_s_marc_mbew`); -- 5376
SELECT COUNT(*) FROM `sap-iac-test.GS4_CDC_PS.marc`; -- 4169
SELECT COUNT(*) FROM (SELECT DISTINCT matnr, werks FROM `sap-iac-test.GS4_CDC_PS.marc`); -- 4169

SELECT
  DISTINCT
  matnr, werks
FROM
  `sap-iac-test.scct_bronze_sap.zbw_s_marc_mbew` bronze
WHERE 
  NOT EXISTS (
    SELECT matnr, werks FROM `sap-iac-test.scct_gold_analytics.zbw_s_marc_mbew_bq` gold WHERE
    bronze.matnr = gold.matnr AND bronze.werks = gold.werks
  ); -- 1207


SELECT
  DISTINCT
  matnr, werks
FROM
  `sap-iac-test.scct_bronze_sap.zbw_s_marc_mbew` bronze
WHERE 
  EXISTS (
    SELECT matnr, werks FROM `sap-iac-test.scct_gold_analytics.zbw_s_marc_mbew_bq` gold WHERE
    bronze.matnr = gold.matnr AND bronze.werks = gold.werks
  ); -- 4169