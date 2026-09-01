/*
===============================================================================
Gold Layer Data Quality & Data Model Integrity Checks
===============================================================================
Script Purpose:
    Validates the Gold Layer (Data Mart) star-schema architecture. Ensures:
    - Primary / Surrogate Key uniqueness across Dimension tables.
    - Referential integrity and zero orphaned foreign keys in Fact tables.

Usage Notes:
    - Execute after building Gold Layer views/tables.
    - All validation queries expect 0 rows returned.
    - Any returned rows flag key collisions or join mismatches.
===============================================================================
*/

-- ====================================================================
-- 1. Customer Dimension Validation: gold.dim_customers
-- ====================================================================

-- Check 1.1: Surrogate Key Uniqueness
-- Business Rule: customer_key must be strictly unique across all dimension records.
-- Expectation: 0 rows.
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- 2. Product Dimension Validation: gold.dim_products
-- ====================================================================

-- Check 2.1: Surrogate Key Uniqueness
-- Business Rule: product_key must be strictly unique across all active dimension records.
-- Expectation: 0 rows.
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- 3. Sales Fact Model Connectivity: gold.fact_sales
-- ====================================================================

-- Check 3.1: Referential Integrity & Orphan Records Check
-- Business Rule: Every fact transaction must successfully resolve to a Customer and Product dimension key.
-- Expectation: 0 rows (Unmatched joins indicate missing dimension records or broken key logic).
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL 
   OR c.customer_key IS NULL;
