USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antigravity
-- Create date: 2026-06-22
-- Description:	Fetches companies that are enabled and scheduled for automatic claims right now and have not run today (hardcoded to 7:00 AM).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetScheduledAutomaticClaims_AI]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @CurrentDay INT = DAY(GETDATE());
    DECLARE @CurrentTime TIME = CAST(GETDATE() AS TIME);
    DECLARE @ScheduledTime TIME = CAST('07:00:00' AS TIME);

    SELECT Comp_id, DayOfMonth 
    FROM tbl_AutomaticClaimSettings
    WHERE IsAutoClaimEnable = 1
      -- Check if today is the scheduled day of month
      AND (DayOfMonth IS NULL OR DayOfMonth = @CurrentDay)
      -- Check if the current time is at or after the scheduled time (7:00 AM)
      AND (@CurrentTime >= @ScheduledTime)
      -- Check if it hasn't run successfully today yet (using 'CompanyRun' marker log)
      AND NOT EXISTS (
          SELECT 1 FROM tbl_AutoClaimData 
          WHERE Comp_id = tbl_AutomaticClaimSettings.Comp_id 
            AND M_Consumerid = 0
            AND Claim_Type = 'CompanyRun'
            AND CAST(Entry_Date AS DATE) = @CurrentDate
      );
END
GO
