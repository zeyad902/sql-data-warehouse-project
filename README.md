# SQL Server Data Warehouse

## Project Overview

This project demonstrates the design and implementation of an end-to-end **SQL Server Data Warehouse** using a **Bronze → Silver → Gold** architecture.

The goal was to transform raw CRM and ERP data into a clean, integrated, and analytics-ready data warehouse that can support reporting and business analysis.

The project covers the complete data warehouse workflow:

**Source Data → Data Ingestion → Data Cleaning → Data Integration → Data Modeling → Analytics**

---

## Why Build a Data Warehouse?

The source data comes from different CRM and ERP systems and contains issues such as:

- Duplicate records
- Inconsistent values
- Missing data
- Different data formats
- Invalid dates and numerical values
- Data distributed across multiple source systems

Using the raw source data directly for analysis would make reporting more difficult and inconsistent.

The Data Warehouse provides a structured environment where data can be:

- Collected from different sources
- Cleaned and standardized
- Integrated into a single model
- Organized for analytical workloads

The result is a reliable **single source of truth** for business analysis.

---

## Data Sources

The project integrates data from two source systems:

### CRM

Provides:

- Customer information
- Product information
- Sales transactions

### ERP

Provides:

- Customer demographic information
- Customer location information
- Product category information

Combining these systems allows the warehouse to create a more complete view of customers, products, and sales.

---

## Architecture

The project follows a **Medallion Architecture**:

**CRM & ERP CSV Files → Bronze → Silver → Gold**

![Data Warehouse Architecture](images/data_architecture.png)

Each layer has a specific responsibility.

---

## Bronze Layer — Raw Data

The Bronze layer is the landing zone for the source data.

### What I Did

I created six Bronze tables representing the CRM and ERP source systems:

- `crm_cust_info`
- `crm_prd_info`
- `crm_sales_details`
- `erp_cust_az12`
- `erp_loc_a101`
- `erp_px_cat_g1v2`

The data is loaded from CSV files using `BULK INSERT` through a stored procedure.

The loading process follows a **full-load approach**:

**TRUNCATE → BULK INSERT**

It also includes error handling and execution-time tracking.

### Why?

The Bronze layer preserves the source data before applying transformations.

This creates a clear separation between:

**Raw Data → Transformed Data**

It also provides a reliable starting point for the following ETL stages.

---

## Silver Layer — Clean & Transform

The Silver layer prepares the raw data for integration and analysis.

### What I Did

I applied several data quality and transformation steps, including:

- Removing duplicate customers
- Standardizing gender and marital status
- Trimming text values
- Handling missing values
- Standardizing product information
- Correcting invalid sales and price values
- Converting date formats
- Cleaning customer and location identifiers
- Standardizing countries
- Deriving product validity periods

For example, duplicate customers were handled using `ROW_NUMBER()` to keep the latest record.

Product validity periods were derived using the `LEAD()` window function.

### Why?

Raw source data is not always suitable for analysis.

The Silver layer creates a **clean, standardized, and consistent version of the data** before it reaches the business layer.

This prevents data quality issues from propagating into the final analytical model.

---

## Gold Layer — Business-Ready Data

The Gold layer contains the final data model used for analytics.

I created a **Star Schema** consisting of:

- `gold.fact_sales`
- `gold.dim_customer`
- `gold.dim_product`

![Star Schema](images/data_model_(star_schema).png)

### Why a Star Schema?

Operational source systems are designed primarily for transactional processes, while analytical workloads require a model that is easier to understand and query.

The Star Schema separates:

- **Facts:** measurable business events
- **Dimensions:** descriptive business attributes

This makes analytical queries simpler and provides a clear structure for future BI and reporting solutions.

---

## Data Integration

One of the main objectives of the project was integrating information from multiple source systems.

### Customer Integration

```text
CRM Customer
      +
ERP Customer Information
      +
ERP Location
      ↓
dim_customer
```

### Product Integration

```text
CRM Product
      +
ERP Product Category
      ↓
dim_product
```

This creates a unified view of customers and products that can be connected to the sales fact table.

---

## Gold Data Model

### Fact Table

#### `gold.fact_sales`

Contains sales transactions and measures such as:

- Sales
- Quantity
- Price
- Order Date
- Ship Date
- Due Date

**60,398 records**

---

### Customer Dimension

#### `gold.dim_customer`

Contains customer attributes integrated from CRM and ERP, including:

- Customer information
- Country
- Gender
- Marital status
- Birth date
- Creation date

A surrogate key is used to connect customers to the fact table.

---

### Product Dimension

#### `gold.dim_product`

Combines product information from CRM with product category information from ERP.

It contains attributes such as:

- Product
- Category
- Subcategory
- Product Line
- Cost
- Start Date

Product validity periods are derived in the Silver layer using `LEAD()`, while the Gold view exposes the currently active product records.

---

## Data Warehouse Flow

The complete process can be summarized as:

```text
        CRM / ERP
           CSV
            │
            ▼
     ┌──────────────┐
     │    Bronze    │
     │  Raw Data    │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │    Silver    │
     │ Clean &      │
     │ Transform    │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │     Gold     │
     │ Star Schema  │
     └──────┬───────┘
            │
            ▼
       Analytics /
       BI / Reporting
```

