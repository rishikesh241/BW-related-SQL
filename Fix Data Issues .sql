
-- remove the material number 000000000000000004 from all tables 

-- 2 records in LateShipments table
SELECT count(*) FROM `sap-iac-test.GS4_REPORTING.LateShipments` WHERE material_number = "000000000000000004" ;
DELETE FROM `sap-iac-test.GS4_REPORTING.LateShipments` WHERE material_number = "000000000000000004" ;

-- Safety_Obsolete_Stock : 597 records 
SELECT * FROM `sap-iac-test.GS4_REPORTING.Safety_Obsolete_Stock` WHERE materialnumber = "000000000000000004" ;
DELETE FROM `sap-iac-test.GS4_REPORTING.Safety_Obsolete_Stock` WHERE materialnumber = "000000000000000004" ;

-- delete from StockMonthlySnapshots and StockWeeklySnapshots 

-- Stock Monthly Snapshots: 959 records 
SELECT * FROM `sap-iac-test.GS4_REPORTING.StockMonthlySnapshots` WHERE materialnumber_matnr = "000000000000000004" ;
DELETE FROM `sap-iac-test.GS4_REPORTING.StockMonthlySnapshots` WHERE materialnumber_matnr = "000000000000000004" ;

-- Stock Weekly Snapshots: 4089 records 
SELECT * FROM `sap-iac-test.GS4_REPORTING.StockWeeklySnapshots` WHERE materialnumber_matnr = "000000000000000004" ;
DELETE FROM `sap-iac-test.GS4_REPORTING.StockWeeklySnapshots` WHERE materialnumber_matnr = "000000000000000004" ;

-- OverDuePos:  30 records 
SELECT * FROM `sap-iac-test.GS4_REPORTING.OverDuePOs` WHERE materialnumber = "000000000000000004" ;
DELETE FROM `sap-iac-test.GS4_REPORTING.OverDuePOs` WHERE materialnumber = "000000000000000004" ;
