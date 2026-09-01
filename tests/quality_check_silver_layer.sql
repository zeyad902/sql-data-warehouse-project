/*
===============================================================================
Quality Checks - Silver Layer Data Validation
===============================================================================
Script Purpose:
    Performs data quality (DQ), integrity, and consistency validations across 
    the Silver Layer tables (CRM and ERP sources).

Validation Categories:
    1. Primary Key Integrity (Uniqueness & Non-nullability)
    2. Data Hygiene (Unwanted leading/trailing whitespaces)
    3. Value Standardizations & Domain Integrity (Categorical checks)
    4. Business Logic & Mathematical Consistency (Sales calculations)
    5. Temporal Integrity (Valid date formats, sequence logic, and domain limits)

Usage Notes:
    - Execute after loading or refreshing the Silver Layer.
    - All queries expect 0 rows returned (or clean distinct value lists).
    - Any returned rows indicate data anomalies requiring remediation.
===============================================================================
*/

-- ====================================================================
-- 1. Checking 'silver.crm_cust_info'
-- Description: Customer profile and demographic data validation
-- ====================================================================

-- Check 1.1: Primary Key Uniqueness & Nullability
-- Business Rule: cst_id must be unique and never NULL.
-- Expectation: 0 rows (No duplicates, no NULL keys).
SELECT 
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 
    OR cst_id IS NULL;

-- Check 1.2: Whitespace Formatting
-- Business Rule: cst_key must be trimmed without leading/trailing spaces.
-- Expectation: 0 rows.
SELECT 
    cst_key 
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- Check 1.3: Data Standardization & Domain Integrity
-- Rationale: Review distinct values to ensure consistent casing and terms.
-- Expectation: Clean list of standardized categories (e.g., Single, Married, n/a).
SELECT DISTINCT 
    cst_marital_status 
FROM silver.crm_cust_info;


-- ====================================================================
-- 2. Checking 'silver.crm_prd_info'
-- Description: Product master catalog validation
-- ====================================================================

-- Check 2.1: Primary Key Uniqueness & Nullability
-- Business Rule: prd_id must be unique and never NULL.
-- Expectation: 0 rows.
SELECT 
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 
    OR prd_id IS NULL;

-- Check 2.2: Whitespace Formatting
-- Business Rule: Product names must not contain padding spaces.
-- Expectation: 0 rows.
SELECT 
    prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check 2.3: Numeric Range Integrity
-- Business Rule: Product costs must be non-null positive numbers.
-- Expectation: 0 rows.
SELECT 
    prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 
   OR prd_cost IS NULL;

-- Check 2.4: Data Standardization & Domain Integrity
-- Rationale: Verify product line taxonomy consistency across items.
-- Expectation: Clean list of valid product line codes/names.
SELECT DISTINCT 
    prd_line 
FROM silver.crm_prd_info;

-- Check 2.5: Chronological Integrity
-- Business Rule: Effective end date cannot occur before start date.
-- Expectation: 0 rows.
SELECT 
    prd_id,
    prd_start_dt,
    prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ====================================================================
-- 3. Checking 'silver.crm_sales_details'
-- Description: Sales transaction line items validation
-- ====================================================================

-- Check 3.1: Raw Date Format & Range Integrity (Bronze Layer Check)
-- Business Rule: Due dates must be valid 8-digit YYYYMMDD integers within bounds.
-- Note: Queries bronze layer to flag raw data issues before transformation.
-- Expectation: 0 rows.
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
   OR LEN(sls_due_dt) != 8 
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

-- Check 3.2: Date Order Logic
-- Business Rule: Ship and due dates must occur on or after the order date.
-- Expectation: 0 rows.
SELECT 
    sls_ord_num,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check 3.3: Mathematical Consistency & Field Validity
-- Business Rule: Sales = Quantity * Price; Metrics must be strictly positive and non-null.
-- Expectation: 0 rows.
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price)
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- ====================================================================
-- 4. Checking 'silver.erp_cust_az12'
-- Description: ERP Customer demographic enrichment validation
-- ====================================================================

-- Check 4.1: Temporal Bounds & Reasonable Range
-- Business Rule: Birthdates must be historically plausible (> 1924) and not in the future.
-- Expectation: 0 rows returned outside acceptable parameters.
SELECT DISTINCT 
    bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();

-- Check 4.2: Data Standardization & Domain Integrity
-- Rationale: Audit gender mapping consistency (e.g., Male, Female, n/a).
-- Expectation: Clean, standardized value domain.
SELECT DISTINCT 
    gen 
FROM silver.erp_cust_az12;


-- ====================================================================
-- 5. Checking 'silver.erp_loc_a101'
-- Description: ERP Location data validation
-- ====================================================================

-- Check 5.1: Data Standardization & Domain Integrity
-- Rationale: Verify country names/codes for formatting anomalies or duplicates.
-- Expectation: Alphabetical list of normalized country designations.
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ====================================================================
-- 6. Checking 'silver.erp_px_cat_g1v2'
-- Description: Product category hierarchy validation
-- ====================================================================

-- Check 6.1: Whitespace Formatting
-- Business Rule: Text fields must be trimmed without leading or trailing spaces.
-- Expectation: 0 rows.
SELECT 
    id,
    cat,
    subcat,
    maintenance
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- Check 6.2: Data Standardization & Domain Integrity
-- Rationale: Confirm valid categorical values for maintenance flags.
-- Expectation: Clean list of distinct maintenance attributes.
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;
