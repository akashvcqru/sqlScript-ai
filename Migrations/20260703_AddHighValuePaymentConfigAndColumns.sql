-- Migration: Add high-value payment configuration table and flag
USE [vcqru]
GO

IF OBJECT_ID('dbo.tbl_HighValuePaymentConfig', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[tbl_HighValuePaymentConfig](
        [Row_ID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Comp_ID] [varchar](50) NOT NULL,
        [Amount] [decimal](18, 2) NOT NULL,
        [Isactive] [bit] NOT NULL DEFAULT 1,
        [Created_Date] [datetime] NOT NULL DEFAULT GETDATE()
    );
END
GO

-- Seed default configuration if not present
IF NOT EXISTS (SELECT 1 FROM tbl_HighValuePaymentConfig WHERE Comp_ID = 'DEFAULT')
BEGIN
    INSERT INTO tbl_HighValuePaymentConfig (Comp_ID, Amount, Isactive, Created_Date)
    VALUES ('DEFAULT', 10000.00, 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ClaimDetails') AND name = 'IsHighValue')
BEGIN
    ALTER TABLE ClaimDetails ADD IsHighValue BIT NOT NULL DEFAULT 0;
END
GO
