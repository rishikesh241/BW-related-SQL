
-- SELECT matnr, erfmg, shkzg, budat, werks, mjahr, bwart FROM GS4_CDC.matdoc WHERE matnr IN (SELECT distinct matnr from GS4_CDC.matdoc WHERE erfmg >= 1500)

-- Available movement types 
-- 551: Issue without purchase order 
-- 261: Issue to production order 
-- 601: Issue to delivery 
-- 201: Issue to cost center 
-- SELECT distinct bwart FROM GS4_CDC.matdoc WHERE bwart IN ('101') WHERE budat BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 52 WEEK) AND CURRENT_DATE();

------ ************************ WEEKLY SNAPSHOTS TABLE ****************************
-- fetch the consumption details and create weekly snapshots 
CREATE OR REPLACE TABLE GS4_REPORTING.WEEKLY_CONSUMPTION AS (
WITH DailyTransactions AS (
  -- Step 1: Gather raw daily transactions, now including plant and fiscal year for joining
  SELECT 
    matnr AS materialnumber,
    werks AS plant,
    mjahr AS fiscalyear,
    budat AS postingdate,
    erfmg AS quantity,
    shkzg AS debcredind,
    bwart AS movement_type
  FROM 
    GS4_CDC.matdoc 
  WHERE 
    budat BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 52 WEEK) AND CURRENT_DATE()
    AND bwart IN ('201', '261', '221', '551', '601', '202', '262', '222','101')
    AND erfmg != 0
),

TransactionsWithPrice AS (
  -- Step 2: Join with Material Ledger to get the price for each transaction
  SELECT
    dt.materialnumber,
    dt.postingdate,
    -- Calculate net quantity for each individual transaction
    (dt.quantity * CASE WHEN dt.debcredind = 'S' THEN 1 ELSE -1 END) AS net_quantity,
    
    -- Calculate price_per_unit based on your specified logic
    CASE
      WHEN MovingAveragePrice > 0 THEN SAFE_DIVIDE(MovingAveragePrice, PriceUnit_PEINH) -- Moving Average Price
      WHEN StandardCost_STPRS > 0 THEN SAFE_DIVIDE(StandardCost_STPRS, PriceUnit_PEINH) -- Standard Cost
      ELSE 0
    END AS price_per_unit

  FROM DailyTransactions AS dt
  LEFT JOIN GS4_REPORTING.MaterialLedger AS ml
    ON dt.materialnumber = ml.materialnumber_matnr
    AND dt.plant = ml.valuationarea_bwkey
    AND dt.fiscalyear = ml.FiscalYear -- CRITICAL: Join on year
    AND EXTRACT(MONTH FROM dt.postingdate) = SAFE_CAST(ml.PostingPeriod AS INT64) -- Join on month
),

ActualWeeklyConsumption AS (
  -- Step 3: Aggregate transactions into weekly buckets, summing both quantity and value
  SELECT
    materialnumber,
    DATE_TRUNC(postingdate, WEEK) AS consumption_week,
    -- Sum the net quantities for the week
    SUM(net_quantity) AS weekly_net_quantity,
    -- Calculate total consumption value for the week
    SUM(net_quantity * price_per_unit) AS weekly_consumption_value
  FROM 
    TransactionsWithPrice
  GROUP BY 
    1, 2
),

-- Helper CTEs for creating the complete weekly template (Unchanged from previous query)
MaterialMaster AS (
  SELECT DISTINCT materialnumber FROM DailyTransactions
),
WeeksCalendar AS (
  SELECT week_start
  FROM UNNEST(GENERATE_DATE_ARRAY(
    DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 52 WEEK), WEEK), 
    DATE_TRUNC(CURRENT_DATE(), WEEK), 
    INTERVAL 1 WEEK
  )) AS week_start
),
MaterialWeekTemplate AS (
  SELECT m.materialnumber, w.week_start
  FROM MaterialMaster m
  CROSS JOIN WeeksCalendar w
)

