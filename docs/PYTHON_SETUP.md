# RavenStack — Python EDA setup

This notebook performs **descriptive analysis** on `analytics.vw_account_360` in SQL Server and exports an account-level CSV for Power BI. It does not train a predictive model.

## Requirements
- Python 3.10+ (recommended)
- Microsoft SQL Server with the RavenStack database, imported raw tables, and the final analytical views already created
- Microsoft **ODBC Driver 17 for SQL Server** installed (the notebook explicitly requests this driver)
- Windows Authentication permission for the account running Jupyter

## Run the notebook
1. From this project folder, create a Python environment and install dependencies:

   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1
   python -m pip install -r requirements.txt
   ```

2. In **the same PowerShell session**, set your local SQL Server instance name. Example only (replace with your real instance):

   ```powershell
   $env:SQL_SERVER = 'localhost\SQLEXPRESS'
   ```

3. Run `jupyter notebook` and open `customer_churn_eda.ipynb`. Select the installed environment/kernel, then **Run All**.
4. Confirm the checks report **500 unique accounts**, **110 ever-churned accounts**, **25,000 usage records**, and **5,568 date-valid usage records**. Those are reference values for the provided dataset and may change if the source data changes.
5. The final cell exports `data/processed/ravenstack_account_360.csv` relative to Jupyter's current working directory. For the expected location, start Jupyter from this folder.
6. In Power BI Desktop, update the CSV source path if the report was authored on another computer.

## Limitations
- The dataset is **synthetic**.
- `churn_flag` is an **ever-churned** historical indicator, not current status or monthly churn.
- Only 5,568 / 25,000 usage rows pass the project's date-window checks; these are **record counts**, distinct from summed usage actions.
- The historical sum of subscription MRR is **not current MRR or revenue**.
- Satisfaction averages exclude missing values; results are descriptive, not causal.

## Publishing notes
- Notebook outputs are retained for portfolio readability, except a local personal file path was removed from the final export output.
- Do not include actual database credentials, private paths, or proprietary/raw datasets without permission.
- The five original source CSVs are included under `data/raw/` with attribution to River @ Rivalytics; the generated processed CSV is ignored because it can be recreated by running this notebook.