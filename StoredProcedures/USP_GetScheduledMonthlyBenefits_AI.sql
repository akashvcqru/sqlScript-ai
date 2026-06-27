USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antigravity
-- Create date: 2026-06-27
-- Description:	Fetches companies that have monthly benefits enabled and scheduled for today directly from BrandSettings_AI (JSON format) and haven't run yet this calendar month.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetScheduledMonthlyBenefits_AI]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @CurrentDay INT = DAY(GETDATE());
    DECLARE @CurrentTime TIME = CAST(GETDATE() AS TIME);
    DECLARE @ScheduledTime TIME = CAST('12:00:00' AS TIME);

    SELECT 
        Comp_ID, 
        TRY_CAST(JSON_VALUE(MonthlyBenefits, '$.DayOfMonth') AS INT) AS DayOfMonth
    FROM BrandSettings_AI
    WHERE MonthlyBenefits IS NOT NULL
      -- Check if Enabled
      AND JSON_VALUE(MonthlyBenefits, '$.IsEnabled') = 'true'
      -- Check if today is the scheduled day of month
      AND (
          JSON_VALUE(MonthlyBenefits, '$.DayOfMonth') IS NULL 
          OR TRY_CAST(JSON_VALUE(MonthlyBenefits, '$.DayOfMonth') AS INT) = @CurrentDay
      )
      -- Check if current time is >= 12:00 PM
      AND (@CurrentTime >= @ScheduledTime)
      -- Check if it hasn't run successfully this calendar month yet
      AND (
          JSON_VALUE(MonthlyBenefits, '$.LastRunDate') IS NULL 
          OR NOT (
              YEAR(TRY_CAST(JSON_VALUE(MonthlyBenefits, '$.LastRunDate') AS DATETIME)) = YEAR(GETDATE())
              AND MONTH(TRY_CAST(JSON_VALUE(MonthlyBenefits, '$.LastRunDate') AS DATETIME)) = MONTH(GETDATE())
          )
      );
END
GO
