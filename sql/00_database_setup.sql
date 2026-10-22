-- RavenStack Customer Churn Analysis
-- Create the database and schemas used in the project.

IF DB_ID('RavenStack_Churn') IS NULL
    CREATE DATABASE RavenStack_Churn;
GO

USE RavenStack_Churn;
GO

IF SCHEMA_ID('raw') IS NULL
    EXEC('CREATE SCHEMA raw');

IF SCHEMA_ID('analytics') IS NULL
    EXEC('CREATE SCHEMA analytics');
GO

SELECT
    DB_NAME() AS database_name,
    name AS schema_name
FROM sys.schemas
WHERE name IN ('raw', 'analytics')
ORDER BY name;
GO
