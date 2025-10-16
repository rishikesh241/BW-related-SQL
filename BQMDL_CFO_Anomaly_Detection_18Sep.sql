WITH ExpenseData AS (
    SELECT
        CompanyCode,
        FiscalYear,
        CAST(FiscalPeriod AS INT64) AS FiscalMonth,  
        CASE 
            WHEN CAST(FiscalPeriod AS INT64) BETWEEN 1 AND 3 THEN 1
            WHEN CAST(FiscalPeriod AS INT64) BETWEEN 4 AND 6 THEN 2
            WHEN CAST(FiscalPeriod AS INT64) BETWEEN 7 AND 9 THEN 3
            ELSE 4
        END AS FiscalQuarter,
        -- Separate calculation for Revenue
        SUM(CASE WHEN GLParentText = 'Gross Revenue' THEN AmountInTargetCurrency ELSE 0 END) AS Revenue, 
        -- Calculate Expenses by excluding 'Gross Revenue'
        SUM(CASE WHEN GLParentText <> 'Gross Revenue' THEN AmountInTargetCurrency ELSE 0 END) AS Expenses,
        CASE
            WHEN GLParentText = 'Gross Revenue' THEN 'Revenue'
            WHEN GLParentText = 'Travel Expense' THEN 'Travel Expense'
            WHEN GLParentText = 'Operating Expense' THEN 'Operating Expense'
            WHEN GLParentText = 'Cost of Goods Sold' THEN 'Cost of Goods Sold'
            WHEN GLParentText = 'Other Operating Expense' THEN 'Other Operating Expense' 
            ELSE 'Other'  -- This will capture any other expense types not explicitly listed
        END AS ExpenseType,
        CASE
         WHEN GLParentText = 'Gross Revenue' THEN 
            CASE GLNodeText
                WHEN 'Revenue Domestic - Product' THEN 'Domestic'
                WHEN 'Sales Revenue w/ Cost Element' THEN 'Sales w/ Cost Element'
                WHEN 'Revenue Foreign - Product' THEN 'Foreign'
                WHEN 'Revenue Affiliate - Product' THEN 'Affiliate'
                ELSE 'Other Revenue' 
            END
            WHEN GLParentText = 'Travel Expense' THEN
                CASE GLNodeText
                    WHEN 'Travel Expenses - Hotel and Accommodation' THEN 'Hotel'
                    WHEN 'Travel Expenses - Meals' THEN 'Meals'
                    WHEN 'Travel Expenses - Ground Transportation' THEN 'Ground Transportation'
                    WHEN 'Travel Expenses - Entertainment' THEN 'Entertainment'
                    WHEN 'Travel Expenses - Airfare, Rail, Mileage' THEN 'Airfare/Rail/Mileage'
                    WHEN 'Travel Expenses - Miscellaneous' THEN 'Miscellaneous'
                    ELSE 'Other Travel Expense' 
                END
            WHEN GLParentText = 'Operating Expense' THEN
                CASE GLNodeText
                    WHEN 'Employee Expense' THEN 'Employee'
                    WHEN 'Building Expense' THEN 'Building'
                    WHEN 'Depreciation & Amortization' THEN 'Depreciation & Amortization'
                    WHEN 'Other Operating Expense' THEN 'Other' 
                    ELSE 'Other Operating Expense' 
                END
            WHEN GLParentText = 'Other Operating Expense' THEN 
                CASE GLNodeText
                    WHEN 'Bad Debt Expense' THEN 'Bad Debt'
                    WHEN 'Advertising and Sales Costs' THEN 'Advertising & Sales'
                    WHEN 'Marketing Expenses' THEN 'Marketing'
                    WHEN 'Subcontracting Services' THEN 'Subcontracting'
                    WHEN 'Other Operating Expenses' THEN 'Other' 
                    WHEN 'Commission/Charge (TRM)' THEN 'Commission/Charge'
                    WHEN 'Other Expenses (TRM)' THEN 'Other (TRM)'
                    WHEN 'Cash Discounts Expense' THEN 'Cash Discounts'
                    ELSE 'Other Operating Expense' 
                END
            WHEN GLParentText = 'Cost of Goods Sold' THEN 
                CASE GLNodeText
                    WHEN 'Cost of Goods Sold (SF & Finish Goods w/o Cost El)' THEN 'COGS (SF & Finish Goods w/o Cost El)'
                    WHEN 'COGS Third Party' THEN 'COGS Third Party'
                    WHEN 'Consumption - Raw Material' THEN 'Consumption - Raw Material'
                    WHEN 'Consumption - Packaging Material' THEN 'Consumption - Packaging Material'
                    WHEN 'Consumption - Trading Goods' THEN 'Consumption - Trading Goods'
                    WHEN 'Consumption - Subcontracting' THEN 'Consumption - Subcontracting'
                    WHEN 'Loss Price Variance (PRD)' THEN 'Loss Price Variance'
                    WHEN 'Inventory Change - Cost of own Goods sold w/C.Elem' THEN 'Inventory Change - Cost of own Goods sold w/C.Elem'
                    WHEN 'Inventory Change - Scrap own Products' THEN 'Inventory Change - Scrap own Products'
                    WHEN 'Inventory Change - Finished Goods' THEN 'Inventory Change - Finished Goods'
                    WHEN 'Adjustment Plant Activity Production Order' THEN 'Adjustment Plant Activity Production Order'
                    WHEN 'Cost of Goods Sold (Affiliated)' THEN 'COGS (Affiliated)'
                    WHEN 'Discount Received' THEN 'Discount Received'
                    ELSE 'Other COGS' 
                END
            ELSE NULL  -- This will assign NULL to ExpSubType for any other GLParentText
        END AS ExpSubType,
        SUM(AmountInTargetCurrency) AS AmountInTargetCurrency  -- This now represents the total amount for the specific ExpenseType and ExpSubType
    FROM `projgcpsbx.cortex_cfo_s4_reporting.ProfitAndLoss`
    WHERE AmountInLocalCurrency <> 0 
        --AND CompanyCode = 'C006' 
        AND FiscalYear IN ('2022', '2023')  
        AND LedgerInGeneralLedgerAccounting = '0L' 
        AND LanguageKey_SPRAS = 'E' 
        AND CurrencyKey = 'USD'
        AND (
            GLParentText IN ('Gross Revenue', 'Travel Expense', 'Operating Expense', 'Cost of Goods Sold', 'Other Operating Expense') 
            -- This condition now only includes the relevant expense GLParentText values
        )
    GROUP BY CompanyCode, FiscalYear, FiscalMonth, FiscalQuarter, ExpenseType, ExpSubType
),

