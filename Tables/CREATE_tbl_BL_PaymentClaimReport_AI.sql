USE [Vcqru]
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tbl_BL_PaymentClaimReport_AI')
BEGIN
    CREATE TABLE [dbo].[tbl_BL_PaymentClaimReport_AI]
    (
        [ID]               BIGINT IDENTITY(1,1) PRIMARY KEY,
        [Row_id]           BIGINT NULL,               -- ClaimDetails.Row_id (Claim_id)
        [Comp_ID]          VARCHAR(50) NOT NULL,
        [Comp_Name]        NVARCHAR(250) NULL,
        [Claim_date]       DATETIME NULL,
        [Mobileno]         VARCHAR(50) NULL,
        [Points]           DECIMAL(18,2) NULL,
        [PointsValue]      DECIMAL(18,2) NULL,
        [tdsAmount]        DECIMAL(18,2) NULL,
        [tdsper]           DECIMAL(18,2) NULL,
        [ConsumerName]     NVARCHAR(250) NULL,
        [City]             NVARCHAR(100) NULL,
        [Pincode]          NVARCHAR(50) NULL,
        [State]            NVARCHAR(100) NULL,
        [Account_No]       NVARCHAR(100) NULL,
        [Account_HolderNm] NVARCHAR(250) NULL,
        [BankName]         NVARCHAR(250) NULL,
        [IFSC_Code]        NVARCHAR(50) NULL,
        [PaymentStatus]    NVARCHAR(50) NULL,
        [BankRefID]        NVARCHAR(100) NULL,
        [TransactionDate]  NVARCHAR(100) NULL,
        [PaymentRemarks]   NVARCHAR(MAX) NULL,
        [Claim_Status]     NVARCHAR(50) NULL,
        [vendor_comment]   NVARCHAR(MAX) NULL,
        [action_date]      DATETIME NULL,
        [GiftName]         NVARCHAR(250) NULL,
        [CreatedDate]      DATETIME DEFAULT GETDATE()
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_BL_PaymentClaimReport_Comp_Mobile_Date]
    ON [dbo].[tbl_BL_PaymentClaimReport_AI] ([Comp_ID], [Mobileno], [Claim_date]);

    PRINT 'Table tbl_BL_PaymentClaimReport_AI created successfully.';
END
ELSE
BEGIN
    PRINT 'Table tbl_BL_PaymentClaimReport_AI already exists.';
END
GO
