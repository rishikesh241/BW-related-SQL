-- ------------------ QUERY FOR UJ1: SAFETY STOCK AND UJ5: OBSOLETE STOCK ---------------------------
-- fields required in table 
-- UJ1: KPI1: safety stock indicator (formula is qty of safety stock is greater than quantity on hand)
-- -- UJ5: obsolence analysis
-- -- fetch data having total consumption greater than 180 days and stock in hand exists for these materials
-- SELECT monthenddate , materialnumber_matnr, sum(quantitymonthlycumulative), sum(TotalConsumptionQuantity) FROM `sap-iac-test.GS4_REPORTING.StockMonthlySnapshots` where (monthenddate >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) AND totalconsumptionquantity = 0) 
-- GROUP BY 1,2


-- 1. material number / part number
-- 2. material description 
-- 3. plant 
-- 4. stock on hand (where char = unrestricted)
-- 5. blocked quantity (where char = blocked)
-- 6. unit of measure
-- 7. amount
-- 8. date 
-- 9. safety stock value
-- 10. KPI: critical shortage indicator (if current quantity < safetystocvalue)

-- CREATE OR REPLACE TABLE `sap-iac-test.GS4_REPORTING.Safety_Obsolete_Stock` AS

-- WITH AggregatedStock AS (
--   -- Step 1: Aggregate the data to get one consolidated row per material.
--   SELECT
--     materialnumber_matnr,
--     materialtext_maktx,
--     BaseUnitOfMeasure_MEINS,
--     WeekEndDate,
--     SafetyStock_EISBE,
--     SUM(CASE WHEN StockCharacteristic = "Unrestricted" THEN QuantityWeeklyCumulative ELSE 0 END) AS StockInHand,
--     SUM(CASE WHEN StockCharacteristic = "Blocked" THEN QuantityWeeklyCumulative ELSE 0 END) AS BlockedQty,
--     SUM(CASE WHEN StockCharacteristic = "Unrestricted" THEN AmountWeeklyCumulative ELSE 0 END) AS AmountInHand,
--     SUM(CASE WHEN StockCharacteristic = "Blocked" THEN AmountWeeklyCumulative ELSE 0 END) AS BlockedAmount
--   FROM
--     `sap-iac-test.GS4_REPORTING.InventoryByPlant`
--   GROUP BY
--     1, 2, 3, 4, 5
-- ),

-- ObsoleteStock AS(
--   SELECT monthenddate , materialnumber_matnr as obsoletestock, sum(quantitymonthlycumulative) FROM `sap-iac-test.GS4_REPORTING.StockMonthlySnapshots` where (monthenddate >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) AND totalconsumptionquantity = 0 AND quantitymonthlycumulative > 0) 
-- GROUP BY 1,2
-- )

-- -- Step 2: Select from the aggregated data and apply the final logic.
-- SELECT
--   materialnumber_matnr AS MaterialNumber,
--   materialtext_maktx AS Description,
--   obsoletestock AS ObsoleteStock, 
--   StockInHand,
--   BlockedQty,
--   BaseUnitOfMeasure_MEINS AS Unit,
--   AmountInHand,
--   BlockedAmount,
--   WeekEndDate AS currentdate,
--   SafetyStock_EISBE AS SafetyStockQty,
--   -- This comparison now works correctly on the aggregated 'StockInHand' value.
--   CASE WHEN StockInHand < SafetyStock_EISBE THEN "X" ELSE "" END AS CriticalShortageIndicator
-- FROM
--   AggregatedStock AS A
-- LEFT JOIN ObsoleteStock AS O
-- ON A.materialnumber_matnr = O.obsoletestock;
-- ------------------ QUERY FOR UJ1: SAFETY STOCK AND UJ5: OBSOLETE STOCK ---------------------------



-- -- UJ1: KPI2 : overdue purchase orders 
-- CREATE OR REPLACE TABLE `sap-iac-test.GS4_REPORTING.OverDuePOs` AS (
--   SELECT
--     l.ebeln AS DocumentNumber,
--     l.matnr AS materialnumber,
--     e.menge AS Quantity,
--     -- Corrected DATE_DIFF order to get a positive number of overdue days
--     -- Added PARSE_DATE to convert the SAP date string (e.g., '20250701') to a DATE type
--     DATE_DIFF(CURRENT_DATE(), e.eindt, DAY) AS OverDueByDays
--   FROM
--     `sap-iac-test.GS4_CDC.ekpo` AS l
--   INNER JOIN
--     `sap-iac-test.GS4_CDC.eket` AS e
--   ON
--     l.ebeln = e.ebeln AND l.ebelp = e.ebelp
--   WHERE
--     -- Use PARSE_DATE here as well for an accurate comparison
--     e.eindt < CURRENT_DATE()
--     -- Filter out items already marked as "Delivery Completed" (elikz = 'X')
--     AND l.elikz != 'X'
--     -- Best practice: Also exclude PO items marked for deletion (loekz)
--     AND l.loekz = ''
-- );

-- 1. Check from EKPO if elikz (delivery completion indicator is blank)
-- 2. for these po's check in EKET table if EINDT is less than current date
-- 3. fetch the distinct po number , material number and quantity 

-- UJ1: KPI3: quality notifications (not sure on table to use, need to generate complete synthetic data, no data in SAP)

-- UJ4 : multiple KPI's 
-- 1. CRITICAL SHORTAGE: get details from uj1 
-- 2. late shipments: run below query / create a table and fetch data from this table
-- CREATE OR REPLACE TABLE `sap-iac-test.GS4_REPORTING.LateShipments` AS (
-- SELECT
--   lips.MATNR AS material_number,
--   lips.LFIMG AS late_shipment_quantity,
--   likp.VBELN AS delivery_number,
--   vbap.VBELN AS sales_order_number,
--   vbap.POSNR AS sales_order_item,
--   vbap.MATNR AS material_number_in_so,
--   DATE(TIMESTAMP(likp.WADAT_IST)) AS actual_goods_issue_date,
--   DATE(TIMESTAMP(vbak.VDATU)) AS planned_delivery_date,
--   DATE_DIFF(DATE(TIMESTAMP(likp.WADAT_IST)), DATE(TIMESTAMP(vbak.VDATU)), DAY) AS days_late
-- FROM
--   `sap-iac-test.GS4_CDC.lips` AS lips
-- INNER JOIN
--   `sap-iac-test.GS4_CDC.likp` AS likp
--   ON
--     lips.VBELN = likp.VBELN
-- INNER JOIN
--   `sap-iac-test.GS4_CDC.vbap` AS vbap
--   ON
--     lips.VGBEL = vbap.VBELN AND lips.VGPOS = vbap.POSNR
-- INNER JOIN
--   `sap-iac-test.GS4_CDC.vbak` AS vbak
--   ON
--     vbap.VBELN = vbak.VBELN
-- WHERE
--   DATE(TIMESTAMP(likp.WADAT_IST)) > DATE(TIMESTAMP(vbak.VDATU))
-- ORDER BY
--   days_late DESC,
--   material_number);

-- 3. Quality Blocked
-- 1. fetch stock number, name, part id from inventorybyplant where characteristic = blocked 


