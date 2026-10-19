-- RavenStack Customer Churn Analysis
-- Check the analytical views before using them in Python and Power BI.

USE RavenStack_Churn;
GO

-- The final view should contain one row for every account.
SELECT
    (SELECT COUNT(*) FROM raw.ravenstack_accounts) AS source_accounts,
    COUNT(*) AS view_accounts,
    COUNT(DISTINCT account_id) AS unique_accounts,
    SUM(CASE WHEN churn_flag = 1 THEN 1 ELSE 0 END) AS ever_churned_accounts
FROM analytics.vw_account_360;

-- Compare account-level totals with their original source tables.
SELECT
    'Subscriptions' AS metric,
    (SELECT COUNT(*) FROM raw.ravenstack_subscriptions) AS source_total,
    (SELECT SUM(subscription_count) FROM analytics.vw_account_360) AS view_total
UNION ALL
SELECT
    'Usage records',
    (SELECT COUNT(*) FROM raw.ravenstack_feature_usage),
    (SELECT SUM(usage_record_count) FROM analytics.vw_account_360)
UNION ALL
SELECT
    'Support tickets',
    (SELECT COUNT(*) FROM raw.ravenstack_support_tickets),
    (SELECT SUM(ticket_count) FROM analytics.vw_account_360)
UNION ALL
SELECT
    'Churn events',
    (SELECT COUNT(*) FROM raw.ravenstack_churn_events),
    (SELECT SUM(event_count) FROM analytics.vw_account_360);

-- Check that recorded subscription amounts and event refunds are not duplicated.
SELECT
    'Recorded MRR sum' AS metric,
    (SELECT SUM(mrr_amount) FROM raw.ravenstack_subscriptions) AS source_total,
    (SELECT SUM(recorded_mrr_sum) FROM analytics.vw_account_360) AS view_total
UNION ALL
SELECT
    'Recorded refunds',
    (SELECT SUM(refund_amount_usd) FROM raw.ravenstack_churn_events),
    (SELECT SUM(recorded_refund_sum) FROM analytics.vw_account_360);

-- Review the data quality exclusions carried into the final view.
SELECT
    SUM(usage_before_signup_count) AS usage_records_before_signup,
    SUM(tickets_before_signup_count) AS tickets_before_signup,
    SUM(valid_usage_record_count) AS valid_usage_records,
    SUM(usage_outside_subscription_count) AS usage_outside_subscription_records,
    SUM(response_after_closure_count) AS response_after_closure_tickets,
    SUM(valid_usage_count) AS usage_count_in_valid_period,
    SUM(valid_error_count) AS error_count_in_valid_period
FROM analytics.vw_account_360;
GO
