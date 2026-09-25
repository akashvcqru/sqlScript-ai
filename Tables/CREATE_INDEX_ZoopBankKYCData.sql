IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_ZoopBankKYCData_AccountNo_IFSC' AND object_id = OBJECT_ID(N'[dbo].[ZoopBankKYCData]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ZoopBankKYCData_AccountNo_IFSC] ON [dbo].[ZoopBankKYCData]([AccountNo] ASC, [IFSC_Code] ASC);
END
GO
