-- Migration: Add Email_ID and Mobile_Number columns to M_QRCode_Print_Settings table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[M_QRCode_Print_Settings]') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_QRCode_Print_Settings]') AND name = N'Email_ID')
    BEGIN
        ALTER TABLE [dbo].[M_QRCode_Print_Settings] ADD [Email_ID] [nvarchar](250) NULL;
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[M_QRCode_Print_Settings]') AND name = N'Mobile_Number')
    BEGIN
        ALTER TABLE [dbo].[M_QRCode_Print_Settings] ADD [Mobile_Number] [nvarchar](250) NULL;
    END
END
GO
