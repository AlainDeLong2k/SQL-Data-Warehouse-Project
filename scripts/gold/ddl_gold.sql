/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
	This script creates views for the Gold layer in the data warehouse.
	The Gold layer represents the final dimension and fact tables (Star Schema)

	Each view performs transformation and combines data from the Silver layer
	to produce a clean, enriched, and business-ready dataset.

Usage:
	- These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- ====================================================================
-- Create Dimension Table: gold.dim_customers
-- ====================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT DISTINCT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate key
	ci.cst_id						AS customer_id,
	ci.cst_key						AS customer_number,
	ci.cst_firstname				AS first_name,
	ci.cst_lastname					AS last_name,
	la.cntry						AS country,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr  -- CRM is the primary source for gender
		ELSE COALESCE(ca.gen, 'n/a')				-- Fallback to ERP data
	END								AS gender,
	ci.cst_marital_status			AS marital_status,
	ca.bdate						AS birthdate,
	ci.cst_create_date				AS creat_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON	ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON	ci.cst_key = la.cid;
GO

-- ====================================================================
-- Create Dimension Table: gold.dim_products
-- ====================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pd.prd_start_dt, pd.prd_key) AS product_key,
	pd.prd_id		AS product_id,
	pd.prd_key		AS product_number,
	pd.prd_nm		AS product_name,
	pd.cat_id		AS category_id,
	pc.cat			AS category,
	pc.subcat		AS subcategory,
	pc.maintenance,
	pd.prd_cost		AS cost,
	pd.prd_line		AS product_line,
	pd.prd_start_dt AS start_date
FROM silver.crm_prd_info pd
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pd.cat_id = pc.id
WHERE pd.prd_end_dt IS NULL; -- Filter out all historical data
GO

-- ====================================================================
-- Create Fact Table: gold.fact_sales
-- ====================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num	AS order_number,
	prd.product_key,
	cst.customer_key,
	sd.sls_order_dt	AS order_date,
	sd.sls_ship_dt	AS shipping_date,
	sd.sls_due_dt	AS due_date,
	sd.sls_sales	AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price	AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products prd
	ON sd.sls_prd_key = prd.product_number
LEFT JOIN gold.dim_customers cst
	ON sd.sls_cust_id = cst.customer_id;
GO