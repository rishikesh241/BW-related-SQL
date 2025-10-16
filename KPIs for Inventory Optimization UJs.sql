
-- UJ5: Find distinct obsolete stock values 
select distinct materialnumber FROM `sap-iac-test.GS4_REPORTING.Safety_Obsolete_Stock` where obsoletestock is not null or obsoletestock != ""

--UJ1: SAFETY STOCK VALUES AND BLOCKED STOCKS-- find distinct materials in the critical shortage. fetch the values for the latest records only per material. 
-- fetch the material number, description, stockinhand, amountinhand and date 
SELECT materialnumber, description, stockinhand, amountinhand, currentdate, safetystockqty, blockedqty, blockedamount FROM `sap-iac-test.GS4_REPORTING.Safety_Obsolete_Stock`
WHERE CriticalShortageIndicator = 'X' 
QUALIFY ROW_NUMBER() OVER (PARTITION BY materialnumber ORDER BY currentdate DESC) = 1;

-- UJ1: fetch overdue pos
SELECT * FROM `sap-iac-test.GS4_REPORTING.OverDuePOs`

-- UJ1: late shipments
SELECT material_number, delivery_number, late_shipment_quantity, actual_goods_issue_date, planned_delivery_date, days_late FROM `sap-iac-test.GS4_REPORTING.LateShipments`


