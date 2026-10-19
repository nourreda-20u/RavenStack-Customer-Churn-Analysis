-- RavenStack Customer Churn Analysis
-- Check data quality before building the analytical views.

USE RavenStack_Churn;
GO

-- Row counts
SELECT 'accounts' AS table_name, COUNT(*) AS row_count FROM raw.ravenstack_accounts
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM raw.ravenstack_subscriptions
UNION ALL
SELECT 'feature_usage', COUNT(*) FROM raw.ravenstack_feature_usage
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM raw.ravenstack_support_tickets
UNION ALL
SELECT 'churn_events', COUNT(*) FROM raw.ravenstack_churn_events;

-- Missing values in fields used for analysis
SELECT 'subscriptions.end_date' AS field_name, COUNT(*) AS missing_count
FROM raw.ravenstack_subscriptions WHERE end_date IS NULL
UNION ALL
SELECT 'support_tickets.satisfaction_score', COUNT(*)
FROM raw.ravenstack_support_tickets WHERE satisfaction_score IS NULL
UNION ALL
SELECT 'churn_events.feedback_text', COUNT(*)
FROM raw.ravenstack_churn_events WHERE feedback_text IS NULL;

-- Repeated usage IDs are not necessarily duplicate records.
SELECT
    COUNT(*) AS repeated_ids,
    SUM(record_count) AS affected_rows
FROM (
    SELECT usage_id, COUNT(*) AS record_count
    FROM raw.ravenstack_feature_usage
    GROUP BY usage_id
    HAVING COUNT(*) > 1
) AS repeated_usage;

-- Check whether repeated IDs refer to identical source records.
WITH repeated_usage AS (
    SELECT usage_id
    FROM raw.ravenstack_feature_usage
    GROUP BY usage_id
    HAVING COUNT(*) > 1
),
unique_records AS (
    SELECT DISTINCT
        u.usage_id, u.subscription_id, u.usage_date, u.feature_name,
        u.usage_count, u.usage_duration_secs, u.error_count, u.is_beta_feature
    FROM raw.ravenstack_feature_usage AS u
    JOIN repeated_usage AS r ON u.usage_id = r.usage_id
)
SELECT usage_id, COUNT(*) AS distinct_record_versions
FROM unique_records
GROUP BY usage_id
ORDER BY usage_id;

-- Orphan records across the four relationships
SELECT 'subscriptions -> accounts' AS relationship, COUNT(*) AS orphan_rows
FROM raw.ravenstack_subscriptions AS s
LEFT JOIN raw.ravenstack_accounts AS a ON s.account_id = a.account_id
WHERE a.account_id IS NULL
UNION ALL
SELECT 'feature_usage -> subscriptions', COUNT(*)
FROM raw.ravenstack_feature_usage AS u
LEFT JOIN raw.ravenstack_subscriptions AS s ON u.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL
UNION ALL
SELECT 'support_tickets -> accounts', COUNT(*)
FROM raw.ravenstack_support_tickets AS t
LEFT JOIN raw.ravenstack_accounts AS a ON t.account_id = a.account_id
WHERE a.account_id IS NULL
UNION ALL
SELECT 'churn_events -> accounts', COUNT(*)
FROM raw.ravenstack_churn_events AS c
LEFT JOIN raw.ravenstack_accounts AS a ON c.account_id = a.account_id
WHERE a.account_id IS NULL;

-- Date issues, including activity recorded before account signup
SELECT 'subscriptions_before_signup' AS issue, COUNT(*) AS affected_rows
FROM raw.ravenstack_subscriptions AS s
JOIN raw.ravenstack_accounts AS a ON s.account_id = a.account_id
WHERE s.start_date < a.signup_date
UNION ALL
SELECT 'subscription_end_before_start', COUNT(*)
FROM raw.ravenstack_subscriptions
WHERE end_date < start_date
UNION ALL
SELECT 'feature_usage_before_signup', COUNT(*)
FROM raw.ravenstack_feature_usage AS u
JOIN raw.ravenstack_subscriptions AS s ON u.subscription_id = s.subscription_id
JOIN raw.ravenstack_accounts AS a ON s.account_id = a.account_id
WHERE u.usage_date < a.signup_date
UNION ALL
SELECT 'support_ticket_before_signup', COUNT(*)
FROM raw.ravenstack_support_tickets AS t
JOIN raw.ravenstack_accounts AS a ON t.account_id = a.account_id
WHERE CAST(t.submitted_at AS date) < a.signup_date
UNION ALL
SELECT 'support_closed_before_submitted', COUNT(*)
FROM raw.ravenstack_support_tickets
WHERE CAST(closed_at AS date) < CAST(submitted_at AS date)
UNION ALL
SELECT 'churn_event_before_signup', COUNT(*)
FROM raw.ravenstack_churn_events AS c
JOIN raw.ravenstack_accounts AS a ON c.account_id = a.account_id
WHERE c.churn_date < a.signup_date;

-- Invalid numeric values and support timing
SELECT 'invalid_subscription_values' AS issue, COUNT(*) AS affected_rows
FROM raw.ravenstack_subscriptions
WHERE seats <= 0 OR mrr_amount < 0 OR arr_amount < 0
UNION ALL
SELECT 'invalid_usage_values', COUNT(*)
FROM raw.ravenstack_feature_usage
WHERE usage_count < 0 OR usage_duration_secs < 0 OR error_count < 0
UNION ALL
SELECT 'invalid_support_values', COUNT(*)
FROM raw.ravenstack_support_tickets
WHERE resolution_time_hours < 0 OR first_response_time_minutes < 0
   OR satisfaction_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'support_response_after_closure', COUNT(*)
FROM raw.ravenstack_support_tickets
WHERE closed_at IS NOT NULL AND submitted_at IS NOT NULL
  AND DATEADD(MINUTE, first_response_time_minutes, CAST(submitted_at AS datetime2)) > closed_at
UNION ALL
SELECT 'negative_refunds', COUNT(*)
FROM raw.ravenstack_churn_events
WHERE refund_amount_usd < 0;

-- Compare account churn flags with the presence of event history.
WITH event_accounts AS (
    SELECT DISTINCT account_id
    FROM raw.ravenstack_churn_events
)
SELECT
    a.churn_flag,
    CASE WHEN e.account_id IS NULL THEN 0 ELSE 1 END AS has_churn_event,
    COUNT(*) AS account_count
FROM raw.ravenstack_accounts AS a
LEFT JOIN event_accounts AS e ON a.account_id = e.account_id
GROUP BY a.churn_flag, CASE WHEN e.account_id IS NULL THEN 0 ELSE 1 END
ORDER BY a.churn_flag, has_churn_event;
GO