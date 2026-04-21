-- 1. Check if ColorCode exists, add if missing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[LandingPage]') AND name = 'ColorCode')
BEGIN
    ALTER TABLE [dbo].[LandingPage] ADD [ColorCode] NVARCHAR(50) NULL;
END
GO

-- 2. Check if PageId exists, add as IDENTITY if missing
-- NOTE: If the table already has data but no PageId, adding an IDENTITY column is tricky.
-- This script assumes PageId might be missing or needs to be added as a primary key.
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[LandingPage]') AND name = 'PageId')
BEGIN
    -- If it doesn't exist, we add it. 
    -- To make it an IDENTITY and PRIMARY KEY safely:
    ALTER TABLE [dbo].[LandingPage] ADD [PageId] INT IDENTITY(1,1);
    
    -- Optional: If you want PageId to be the primary key instead of (Comp_Id, Service_Id)
    -- WARNING: This script does not drop the existing primary key.
END
GO
