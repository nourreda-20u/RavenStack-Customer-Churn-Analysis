-- RavenStack Customer Churn Analysis
-- Prepare account-level data for Python and Power BI.

USE RavenStack_Churn;
GO

-- Subscription amounts are recorded values, not current revenue.
CREATE OR ALTER VIEW analytics.vw_account_subscriptions AS
SELECT
    account_id,
    COUNT(*) AS subscription_count,
    SUM(mrr_amount) AS recorded_mrr_sum,
    AVG(CAST(mrr_amount AS decimal(18,2))) AS avg_subscription_mrr,
    SUM(CASE WHEN upgrade_flag = 1 THEN 1 ELSE 0 END) AS upgrade_count,
    SUM(CASE WHEN downgrade_flag = 1 THEN 1 ELSE 0 END) AS downgrade_count,
    SUM(CASE WHEN is_trial = 1 THEN 1 ELSE 0 END) AS trial_subscription_count
FROM raw.ravenstack_subscriptions
GROUP BY account_id;
GO

-- Keep every usage record, but only count activity within the account and subscription dates as valid.
CREATE OR ALTER VIEW analytics.vw_account_usage AS
SELECT
    s.account_id,
    COUNT(*) AS usage_record_count,
    SUM(u.usage_count) AS recorded_usage_count,
    SUM(CASE WHEN u.usage_date < a.signup_date THEN 1 ELSE 0 END) AS usage_before_signup_count,
    SUM(CASE WHEN u.usage_date < s.start_date OR
                   (s.end_date IS NOT NULL AND u.usage_date > s.end_date)
             THEN 1 ELSE 0 END) AS usage_outside_subscription_count,
    SUM(CASE WHEN u.usage_date >= a.signup_date
                  AND u.usage_date >= s.start_date
                  AND (s.end_date IS NULL OR u.usage_date <= s.end_date)
             THEN 1 ELSE 0 END) AS valid_usage_record_count,
    SUM(CASE WHEN u.usage_date >= a.signup_date
                  AND u.usage_date >= s.start_date
                  AND (s.end_date IS NULL OR u.usage_date <= s.end_date)
             THEN u.usage_count ELSE 0 END) AS valid_usage_count,
    SUM(CASE WHEN u.usage_date >= a.signup_date
                  AND u.usage_date >= s.start_date
                  AND (s.end_date IS NULL OR u.usage_date <= s.end_date)
             THEN u.error_count ELSE 0 END) AS valid_error_count,
    COUNT(DISTINCT CASE WHEN u.usage_date >= a.signup_date
                            AND u.usage_date >= s.start_date
                            AND (s.end_date IS NULL OR u.usage_date <= s.end_date)
                       THEN u.feature_name END) AS valid_distinct_features,
    MAX(CASE WHEN u.usage_date >= a.signup_date
                  AND u.usage_date >= s.start_date
                  AND (s.end_date IS NULL OR u.usage_date <= s.end_date)
             THEN u.usage_date END) AS last_valid_usage_date
FROM raw.ravenstack_feature_usage AS u
JOIN raw.ravenstack_subscriptions AS s ON u.subscription_id = s.subscription_id
JOIN raw.ravenstack_accounts AS a ON s.account_id = a.account_id
GROUP BY s.account_id;
GO

-- Exclude pre-signup tickets and invalid response timing from support performance measures.
CREATE OR ALTER VIEW analytics.vw_account_support AS
SELECT
    t.account_id,
    COUNT(*) AS ticket_count,
    SUM(CASE WHEN CAST(t.submitted_at AS date) < a.signup_date THEN 1 ELSE 0 END) AS tickets_before_signup_count,
    SUM(CASE WHEN t.closed_at IS NOT NULL
                  AND DATEADD(MINUTE, t.first_response_time_minutes, CAST(t.submitted_at AS datetime2)) > t.closed_at
             THEN 1 ELSE 0 END) AS response_after_closure_count,
    SUM(CASE WHEN t.escalation_flag = 1 THEN 1 ELSE 0 END) AS escalation_count,
    AVG(CASE WHEN CAST(t.submitted_at AS date) >= a.signup_date
             THEN CAST(t.satisfaction_score AS decimal(18,2)) END) AS avg_valid_satisfaction,
    AVG(CASE WHEN CAST(t.submitted_at AS date) >= a.signup_date
                  AND (t.closed_at IS NULL OR
                       DATEADD(MINUTE, t.first_response_time_minutes, CAST(t.submitted_at AS datetime2)) <= t.closed_at)
             THEN CAST(t.resolution_time_hours AS decimal(18,2)) END) AS avg_valid_resolution_hours
