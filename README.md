# RavenStack | Customer Churn & Retention Analysis

**End-to-end data analytics case study · SQL Server · Python · Power BI**

RavenStack is a synthetic SaaS customer dataset. This project builds an account-level analytical dataset from five related tables, investigates historical churn patterns, and presents the results in a three-page Power BI report.

> **Scope:** Descriptive and exploratory analysis, **not** a churn prediction model. "Ever churned" means an account was flagged as churned at some point; it is **not** current churn status or a monthly churn rate.

## Dashboard

The Power BI report includes three pages:

| Page | Focus |
| --- | --- |
| **Home** | Project introduction, headline metrics and navigation |
| **Customer Churn Overview** | Account counts and ever-churned shares by industry, plan tier and seat band |
| **Customer Experience & Engagement** | Subscription history, plan changes, product usage validity, support activity and satisfaction |

The screenshots and downloadable `Ravenstack.pbix` report will be linked here once their binary files are uploaded under `assets/screenshots/` and `powerbi/`. The report should be opened in **Power BI Desktop**; page-navigation buttons can be tested with **Ctrl + Click** in edit mode.

## Business questions

- How does historical churn vary by industry, plan tier and account size?
- How do subscription counts, upgrades and downgrades differ between churn groups?
- What proportion of product-usage records can be used after temporal validity checks?
- What do account-level support activity and available satisfaction scores show?
- Which data-quality limitations constrain business interpretations?

## Data source and credits

