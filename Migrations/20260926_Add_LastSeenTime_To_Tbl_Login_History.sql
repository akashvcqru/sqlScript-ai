-- ============================================================================
-- Migration: Add LastSeenTime column to Tbl_Login_History
-- Date: 2026-09-26
-- Description: Adds LastSeenTime to track active sessions for Vendor Heartbeat 
--              and Admin Online Vendors report.
-- ============================================================================

IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Tbl_Login_History' 
      AND COLUMN_NAME = 'LastSeenTime'
)
BEGIN
    ALTER TABLE [dbo].[Tbl_Login_History]
    ADD [LastSeenTime] DATETIME NULL;
    
    PRINT 'Column LastSeenTime added successfully to Tbl_Login_History.';
END
ELSE
BEGIN
    PRINT 'Column LastSeenTime already exists in Tbl_Login_History.';
END
GO

-- Populate initial LastSeenTime from LoginTime for existing rows where null
UPDATE [dbo].[Tbl_Login_History]
SET [LastSeenTime] = [LoginTime]
WHERE [LastSeenTime] IS NULL AND [LoginTime] IS NOT NULL;
GO