The main idea is to separate **data ingestion, transformation, and business modeling into independent layers**.

---

## Data Quality

Several data quality problems were identified and handled during the ETL process:

- Duplicate customer records
- Missing values
- Inconsistent categorical values
- Invalid dates
- Invalid sales values
- Invalid prices
- Inconsistent country names
- Product data requiring standardization

These issues were handled primarily in the Silver layer so that the Gold layer remains clean and suitable for analytical workloads.

---

## Project Scale

| Layer | Object | Records |
|---|---|---:|
| Bronze | CRM Customers | 18,493 |
| Bronze | CRM Products | 397 |
| Bronze | CRM Sales | 60,398 |
| Bronze | ERP Customers | 18,483 |
| Bronze | ERP Locations | 18,484 |
| Bronze | ERP Categories | 37 |
| Gold | Customers | 18,484 |
| Gold | Products | 295 |
| Gold | Sales | 60,398 |

---

## Analytical SQL

The Gold layer was also used to answer several business questions and validate that the warehouse can support analytical workloads.

### What are the overall business KPIs?

- **Total Sales:** 29.36M
- **Total Orders:** 27,659
- **Total Customers:** 18,484
- **Quantity Sold:** 60,423
- **Average Selling Price:** 486

### Which year generated the highest sales?

**2013**

- Sales: **16.34M**
- Orders: **21,287**

### Which product generated the highest sales?

**Mountain-200 Black-46**

- Sales: **1.37M**
- Quantity: **620**

### Which category performs best?

**Bikes**

- Sales: **28.32M**

### Which subcategory performs best?

**Road Bikes**

- Sales: **14.52M**

### Which country generates the most sales?

**United States**

- Sales: **9.16M**

### Who are the highest-value customers?

The top customers generated approximately **13K** in sales each, with **Nichole Nara** and **Kaitlyn Henderson** both reaching **13,294** in sales.

> The analytical section is included to demonstrate how the Gold layer can be used for business analysis. The main focus of the project is the Data Warehouse architecture and implementation.

---

## Example Analytical Query

```sql
SELECT TOP 10
    p.product_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_sales DESC;
```

This query identifies the top-performing products by revenue.

---

## How to Run

### Prerequisites

- SQL Server
- SQL Server Management Studio (SSMS)
- Access to the source CSV files
- Git (optional)

### Execution Order

Run the scripts in the following order:

```text
1. create_database.sql
        ↓
2. create_bronze_layer.sql
        ↓
3. loading_data_into_bronze.sql
        ↓
4. create_silver_tables.sql
        ↓
5. loading_data_into_silver.sql
        ↓
6. ddl_gold_layer.sql
        ↓
7. analytical_queries.sql
```

Before running the Bronze loading script, make sure the CSV file paths inside the `BULK INSERT` statements match your local environment.

---

## Project Structure

```text
SQL-Data-Warehouse/
│
├── datasets/
│
├── scripts/
│   ├── create_database.sql
│   ├── create_bronze_layer.sql
│   ├── loading_data_into_bronze.sql
│   ├── create_silver_tables.sql
│   ├── loading_data_into_silver.sql
│   ├── ddl_gold_layer.sql
│   └── analytical_queries.sql
│
├── images/
│   ├── data_architecture.png
│   └── data_model_(star_schema).png
│
└── README.md
```

---

## SQL & Data Warehousing Skills

- SQL Server
- T-SQL
- ETL
- Medallion Architecture
- Data Cleaning
- Data Standardization
- Data Integration
- Stored Procedures
- `BULK INSERT`
- CTEs
- Window Functions
- `ROW_NUMBER()`
- `LEAD()`
- Joins & Aggregations
- Surrogate Keys
- Fact & Dimension Tables
- Star Schema
- Analytical SQL

---

## Technologies

<p align="left">
  <a href="https://www.microsoft.com/en-us/sql-server">
    <img src="https://skillicons.dev/icons?i=sqlserver" alt="SQL Server" width="45" height="45"/>
  </a>
  <a href="https://learn.microsoft.com/en-us/sql/t-sql/language-reference">
    <img src="https://skillicons.dev/icons?i=sql" alt="T-SQL" width="45" height="45"/>
  </a>
  <a href="https://learn.microsoft.com/en-us/ssms/sql-server-management-studio-ssms">
    <img src="https://skillicons.dev/icons?i=visualstudio" alt="SSMS" width="45" height="45"/>
  </a>
  <a href="https://git-scm.com/">
    <img src="https://skillicons.dev/icons?i=git" alt="Git" width="45" height="45"/>
  </a>
  <a href="https://github.com/">
    <img src="https://skillicons.dev/icons?i=github" alt="GitHub" width="45" height="45"/>
  </a>
</p>

**Core Concepts:** Data Warehousing · ETL · Dimensional Modeling

## Author

## Author

**Zeyad Mohamed Goda**

[GitHub](https://github.com/zeyad902) · [LinkedIn](https://www.linkedin.com/in/zeyad-mohamed-goda/)
