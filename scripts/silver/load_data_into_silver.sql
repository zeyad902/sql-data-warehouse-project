CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    -- Track total batch timing
    DECLARE @batch_start_time DATETIME = GETDATE();
    DECLARE @batch_end_time DATETIME;

    -- Track individual table load timing
    DECLARE @start_time DATETIME;
    DECLARE @end_time DATETIME;

    BEGIN TRY
        PRINT '=================================================================';
        PRINT '         STARTING SILVER LAYER ETL LOAD PROCESS                  ';
        PRINT '=================================================================';
        PRINT 'Batch Start Time: ' + CONVERT(VARCHAR(20), @batch_start_time, 120);
        PRINT '-----------------------------------------------------------------';

        -- =========================================================================
        -- 1. Load Table: silver.crm_cust_info
        -- =========================================================================
        SET @start_time = GETDATE();
        PRINT '>> [1/6] Truncating and Loading: silver.crm_cust_info';
        PRINT '   Start Time: ' + CONVERT(VARCHAR(20), @start_time, 120);

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            -- Standardize Marital Status values
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            -- Standardize Gender values
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            -- Subquery to rank records and identify the most recent entry per customer ID
            SELECT 
                *,
                ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t 
        WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '   End Time:   ' + CONVERT(VARCHAR(20), @end_time, 120);
        PRINT '   Duration:   ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '-----------------------------------------------------------------';

        -- =========================================================================
        -- 2. Load Table: silver.crm_prd_info
        -- =========================================================================
        SET @start_time = GETDATE();
        PRINT '>> [2/6] Truncating and Loading: silver.crm_prd_info';
        PRINT '   Start Time: ' + CONVERT(VARCHAR(20), @start_time, 120);

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT 
            prd_id,
            -- Extract category ID from product key structure (e.g., replace '-' with '_')
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            -- Extract actual product key starting from 7th character
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            -- Default NULL cost to 0
            ISNULL(prd_cost, 0) AS prd_cost,
            -- Standardize Product Line codes
            CASE 
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other sales'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            prd_start_dt,
            -- Calculate end date as (next record start date - 1 day) for historical tracking
            DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '   End Time:   ' + CONVERT(VARCHAR(20), @end_time, 120);
        PRINT '   Duration:   ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '-----------------------------------------------------------------';

        -- =========================================================================
        -- 3. Load Table: silver.crm_sales_details
        -- =========================================================================
        SET @start_time = GETDATE();
        PRINT '>> [3/6] Truncating and Loading: silver.crm_sales_details';
        PRINT '   Start Time: ' + CONVERT(VARCHAR(20), @start_time, 120);

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- Convert Order Date from YYYYMMDD integer to DATE type
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            -- Convert Ship Date from YYYYMMDD integer to DATE type
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            -- Convert Due Date from YYYYMMDD integer to DATE type
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            -- Recalculate sales amount if missing, negative, or inconsistent with quantity * price
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            -- Recalculate unit price if missing or non-positive (uses NULLIF to prevent division by zero)
            CASE 
                WHEN sls_price <= 0 OR sls_price IS NULL 
                THEN sls_sales / NULLIF(sls_quantity, 0) 
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '   End Time:   ' + CONVERT(VARCHAR(20), @end_time, 120);
        PRINT '   Duration:   ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '-----------------------------------------------------------------';

        -- =========================================================================
        -- 4. Load Table: silver.erp_cust_az12
        -- =========================================================================
        SET @start_time = GETDATE();
        PRINT '>> [4/6] Truncating and Loading: silver.erp_cust_az12';
        PRINT '   Start Time: ' + CONVERT(VARCHAR(20), @start_time, 120);

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            -- Remove 'NAS' prefix if present
            CASE 
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,
            -- Nullify future birth dates
            CASE 
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            -- Standardize Gender values
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '   End Time:   ' + CONVERT(VARCHAR(20), @end_time, 120);
        PRINT '   Duration:   ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '-----------------------------------------------------------------';

        -- =========================================================================
        -- 5. Load Table: silver.erp_loc_a101
        -- =========================================================================
        SET @start_time = GETDATE();
        PRINT '>> [5/6] Truncating and Loading: silver.erp_loc_a101';
        PRINT '   Start Time: ' + CONVERT(VARCHAR(20), @start_time, 120);

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT DISTINCT
            REPLACE(cid, '-', '') AS cid,
            -- Standardize Country names
            CASE 
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '   End Time:   ' + CONVERT(VARCHAR(20), @end_time, 120);
        PRINT '   Duration:   ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '-----------------------------------------------------------------';

        -- =========================================================================
        -- 6. Load Table: silver.erp_px_cat_g1v2
        -- =========================================================================
        SET @start_time = GETDATE();
        PRINT '>> [6/6] Truncating and Loading: silver.erp_px_cat_g1v2';
        PRINT '   Start Time: ' + CONVERT(VARCHAR(20), @start_time, 120);

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT 
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '   End Time:   ' + CONVERT(VARCHAR(20), @end_time, 120);
        PRINT '   Duration:   ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '-----------------------------------------------------------------';

        -- Overall Summary Print
        SET @batch_end_time = GETDATE();
        PRINT '=================================================================';
        PRINT '         SILVER LAYER LOAD COMPLETED SUCCESSFULLY                ';
        PRINT '=================================================================';
        PRINT 'Batch End Time:   ' + CONVERT(VARCHAR(20), @batch_end_time, 120);
        PRINT 'Total Duration:   ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR(10)) + ' second(s)';
        PRINT '=================================================================';

    END TRY
    BEGIN CATCH
        PRINT '=================================================================';
        PRINT 'ERROR OCCURRED DURING LOAD PROCESS!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
        PRINT 'Error State:   ' + CAST(ERROR_STATE() AS VARCHAR(10));
        PRINT '=================================================================';
        THROW;
    END CATCH
END;
GO
