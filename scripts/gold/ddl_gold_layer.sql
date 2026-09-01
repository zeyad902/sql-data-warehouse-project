/*
===============================================================================
Gold Layer Blueprint: Dimensional Modeling (Star Schema)
===============================================================================
Script Purpose:
    Creates the analytical views forming the Gold Layer (Data Mart). 
    Combines cleaned, normalized tables from the Silver Layer (CRM & ERP) 
    into dimension and fact structures optimized for reporting/BI tools.

Views Included:
    1. gold.dim_customer - Customer Dimension (CRM + ERP enrichment)
    2. gold.dim_product  - Product Dimension (Active products + Categories)
    3. gold.fact_sales   - Sales Fact Table (Transactional line items)
===============================================================================
*/

-- ============================================================================
-- 1. Customer Dimension: gold.dim_customer
-- Description: Integrates demographic and geographic attributes from CRM & ERP
-- ============================================================================
CREATE VIEW gold.dim_customer AS 
SELECT 
    -- Surrogate Key generation for the dimension
    ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
    
    -- Business Keys & Demographics (CRM Source)
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS frist_name,
    ci.cst_lastname AS last_name,
    
    -- Geographic Data (ERP Location)
    la.cntry As country,
    
    -- Marital Status & Gender Handling (CRM prioritized, ERP fallback)
    ci.cst_marital_status AS martial_status,
    CASE 
         WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
         ELSE COALESCE(ca.gen,'n/a')
    END AS gender,
    
    -- Audit & Temporal Metadata
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid
GO

-- ============================================================================
-- 2. Product Dimension: gold.dim_product
-- Description: Consolidates active products with hierarchy/categories from ERP
-- Filter: Excludes historical/inactive product revisions (prd_end_dt IS NULL)
-- ============================================================================
CREATE VIEW gold.dim_product AS 
SELECT
    -- Surrogate Key generation for the product dimension
    ROW_NUMBER() OVER(ORDER BY prd_id, prd_start_dt) AS product_key,
    
    -- Product Identifiers
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    
    -- Category Hierarchy (ERP Source)
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    
    -- Metrics & Line Info
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL 
GO

-- ============================================================================
-- 3. Sales Fact Table: gold.fact_sales
-- Description: Central fact table containing sales transactions joined back 
--              to Gold dimensions to resolve Surrogate Keys.
-- ============================================================================
CREATE VIEW gold.fact_sales AS
SELECT
    -- Transaction Identifiers
    sd.sls_ord_num AS order_number,
    
    -- Dimension Surrogate Keys (Foreign Keys)
    dp.product_key,
    dc.customer_key,
    
    -- Dates & Timestamps
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,
    
    -- Measures & Fact Metrics
    sd.sls_sales AS sales,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_product dp
    ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customer dc
    ON sd.sls_cust_id = dc.customer_id
GO
