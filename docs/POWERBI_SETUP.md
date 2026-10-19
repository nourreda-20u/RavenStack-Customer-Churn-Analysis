# Power BI Report — RavenStack

## Included report
- `Ravenstack.pbix` — existing report, copied without modification.
- The report contains three pages in order:
  1. Home
  2. Customer Churn Overview
  3. Customer Experience & Engagement

## Open and verify
1. Open `Ravenstack.pbix` in Power BI Desktop.
2. On Home, use **Ctrl + Click** on navigation buttons in edit mode.
3. Check each page for rendering issues and confirm slicers and navigation work.
4. Clear all filters; expected baselines are 500 accounts, 110 ever-churned accounts (22%), 25,000 recorded usage records, 5,568 date-valid usage records (22.27%).
5. The data connection or refresh may require updating the local processed CSV path. Opening the saved report is not the same as successfully refreshing it.

## Screenshots for GitHub
Approved Power BI Desktop screenshots are prepared for publication in:
- `assets/screenshots/01_home_cover.png`
- `assets/screenshots/02_customer_churn_overview.png`
- `assets/screenshots/03_customer_experience_engagement.png`

These image files must be uploaded separately to GitHub; they are not in the repository yet.

To create each: select the page, use Fit to page, hide the editing panes if needed, and use Windows Snipping Tool. Save a clear full-page PNG without exposing personal file paths.

## Interpretation notes
- The source data is synthetic.
- `churn_flag` denotes ever-churned status, not current-month churn.
- Date-valid usage coverage is based on records meeting account signup and subscription-period date checks.

## Verification status
PBIX file and page metadata were inspected. Power BI Desktop execution, button interactions, data refresh, and final screenshots were not independently tested in this environment.