FROM raw.ravenstack_support_tickets AS t
JOIN raw.ravenstack_accounts AS a ON t.account_id = a.account_id
GROUP BY t.account_id;
GO

-- Churn events describe history and do not replace the account churn flag.
CREATE OR ALTER VIEW analytics.vw_account_churn_events AS
SELECT
    account_id,
    COUNT(*) AS event_count,
    SUM(CASE WHEN is_reactivation = 0 THEN 1 ELSE 0 END) AS churn_event_count,
    SUM(CASE WHEN is_reactivation = 1 THEN 1 ELSE 0 END) AS reactivation_event_count,
    MIN(CASE WHEN is_reactivation = 0 THEN churn_date END) AS first_churn_event_date,
    SUM(refund_amount_usd) AS recorded_refund_sum
FROM raw.ravenstack_churn_events
GROUP BY account_id;
GO

-- Aggregate child tables first to keep one row per account.
CREATE OR ALTER VIEW analytics.vw_account_360 AS
SELECT
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    a.signup_date,
    a.referral_source,
    a.plan_tier,
    a.seats,
    a.is_trial,
    a.churn_flag,
    COALESCE(s.subscription_count, 0) AS subscription_count,
    COALESCE(s.recorded_mrr_sum, 0) AS recorded_mrr_sum,
    s.avg_subscription_mrr,
    COALESCE(s.upgrade_count, 0) AS upgrade_count,
    COALESCE(s.downgrade_count, 0) AS downgrade_count,
    COALESCE(s.trial_subscription_count, 0) AS trial_subscription_count,
    COALESCE(u.usage_record_count, 0) AS usage_record_count,
    COALESCE(u.recorded_usage_count, 0) AS recorded_usage_count,
    COALESCE(u.usage_before_signup_count, 0) AS usage_before_signup_count,
    COALESCE(u.usage_outside_subscription_count, 0) AS usage_outside_subscription_count,
    COALESCE(u.valid_usage_record_count, 0) AS valid_usage_record_count,
    COALESCE(u.valid_usage_count, 0) AS valid_usage_count,
    COALESCE(u.valid_error_count, 0) AS valid_error_count,
    COALESCE(u.valid_distinct_features, 0) AS valid_distinct_features,
    u.last_valid_usage_date,
    COALESCE(t.ticket_count, 0) AS ticket_count,
    COALESCE(t.tickets_before_signup_count, 0) AS tickets_before_signup_count,
    COALESCE(t.response_after_closure_count, 0) AS response_after_closure_count,
    COALESCE(t.escalation_count, 0) AS escalation_count,
    t.avg_valid_satisfaction,
    t.avg_valid_resolution_hours,
    COALESCE(c.event_count, 0) AS event_count,
    COALESCE(c.churn_event_count, 0) AS churn_event_count,
    COALESCE(c.reactivation_event_count, 0) AS reactivation_event_count,
    c.first_churn_event_date,
    COALESCE(c.recorded_refund_sum, 0) AS recorded_refund_sum
FROM raw.ravenstack_accounts AS a
LEFT JOIN analytics.vw_account_subscriptions AS s ON a.account_id = s.account_id
LEFT JOIN analytics.vw_account_usage AS u ON a.account_id = u.account_id
LEFT JOIN analytics.vw_account_support AS t ON a.account_id = t.account_id
LEFT JOIN analytics.vw_account_churn_events AS c ON a.account_id = c.account_id;
GO