**[SaaS Subscription & Churn Analytics Dataset — Kaggle](https://www.kaggle.com/datasets/rivalytics/saas-subscription-and-churn-analytics-dataset)**, created by **River @ Rivalytics**.

The five source CSV files were imported individually into SQL Server. The dataset is **synthetic**, not customer information from a real business. Source documentation credits the author and describes its terms as *“MIT-like”*, rather than a standard, unambiguous license identifier. To avoid assuming redistribution rights, **the raw CSV files are not republished here**; download them from the original Kaggle page.

| Source table | Records |
| --- | ---: |
| Accounts | 500 |
| Subscriptions | 5,000 |
| Feature usage | 25,000 |
| Support tickets | 2,000 |
| Churn events | 600 |
| **Total** | **33,100** |

## Workflow

```text
Kaggle source: five CSV files
          ↓
SQL Server
Import → relational checks → data-quality audit → analytical views → validation
          ↓
analytics.vw_account_360 (one row per account)
          ↓
Python / pandas / seaborn
Descriptive EDA → churn-group comparisons → processed account-level CSV
          ↓
Power BI Desktop
Home → Churn Overview → Experience & Engagement
```

### 1. SQL Server

The scripts in [`sql/`](sql/) prepare the database, document quality issues and create account-level analytical views. Important checks include duplicated `usage_id` values, foreign-key integrity, usage before signup, usage outside subscription periods, inconsistent support timestamps and churn-event discrepancies.

Repeated source `usage_id` values are not silently deleted: a surrogate `FEUS_ID` is used for feature-usage row identity. Related tables are aggregated **before** the final account-level joins to avoid multiplying their measures.

**Execution order:** `00_database_setup.sql` → manually import the five CSV files into the `raw` schema → `01_database_foundation.sql` → `02_data_quality.sql` → `03_analytical_views.sql` → `04_final_validation.sql`.

The import is intentionally documented as a manual SQL Server step, matching the actual project. Script `00` creates the database/schemas **but not the CSV-derived tables**; script `01` should be run **once** on the imported data. See [SQL setup](docs/SQL_SETUP.md).

### 2. Python EDA

[`notebooks/customer_churn_eda.ipynb`](notebooks/customer_churn_eda.ipynb) reads `analytics.vw_account_360` using SQLAlchemy and pyodbc. It performs account-level descriptive comparisons, constructs size groups and exports `data/processed/ravenstack_account_360.csv` for Power BI. No predictive model is trained.

The connection uses a local `SQL_SERVER` environment variable. See [Python setup](docs/PYTHON_SETUP.md).

### 3. Power BI

The report features consistent navigation, slicers, KPI cards and account-level comparisons. See [Power BI setup](docs/POWERBI_SETUP.md) for opening the saved report, validating baseline metrics and updating the CSV source path if a refresh is needed.

## Key findings

| Metric | Finding |
| --- | ---: |
| Distinct accounts | **500** |
| Ever-churned accounts | **110** |
| Ever-churned share | **22.00%** |
| Logged feature-usage records | **25,000** |
| Date-valid feature-usage records | **5,568** |
| Date-valid usage coverage | **22.27%** |

- **Customer segments:** DevTools has the highest observed industry ever-churned share in this dataset: **35 of 113 accounts (30.97%)**.
- **Subscription history:** Average subscription records per account are similar: approximately **10.29** for Ever Churned versus **9.92** for Never Flagged.
- **Support:** Mean ticket counts are approximately **3.93** (Ever Churned) versus **4.02** (Never Flagged). Mean escalation counts are **0.22** versus **0.18**.
- **Satisfaction:** Mean available valid account-level satisfaction is approximately **4.03** (Ever Churned) versus **3.94** (Never Flagged), on a five-point scale.

These are **descriptive associations**, not evidence of what caused churn.

## Data quality and interpretation

- **Historical target:** Account `churn_flag` means **ever churned**, not current status. Account flags and churn-event history do not fully agree.
- **Limited usage coverage:** Only **5,568 / 25,000** usage rows pass checks against account signup and subscription windows. Invalid-date categories overlap; do not sum them.
- **Rows vs actions:** **22.27%** is the share of date-valid **usage rows**, not the share of `usage_count` actions.
- **MRR terminology:** `recorded_mrr_sum` adds historical subscription MRR entries, **not** current recurring revenue or recognized revenue.
- **Missing satisfaction:** Unavailable valid satisfaction scores are excluded, not treated as zero. The dashboard compares account-level means, not a ticket-weighted grand mean.
- **Synthetic limitations:** These results demonstrate a workflow; they are not business claims about a real company.

## Reproduce this project

**Requirements:** SQL Server and SSMS, the five source CSVs from Kaggle, Python 3.10+, Jupyter, Microsoft ODBC Driver 17 for SQL Server, and Power BI Desktop.

1. Download the source CSVs from the [original Kaggle dataset](https://www.kaggle.com/datasets/rivalytics/saas-subscription-and-churn-analytics-dataset).
2. Follow [SQL setup](docs/SQL_SETUP.md) to create `RavenStack_Churn`, import the CSVs, build the views and run validation.
3. From the repository root, prepare Python and start Jupyter:

   ```powershell
   python -m pip install -r requirements.txt
   $env:SQL_SERVER = 'YOUR_SQL_SERVER_INSTANCE'
   jupyter notebook
   ```

4. Open [the notebook](notebooks/customer_churn_eda.ipynb) and **Run All**. Start Jupyter from the repository root so the processed CSV is exported to `data/processed/`.
5. Open `powerbi/Ravenstack.pbix` in Power BI Desktop once it has been added to the repository. If refreshing the data on a different computer, update the file path in Power Query / data-source settings.
6. Validate unfiltered results: **500** accounts, **110** ever churned (**22%**), and **5,568** date-valid usage rows out of **25,000** (**22.27%**).

**Reproducibility note:** The original SQL and Power BI workflow was executed during the project, but this publishing package has **not** been freshly rerun end-to-end on a clean computer.

## Repository structure

```text
.
├── README.md
├── requirements.txt
├── .gitignore
├── sql/
│   ├── 00_database_setup.sql
│   ├── 01_database_foundation.sql
│   ├── 02_data_quality.sql
│   ├── 03_analytical_views.sql
│   └── 04_final_validation.sql
├── notebooks/
│   └── customer_churn_eda.ipynb
├── docs/
│   ├── SQL_SETUP.md
│   ├── PYTHON_SETUP.md
│   └── POWERBI_SETUP.md
├── data/processed/
│   └── .gitkeep
├── powerbi/                 # Add Ravenstack.pbix
└── assets/screenshots/      # Add three dashboard screenshots
```

**Data availability:** Source data is hosted by [River @ Rivalytics on Kaggle](https://www.kaggle.com/datasets/rivalytics/saas-subscription-and-churn-analytics-dataset). This repository excludes raw CSVs and the generated processed CSV. Once uploaded, the PBIX contains its own imported data snapshot, but refreshing it elsewhere may require changing the CSV path.
