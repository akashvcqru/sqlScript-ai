IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MobileToAccount_Audit') AND name = 'Reference_Id')
BEGIN
    ALTER TABLE [dbo].[MobileToAccount_Audit] ADD [Reference_Id] VARCHAR(100) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('MobileToAccount_Audit') AND name = 'Status')
BEGIN
    ALTER TABLE [dbo].[MobileToAccount_Audit] ADD [Status] VARCHAR(20) NULL;
END
GO
