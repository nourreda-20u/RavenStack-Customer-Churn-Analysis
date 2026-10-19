-- RavenStack Customer Churn Analysis
-- Set up the row key and relationships after importing the CSV files.

USE RavenStack_Churn;
GO

-- usage_id is repeated in the source, so keep it and add a unique row key.
ALTER TABLE raw.ravenstack_feature_usage
ADD FEUS_ID BIGINT IDENTITY(1,1) NOT NULL;
GO

ALTER TABLE raw.ravenstack_feature_usage
ADD CONSTRAINT PK_feature_usage PRIMARY KEY (FEUS_ID);
GO

ALTER TABLE raw.ravenstack_subscriptions
ADD CONSTRAINT FK_subscriptions_accounts
FOREIGN KEY (account_id) REFERENCES raw.ravenstack_accounts(account_id);

ALTER TABLE raw.ravenstack_feature_usage
ADD CONSTRAINT FK_feature_usage_subscriptions
FOREIGN KEY (subscription_id) REFERENCES raw.ravenstack_subscriptions(subscription_id);

ALTER TABLE raw.ravenstack_support_tickets
ADD CONSTRAINT FK_support_tickets_accounts
FOREIGN KEY (account_id) REFERENCES raw.ravenstack_accounts(account_id);

ALTER TABLE raw.ravenstack_churn_events
ADD CONSTRAINT FK_churn_events_accounts
FOREIGN KEY (account_id) REFERENCES raw.ravenstack_accounts(account_id);
GO