-- Calculate monthly aggregates
MonthlyAggregates AS (
  SELECT
      CompanyCode,
      FiscalYear,
      FiscalMonth,
      ExpenseType,
      ExpSubType,
      AVG(AmountInTargetCurrency) AS AvgMonthlyExpense,
      STDDEV(AmountInTargetCurrency) AS StdDevMonthlyExpense
  FROM ExpenseData
  GROUP BY CompanyCode, FiscalYear, FiscalMonth, ExpenseType, ExpSubType
),

-- Calculate quarterly aggregates
QuarterlyAggregates AS (
  SELECT
      CompanyCode,
      FiscalYear,
      FiscalQuarter,
      ExpenseType,
      ExpSubType,
      AVG(AmountInTargetCurrency) AS AvgQuarterlyExpense,
      STDDEV(AmountInTargetCurrency) AS StdDevQuarterlyExpense
  FROM ExpenseData
  GROUP BY CompanyCode, FiscalYear, FiscalQuarter, ExpenseType, ExpSubType
),

-- Combine the data and calculate anomaly flags
AnomalyDetection AS (
    SELECT
        ed.CompanyCode,
        ed.FiscalYear,
        ed.FiscalMonth,
        ed.FiscalQuarter,
        ed.ExpenseType,
        ed.ExpSubType,
        ed.AmountInTargetCurrency AS ExpenseAmount,
        ma.AvgMonthlyExpense,
        ma.StdDevMonthlyExpense,
        qa.AvgQuarterlyExpense,
        qa.StdDevQuarterlyExpense,
        (ed.AmountInTargetCurrency - ma.AvgMonthlyExpense) / NULLIF(ma.AvgMonthlyExpense, 0) AS MonthlyPercentDeviation,
        (ed.AmountInTargetCurrency - ma.AvgMonthlyExpense) / NULLIF(ma.StdDevMonthlyExpense, 0) AS MonthlyZScore,
        (ed.AmountInTargetCurrency - qa.AvgQuarterlyExpense) / NULLIF(qa.AvgQuarterlyExpense, 0) AS QuarterlyPercentDeviation,
        (ed.AmountInTargetCurrency - qa.AvgQuarterlyExpense) / NULLIF(qa.StdDevQuarterlyExpense, 0) AS QuarterlyZScore,
        ed.Revenue -- Include the Revenue column here
    FROM ExpenseData ed
    JOIN MonthlyAggregates ma ON ed.CompanyCode = ma.CompanyCode
      AND ed.FiscalYear = ma.FiscalYear
      AND ed.FiscalMonth = ma.FiscalMonth
      AND ed.ExpenseType = ma.ExpenseType
      AND ed.ExpSubType = ma.ExpSubType
    JOIN QuarterlyAggregates qa ON ed.CompanyCode = qa.CompanyCode
      AND ed.FiscalYear = qa.FiscalYear
      AND ed.FiscalQuarter = qa.FiscalQuarter
      AND ed.ExpenseType = qa.ExpenseType
      AND ed.ExpSubType = qa.ExpSubType
)

SELECT 
    *,
    CASE
        WHEN ABS(MonthlyPercentDeviation) > 0.5 OR ABS(MonthlyZScore) > 3 OR ABS(QuarterlyPercentDeviation) > 0.5 OR ABS(QuarterlyZScore) > 3 THEN 'High Anomaly'
        WHEN ABS(MonthlyPercentDeviation) > 0.3 OR ABS(MonthlyZScore) > 2 OR ABS(QuarterlyPercentDeviation) > 0.3 OR ABS(QuarterlyZScore) > 2 THEN 'Medium Anomaly'
        WHEN ABS(MonthlyPercentDeviation) > 0.2 OR ABS(MonthlyZScore) > 1 OR ABS(QuarterlyPercentDeviation) > 0.2 OR ABS(QuarterlyZScore) > 1 THEN 'Low Anomaly'
        ELSE 'Not Anomaly'
    END AS AnomalyFlag,
    CASE
        WHEN ABS(MonthlyPercentDeviation) > 0.5 OR ABS(MonthlyZScore) > 3 OR ABS(QuarterlyPercentDeviation) > 0.5 OR ABS(QuarterlyZScore) > 3 THEN 'Yes'
        ELSE 'No'  
    END AS NeedsAction
FROM AnomalyDetection
ORDER BY FiscalYear, FiscalMonth, ExpenseType, ExpSubType;