-- Final Step: Join actuals to the template to fill in zero-consumption weeks
SELECT 
  template.materialnumber,
  md.materialtext_maktx as materialtext,
  template.week_start AS consumption_week,
  -- Use COALESCE to show 0 for weeks with no activity
  COALESCE(actuals.weekly_net_quantity, 0) AS final_net_consumption_quantity,
  COALESCE(actuals.weekly_consumption_value, 0) AS final_consumption_value
FROM 
  MaterialWeekTemplate AS template
LEFT JOIN 
GS4_REPORTING.MaterialsMD as md 
ON template.materialnumber = md.materialnumber_matnr
LEFT JOIN 
  ActualWeeklyConsumption AS actuals
  ON template.materialnumber = actuals.materialnumber 
  AND template.week_start = actuals.consumption_week
ORDER BY 
  template.materialnumber, 
  template.week_start DESC);
------ ************************ WEEKLY SNAPSHOTS TABLE ****************************


-- get the material price => Use the materialledger table GS4_REPORTING.MaterialLedger

-- For weekly consumption, we have the stock weekly snapshots table / inventorybyplant table 

--******************* ABC/XYZ ANALYSIS TABLE --*******************
CREATE OR REPLACE TABLE GS4_REPORTING.ABC_XYZ AS (
WITH MaterialMetrics AS (
  -- Step A & B (Prep): Aggregate the weekly data to get total value, average, and standard deviation for each material.
  SELECT
    materialnumber,
    -- ABC Metric: Total consumption value over the entire period
    SUM(final_consumption_value) AS total_consumption_value,
    -- XYZ Metrics: Average and Standard Deviation of weekly quantities
    AVG(final_net_consumption_quantity) AS avg_weekly_consumption,
    STDDEV_SAMP(final_net_consumption_quantity) AS stdev_weekly_consumption
  FROM
    GS4_REPORTING.WEEKLY_CONSUMPTION
  GROUP BY
    materialnumber
),


MaterialABCClassification AS (
  -- Step A (Classification): Calculate the cumulative value percentage and assign ABC class using window functions.
  SELECT
    materialnumber,
    total_consumption_value,
    avg_weekly_consumption,
    stdev_weekly_consumption,
    -- Calculate the cumulative percentage of the grand total value
    SUM(total_consumption_value) OVER (ORDER BY total_consumption_value DESC) / 
    SUM(total_consumption_value) OVER () AS cumulative_value_percentage
  FROM
    MaterialMetrics
)

-- Final Step: Assign XYZ class based on the Coefficient of Variation (CoV) and combine all results.
SELECT
  abc.materialnumber,
  -- ABC Analysis Results
  abc.total_consumption_value,
  CASE
    WHEN abc.cumulative_value_percentage <= 0.80 THEN 'A'
    WHEN abc.cumulative_value_percentage <= 0.95 THEN 'B'
    ELSE 'C'
  END AS abc_class,
  
  -- XYZ Analysis Results
  abc.avg_weekly_consumption,
  abc.stdev_weekly_consumption,
  -- Calculate Coefficient of Variation (CoV) to measure volatility
  SAFE_DIVIDE(abc.stdev_weekly_consumption, abc.avg_weekly_consumption) AS coefficient_of_variation,
  CASE
    WHEN abc.avg_weekly_consumption = 0 THEN 'Z' -- No movement or net-zero movement
    WHEN SAFE_DIVIDE(abc.stdev_weekly_consumption, abc.avg_weekly_consumption) < 0.5 THEN 'X'
    WHEN SAFE_DIVIDE(abc.stdev_weekly_consumption, abc.avg_weekly_consumption) <= 1.0 THEN 'Y'
    ELSE 'Z' -- Also catches any NULL CoV from SAFE_DIVIDE if stdev > 0 but avg = 0
  END AS xyz_class
FROM
  MaterialABCClassification AS abc
ORDER BY
  total_consumption_value DESC);
--******************* ABC/XYZ ANALYSIS TABLE --*******************

