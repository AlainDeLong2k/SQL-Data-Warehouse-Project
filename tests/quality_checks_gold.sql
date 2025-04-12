/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
	This script performs quality checks to validate the integrity, consistency,
	and accuracy of the 'gold' layer. These checks ensure:
	- Uniqueness of surrogate keys in dimension tables.
	- Referential integrity between fact and dimension tables.
	- Validation of relationships in the data model for analytical purposes.

Usage Notes:
	- Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
SELECT
	customer_key,
	COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT DISTINCT gender
FROM gold.dim_customers;

-- ====================================================================
-- Checking 'gold.dim_products'
-- ====================================================================
SELECT
	product_key,
	COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================
SELECT *
FROM gold.fact_sales sls
LEFT JOIN gold.dim_customers cst
	ON sls.customer_key = cst.customer_key
LEFT JOIN gold.dim_products prd
	ON sls.product_key = prd.product_key
WHERE cst.customer_key IS NULL OR prd.product_key IS NULL;


SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.fact_sales;


SELECT cst_id, COUNT(*) FROM (
SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON	ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON	ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1;

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON		ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON		ci.cst_key = la.cid
ORDER BY 1, 2;

SELECT prd_key, COUNT(*) FROM (
SELECT
	pd.prd_id,
	pd.cat_id,
	pd.prd_key,
	pd.prd_nm,
	pd.prd_cost,
	pd.prd_line,
	pd.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pd
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pd.cat_id = pc.id
WHERE pd.prd_end_dt IS NULL
)t GROUP BY prd_key
HAVING COUNT(*) > 1;


EXEC bronze.load_bronze;
EXEC silver.load_silver;
