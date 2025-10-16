DECLARE trend_start_date DATE DEFAULT PARSE_DATE('%d-%b-%y', '13-Apr-25');
DECLARE trend_end_date DATE DEFAULT PARSE_DATE('%d-%b-%y', '03-May-25');

WITH ParsedInvoices AS (
    SELECT
        Invoice_ID,
        Posting_date,
        Net_due_date,
        Amount,
        Clearing_document,
        Clearing_date
    FROM
        sap-iac-test.proj24_test.Invoices_Data
),
DateSeries AS (
    -- Generate a series of dates for the trend analysis range
    SELECT
        DISTINCT calendar_date
    FROM
        UNNEST(GENERATE_DATE_ARRAY(
            trend_start_date,
            trend_end_date,
            INTERVAL 1 DAY
        )) AS calendar_date
),
OutstandingInvoicesDaily AS (
    SELECT
        ds.calendar_date,
        pi.Invoice_ID,
        pi.Posting_date,
        pi.Clearing_date,
        pi.Amount,
        -- An invoice is outstanding on calendar_date if:
        -- 1. It has no clearing document OR
        -- 2. Its clearing date is AFTER the calendar_date
        CASE
            WHEN pi.Net_due_date < ds.calendar_date and (pi.Clearing_document IS NULL OR pi.Clearing_date >= ds.calendar_date)
            THEN TRUE
            ELSE FALSE
        END AS IsOutstandingOnDate,
        -- Calculate the age based on the calendar_date or clearing date if it falls before calendar_date
        CASE
            WHEN pi.Net_due_date < ds.calendar_date and (pi.Clearing_document IS NULL OR pi.Clearing_date >= ds.calendar_date)
                THEN DATE_DIFF(ds.calendar_date, pi.Net_due_date, DAY)
            ELSE 0
        END AS Invoice_Age_Days
    FROM
        DateSeries ds
    CROSS JOIN
        ParsedInvoices pi
    WHERE
        pi.Posting_date <= ds.calendar_date -- Only consider invoices posted on or before the calendar_date
),
DailyTrend AS (
    SELECT
        calendar_date,
        COUNT(DISTINCT Invoice_ID) AS Number_of_Outstanding_Invoices,
        AVG(Invoice_Age_Days) AS Average_Outstanding_Age,
        SUM(Amount) AS Total_Outstanding_Amount
    FROM
        OutstandingInvoicesDaily
    WHERE
        IsOutstandingOnDate = TRUE
    GROUP BY
        calendar_date
)
SELECT
    dt.calendar_date,
    dt.Number_of_Outstanding_Invoices,
    dt.Average_Outstanding_Age,
    dt.Total_Outstanding_Amount,
    LAG(dt.Average_Outstanding_Age, 1) OVER (ORDER BY dt.calendar_date) AS Previous_Day_Average_Age,
    dt.Average_Outstanding_Age - LAG(dt.Average_Outstanding_Age, 1) OVER (ORDER BY dt.calendar_date) AS Change_In_Average_Age
FROM
    DailyTrend dt
ORDER BY
    dt.calendar_date;

