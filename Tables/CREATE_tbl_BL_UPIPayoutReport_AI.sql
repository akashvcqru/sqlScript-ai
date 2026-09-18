USE [Vcqru]
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_BL_UPIPayoutReport_AI')
BEGIN
    CREATE TABLE [dbo].[tbl_BL_UPIPayoutReport_AI]
    (
        [ID]                         BIGINT IDENTITY(1,1) PRIMARY KEY,
        [tblUPITransactionDetailsID] BIGINT NULL,               -- tblUPITransactionDetails.Id
        [Comp_ID]                    VARCHAR(50) NOT NULL,
        [ConsumerName]               NVARCHAR(250) NULL,
        [MobileNo]                   VARCHAR(50) NULL,
        [Code1]                      VARCHAR(50) NULL,
        [Code2]                      VARCHAR(50) NULL,
        [UPI_Id]                     NVARCHAR(100) NULL,
        [OldBal]                     DECIMAL(18,2) NULL,
        [Amount]                     DECIMAL(18,2) NULL,
        [FinalPayment]               DECIMAL(18,2) NULL,
        [tdsAmount]                  DECIMAL(18,2) NULL,
        [tdsper]                     DECIMAL(18,2) NULL,
        [ChargedAmount]              DECIMAL(18,2) NULL,
        [GstAmount]                  DECIMAL(18,2) NULL,
        [NewBal]                     DECIMAL(18,2) NULL,
        [OrderId]                    NVARCHAR(100) NULL,
        [BankStatus]                 NVARCHAR(50) NULL,
        [BankRemark]                 NVARCHAR(MAX) NULL,
        [ReqDate]                    DATETIME NULL,
        [FinalStatus]                NVARCHAR(500) NULL,
        [FinalRemark]                NVARCHAR(MAX) NULL,
        [CreatedDate]                DATETIME DEFAULT GETDATE()
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_BL_UPIPayoutReport_Comp_Mobile_Date]
    ON [dbo].[tbl_BL_UPIPayoutReport_AI] ([Comp_ID], [MobileNo], [ReqDate]);

    PRINT 'Table tbl_BL_UPIPayoutReport_AI created successfully.';
END
ELSE
BEGIN
    PRINT 'Table tbl_BL_UPIPayoutReport_AI already exists.';
END
GO
