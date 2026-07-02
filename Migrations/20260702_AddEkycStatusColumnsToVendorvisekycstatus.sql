-- Migration: Add pan_ekycStatus, aadhar_ekycStatus, bank_ekycStatus, upi_ekycStatus columns to tbl_Vendorvisekycstatus table
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Vendorvisekycstatus]') 
      AND name = 'pan_ekycStatus'
)
BEGIN
    ALTER TABLE [dbo].[tbl_Vendorvisekycstatus] ADD [pan_ekycStatus] [varchar](20) NULL;
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Vendorvisekycstatus]') 
      AND name = 'aadhar_ekycStatus'
)
BEGIN
    ALTER TABLE [dbo].[tbl_Vendorvisekycstatus] ADD [aadhar_ekycStatus] [varchar](20) NULL;
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Vendorvisekycstatus]') 
      AND name = 'bank_ekycStatus'
)
BEGIN
    ALTER TABLE [dbo].[tbl_Vendorvisekycstatus] ADD [bank_ekycStatus] [varchar](20) NULL;
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Vendorvisekycstatus]') 
      AND name = 'upi_ekycStatus'
)
BEGIN
    ALTER TABLE [dbo].[tbl_Vendorvisekycstatus] ADD [upi_ekycStatus] [varchar](20) NULL;
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[tbl_Vendorvisekycstatus]') 
      AND name = 'Updated_date'
)
BEGIN
    ALTER TABLE [dbo].[tbl_Vendorvisekycstatus] ADD [Updated_date] [datetime] NULL;
END
GO

