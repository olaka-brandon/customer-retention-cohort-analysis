-- Set search_path parameter to your schema
SET SEARCH_PATH TO portfolio_schema;

-- Create table
CREATE TABLE cohort (
    InvoiceNo VARCHAR(50),
    StockCode VARCHAR(50),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(10, 2),
    CustomerID NUMERIC(10, 1),
    Country VARCHAR(255)
);

ALTER TABLE cohort
ALTER COLUMN customerid TYPE INT;

SELECT * FROM cohort;

-- DATA CLEANING
-- We have to filter out records with customerid = null since these are non-existent customers
-- Next, we filter out those with negatuve quantity as these are purchase returns 
-- Lastly, we check for and filter out the duplicates

-- Total records = 541,909
WITH cohort_retail AS (
    SELECT invoiceno, stockcode, description, quantity, invoicedate, unitprice, customerid, country
    FROM cohort
    WHERE customerid IS NOT NULL
	-- 135,080 records with customerid

), quantity_unit_price AS (
	SELECT * FROM cohort_retail
	WHERE quantity > 0 AND unitprice > 0
	-- 397,882 records with positive quantity

), dup_check AS (

	-- Duplicate check
	SELECT *, ROW_NUMBER() OVER (PARTITION BY invoiceno, stockcode, quantity ORDER BY invoicedate) dup_flag
	FROM quantity_unit_price

)
SELECT * INTO online_retail_main
FROM dup_check WHERE dup_flag=1;

-- 392,666 clean records
-- 5,214 duplicate records


-- COHORT ANALYSIS
-- We need unique identifiers(customerid), initial start date(first invoice date) and revenue data

SELECT 
	customerid,
	MIN(invoicedate) AS first_purchase_date,
	DATE_TRUNC('month', MIN(invoicedate)) AS cohort_date
INTO grouped_cohort
FROM online_retail_main
GROUP BY customerid;

SELECT * FROM grouped_cohort;

-- Create cohort index
SELECT 
	orm3.*,
	(year_diff * 12 + (month_diff +1)) AS cohort_index
INTO cohort_retention
FROM (
		SELECT 
	orm2.*,
	invoice_year - cohort_year AS year_diff,
	invoice_month - cohort_month AS month_diff
FROM (
			SELECT 
				orm.*,
				gc.cohort_date,
				EXTRACT(YEAR FROM orm.invoicedate) AS invoice_year,
				EXTRACT(MONTH FROM orm.invoicedate) AS invoice_month,
				EXTRACT(YEAR FROM gc.cohort_date) AS cohort_year,
				EXTRACT(MONTH FROM gc.cohort_date) AS cohort_month
			FROM online_retail_main orm
			LEFT JOIN grouped_cohort gc
			ON orm.customerid = gc.customerid
	) AS orm2 	
) AS orm3;


-- Finding distinct records in the cohort retention
SELECT DISTINCT
	customerid,
	cohort_date,
	cohort_index
FROM cohort_retention;

-- At this point, we can export the data for visualization

-- Find out the number of indices there and copy into the pivot table query below
SELECT DISTINCT
cohort_index
FROM cohort_retention;

-- Pivot data to see the cohort table
SELECT
    cohort_date,
    COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN customerid END) AS cohort_1,
    COUNT(DISTINCT CASE WHEN cohort_index = 2 THEN customerid END) AS cohort_2,
    COUNT(DISTINCT CASE WHEN cohort_index = 3 THEN customerid END) AS cohort_3,
    COUNT(DISTINCT CASE WHEN cohort_index = 4 THEN customerid END) AS cohort_4,
    COUNT(DISTINCT CASE WHEN cohort_index = 5 THEN customerid END) AS cohort_5,
    COUNT(DISTINCT CASE WHEN cohort_index = 6 THEN customerid END) AS cohort_6,
    COUNT(DISTINCT CASE WHEN cohort_index = 7 THEN customerid END) AS cohort_7,
    COUNT(DISTINCT CASE WHEN cohort_index = 8 THEN customerid END) AS cohort_8,
    COUNT(DISTINCT CASE WHEN cohort_index = 9 THEN customerid END) AS cohort_9,
    COUNT(DISTINCT CASE WHEN cohort_index = 10 THEN customerid END) AS cohort_10,
    COUNT(DISTINCT CASE WHEN cohort_index = 11 THEN customerid END) AS cohort_11,
    COUNT(DISTINCT CASE WHEN cohort_index = 12 THEN customerid END) AS cohort_12,
    COUNT(DISTINCT CASE WHEN cohort_index = 13 THEN customerid END) AS cohort_13
FROM cohort_retention
GROUP BY cohort_date;
--ORDER BY cohort_date;
