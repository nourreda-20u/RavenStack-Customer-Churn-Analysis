# RavenStack — SQL Setup and Execution

This folder documents the SQL Server stage of the RavenStack Customer Churn & Retention Analysis portfolio project. The source dataset contains five CSV files, imported individually into SQL Server during the original project. The original analysis queries are preserved unchanged.

## Requirements

- Microsoft SQL Server and SQL Server Management Studio (SSMS), or an equivalent SQL Server client.
- Access to the five original RavenStack CSV datasets and permission to create a database and tables.

## Expected database structure

Database: `RavenStack_Churn`

Schemas: `raw` (imported source tables), `analytics` (analytical views).

| Raw table | Expected imported rows |
| --- | ---: |
| `raw.ravenstack_accounts` | 500 |
| `raw.ravenstack_subscriptions` | 5,000 |
| `raw.ravenstack_feature_usage` | 25,000 |
| `raw.ravenstack_support_tickets` | 2,000 |
| `raw.ravenstack_churn_events` | 600 |

These are observed project baselines, not automatically created data.

## Execution order

1. Run `sql/00_database_setup.sql`. It creates `RavenStack_Churn`, `raw`, and `analytics` if they don't exist. **It does not create the five source tables.**
2. Import the five CSVs **individually** into SQL Server, targeting the `raw` schema and the exact table names above. In SSMS, use the import workflow available for your version (for example Import Flat File, or Import Data). Check inferred column types and allow legitimate missing values. Ensure keys, dates, numeric and bit/boolean columns have appropriate SQL Server types.
3. Validate the imported tables and row counts before applying constraints. The source data must support the required keys and relationships. Original repeated `usage_id` values in feature usage must be retained; they should not be made into a unique primary key.
4. Run `sql/01_database_foundation.sql` **once**, on a freshly imported dataset. It adds the `FEUS_ID` identity primary key to feature usage and foreign keys to the other tables. **It is not idempotent**: rerunning it on already configured tables may fail because the column or constraints already exist.
5. Run `sql/02_data_quality.sql` to inspect missing values, repeated usage identifiers and other quality issues; inspection queries do not imply all flagged records should be deleted.
6. Run `sql/03_analytical_views.sql` to build the account-level analytics views, including `analytics.vw_account_360`.
7. Run `sql/04_final_validation.sql` to compare source and analytical view totals.

## Expected baseline checks

```sql
USE RavenStack_Churn;

SELECT COUNT(*) AS total_accounts,
       SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) AS ever_churned_accounts
FROM analytics.vw_account_360;

SELECT SUM(usage_record_count) AS recorded_usage_records,
       SUM(valid_usage_record_count) AS date_valid_usage_records
FROM analytics.vw_account_360;
```

The validated portfolio baselines are 500 accounts, 110 ever-churned accounts, 25,000 recorded usage records, and 5,568 date-valid usage records. Those validation numbers are descriptive checks, not guarantees on alternate source datasets.

## Important interpretation notes

- The account `churn_flag` is an **ever-churned** indicator, not a measure of present-day or monthly churn.
- The dataset is synthetic; associations should not be described as causal findings.
- Usage date-validity is limited (5,568 of 25,000 records, or 22.27%). The invalid-date categories can overlap.
- `recorded_mrr_sum` adds recorded subscription MRR values; it is **not** current MRR or recognized revenue.
- Account-level views aggregate data for descriptive analysis and are subsequently used by Python and Power BI.

## Reproducibility caveats

- The SQL scripts do **not** include original CSV files, `CREATE TABLE` definitions, or a fully automated import script. CSV import and schema/type verification are prerequisite manual steps, matching the original workflow.
- Exact dataset source and redistribution/license details should be linked from the top-level project README once verified. Do not assume redistribution permission.
- The SQL was reviewed statically for publishing instructions; it was **not rerun on a fresh SQL Server instance** as part of preparing this package.