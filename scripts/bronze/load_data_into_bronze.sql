CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    SET NOCOUNT ON;

    -- Local variables for step and overall duration tracking
    DECLARE @step_start_time DATETIME, @step_end_time DATETIME;
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
    DECLARE @proc_start_time DATETIME, @proc_end_time DATETIME;

    BEGIN TRY
        SET @proc_start_time = GETDATE();

        -- =========================================================================
        -- Procedure Name : bronze.load_bronze
        -- Description    : Truncates and loads raw CSV datasets into Bronze tables.
        -- Target Schema  : bronze
        -- Source System  : CRM & ERP CSV Files
        -- =========================================================================

        PRINT '================================================';
        PRINT 'Starting Bronze Layer Data Load...';
        PRINT '================================================';

        -- =========================================================================
        -- Step 1: Load CRM Data (Customer, Product, and Sales Information)
        -- =========================================================================
        SET @batch_start_time = GETDATE();
        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables...';
        PRINT '------------------------------------------------';

        -- Step 1.1: Truncate and load Customer Info
        PRINT '>> Loading: bronze.crm_cust_info';
        SET @step_start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_cust_info;
        BULK INSERT bronze.crm_cust_info
        FROM 'D:\college\Data Analysis\PROJECTS\data warehouse project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @step_end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';

        -- Step 1.2: Truncate and load Product Info
        PRINT '>> Loading: bronze.crm_prd_info';
        SET @step_start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_prd_info;
        BULK INSERT bronze.crm_prd_info
        FROM 'D:\college\Data Analysis\PROJECTS\data warehouse project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @step_end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';

        -- Step 1.3: Truncate and load Sales Details
        PRINT '>> Loading: bronze.crm_sales_details';
        SET @step_start_time = GETDATE();
        TRUNCATE TABLE bronze.crm_sales_details;
        BULK INSERT bronze.crm_sales_details
        FROM 'D:\college\Data Analysis\PROJECTS\data warehouse project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @step_end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';

        SET @batch_end_time = GETDATE();
        PRINT '-> Total CRM Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

        -- =========================================================================
        -- Step 2: Load ERP Data (Customer, Location, and Product Category Data)
        -- =========================================================================
        SET @batch_start_time = GETDATE();
        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables...';
        PRINT '------------------------------------------------';

        -- Step 2.1: Truncate and load ERP Customer Data (AZ12)
        PRINT '>> Loading: bronze.erp_cust_az12';
        SET @step_start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_cust_az12;
        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\college\Data Analysis\PROJECTS\data warehouse project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @step_end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';

        -- Step 2.2: Truncate and load ERP Location Data (A101)
        PRINT '>> Loading: bronze.erp_loc_a101';
        SET @step_start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_loc_a101;
        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\college\Data Analysis\PROJECTS\data warehouse project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @step_end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';

        -- Step 2.3: Truncate and load ERP Product Category Data (PX_CAT_G1V2)
        PRINT '>> Loading: bronze.erp_px_cat_g1v2';
        SET @step_start_time = GETDATE();
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\college\Data Analysis\PROJECTS\data warehouse project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @step_end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @step_start_time, @step_end_time) AS NVARCHAR) + ' seconds';

        SET @batch_end_time = GETDATE();
        PRINT '-> Total ERP Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

        SET @proc_end_time = GETDATE();
        PRINT '================================================';
        PRINT 'Bronze Layer Data Load Completed Successfully!';
        PRINT 'Total Procedure Duration: ' + CAST(DATEDIFF(second, @proc_start_time, @proc_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';
    END TRY
    BEGIN CATCH 
        PRINT '===========================================';
        PRINT 'ERROR OCCURED DURING LOADING';
        PRINT '===========================================';
        PRINT 'ERROR Message: ' + ERROR_MESSAGE();
        PRINT 'ERROR Number: '  + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR State: '   + CAST(ERROR_STATE() AS NVARCHAR);
    END CATCH
END;