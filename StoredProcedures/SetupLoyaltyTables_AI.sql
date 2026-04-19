-- =============================================
-- Database Tables for Loyalty & OTP System
-- Created: 2026-04-17
-- Description: Creates/updates tables for OTP verification, UPI transactions, and wallet management
-- =============================================

USE [Vcqru]
GO

-- =============================================
-- TABLE 1: tblOTPVerification
-- Description: Stores OTP records for verification
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tblOTPVerification]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tblOTPVerification] (
        [OtpId] [NVARCHAR](50) PRIMARY KEY NOT NULL,
        [MobileNo] [VARCHAR](10) NOT NULL,
        [OTP] [VARCHAR](6) NOT NULL,
        [Comp_ID] [VARCHAR](50) NULL,
        [CreatedDate] [DATETIME] NOT NULL DEFAULT GETDATE(),
        [ExpiryTime] [DATETIME] NOT NULL,
        [VerifiedDate] [DATETIME] NULL,
        [IsUsed] [BIT] NOT NULL DEFAULT 0,
        [Attempts] [INT] NOT NULL DEFAULT 0
    )
    
    CREATE INDEX IX_OTP_Mobile ON [dbo].[tblOTPVerification]([MobileNo])
    CREATE INDEX IX_OTP_Status ON [dbo].[tblOTPVerification]([IsUsed], [ExpiryTime])
    
    PRINT 'Table tblOTPVerification created successfully'
END
GO

-- =============================================
-- TABLE 2: tblUPITransactionDetails
-- Description: Records UPI transactions and payout history
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tblUPITransactionDetails]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tblUPITransactionDetails] (
        [TransId] [BIGINT] PRIMARY KEY IDENTITY(1,1),
        [M_Consumerid] [INT] NOT NULL,
        [MobileNo] [VARCHAR](15) NOT NULL,
        [Code1] [VARCHAR](10) NOT NULL,
        [Code2] [VARCHAR](10) NOT NULL,
        [Amount] [DECIMAL](18, 2) NOT NULL,
        [Comp_Id] [VARCHAR](50) NOT NULL,
        [UPIId] [NVARCHAR](100) NULL,
        [Status] [VARCHAR](50) NOT NULL DEFAULT 'Pending', -- Pending, Success, Failed, Cancelled
        [TransactionRef] [NVARCHAR](100) NULL,
        [PaymentMode] [VARCHAR](50) NULL, -- UPI, NEFT, IMPS
        [CreatedDate] [DATETIME] NOT NULL DEFAULT GETDATE(),
        [ProcessedDate] [DATETIME] NULL,
        [ReqDate] [DATETIME] NULL,
        [Remarks] [NVARCHAR](MAX) NULL
    )
    
    CREATE INDEX IX_UPI_Mobile ON [dbo].[tblUPITransactionDetails]([MobileNo])
    CREATE INDEX IX_UPI_Consumer ON [dbo].[tblUPITransactionDetails]([M_Consumerid])
    CREATE INDEX IX_UPI_Status ON [dbo].[tblUPITransactionDetails]([Status])
    CREATE INDEX IX_UPI_Comp ON [dbo].[tblUPITransactionDetails]([Comp_Id])
    
    PRINT 'Table tblUPITransactionDetails created successfully'
END
GO

-- =============================================
-- TABLE 3: tblCashWalletBalance
-- Description: Tracks wallet balance per consumer per company
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tblCashWalletBalance]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tblCashWalletBalance] (
        [WalletId] [BIGINT] PRIMARY KEY IDENTITY(1,1),
        [M_Consumerid] [INT] NOT NULL,
        [Comp_Id] [VARCHAR](50) NOT NULL,
        [Balance] [DECIMAL](18, 2) NOT NULL DEFAULT 0,
        [TotalEarned] [DECIMAL](18, 2) NOT NULL DEFAULT 0,
        [TotalRedeemed] [DECIMAL](18, 2) NOT NULL DEFAULT 0,
        [CreatedDate] [DATETIME] NOT NULL DEFAULT GETDATE(),
        [LastUpdated] [DATETIME] NOT NULL DEFAULT GETDATE(),
        UNIQUE (M_Consumerid, Comp_Id)
    )
    
    CREATE INDEX IX_Wallet_Consumer ON [dbo].[tblCashWalletBalance]([M_Consumerid])
    CREATE INDEX IX_Wallet_Comp ON [dbo].[tblCashWalletBalance]([Comp_Id])
    
    PRINT 'Table tblCashWalletBalance created successfully'
END
GO

-- =============================================
-- TABLE 4: Paytm_balance (if not exists)
-- Description: Paytm payment transactions
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Paytm_balance]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Paytm_balance] (
        [PaytmTransId] [BIGINT] PRIMARY KEY IDENTITY(1,1),
        [M_Consumerid] [INT] NOT NULL,
        [MobileNo] [VARCHAR](15) NOT NULL,
        [Amount] [DECIMAL](18, 2) NOT NULL,
        [Code1] [VARCHAR](10) NULL,
        [Code2] [VARCHAR](10) NULL,
        [Comp_Id] [VARCHAR](50) NOT NULL,
        [PaytmOrderId] [NVARCHAR](100) NULL,
        [PaytmTxnId] [NVARCHAR](100) NULL,
        [Status] [VARCHAR](50) NOT NULL DEFAULT 'Pending', -- Pending, Success, Failed
        [PaymentMode] [VARCHAR](50) NULL,
        [CreatedDate] [DATETIME] NOT NULL DEFAULT GETDATE(),
        [ProcessedDate] [DATETIME] NULL,
        [Remarks] [NVARCHAR](MAX) NULL
    )
    
    CREATE INDEX IX_Paytm_Mobile ON [dbo].[Paytm_balance]([MobileNo])
    CREATE INDEX IX_Paytm_Consumer ON [dbo].[Paytm_balance]([M_Consumerid])
    CREATE INDEX IX_Paytm_Status ON [dbo].[Paytm_balance]([Status])
    
    PRINT 'Table Paytm_balance created successfully'
END
GO

-- =============================================
-- TABLE 5: LandingPage_CodeCheckMessages (if not exists)
-- Description: Custom messages for code check operations
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LandingPage_CodeCheckMessages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[LandingPage_CodeCheckMessages] (
        [MessageId] [BIGINT] PRIMARY KEY IDENTITY(1,1),
        [Comp_Id] [VARCHAR](50) NOT NULL,
        [Service_Id] [VARCHAR](50) NULL,
        [Message_Type] [VARCHAR](50) NOT NULL, -- Success, InvalidCode, AlreadyChecked, etc.
        [Message_Text] [NVARCHAR](MAX) NOT NULL,
        [IsActive] [BIT] NOT NULL DEFAULT 1,
        [CreatedDate] [DATETIME] NOT NULL DEFAULT GETDATE(),
        [UpdatedDate] [DATETIME] NULL,
        [CreatedBy] [NVARCHAR](100) NULL
    )
    
    CREATE INDEX IX_Messages_Comp ON [dbo].[LandingPage_CodeCheckMessages]([Comp_Id])
    CREATE INDEX IX_Messages_Type ON [dbo].[LandingPage_CodeCheckMessages]([Message_Type])
    
    PRINT 'Table LandingPage_CodeCheckMessages created successfully'
END
GO

-- =============================================
-- TABLE 6: BaseFormFields (reference table - if not exists)
-- Description: Base form field definitions
-- =============================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BaseFormFields]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[BaseFormFields] (
        [FieldId] [INT] PRIMARY KEY IDENTITY(1,1),
        [FieldName] [NVARCHAR](100) NOT NULL UNIQUE,
        [BaseFieldType] [VARCHAR](50) NOT NULL, -- text, email, tel, select, checkbox
        [DefaultLabel] [NVARCHAR](100) NULL,
        [ValidationPattern] [NVARCHAR](MAX) NULL,
        [IsActive] [BIT] NOT NULL DEFAULT 1
    )
    
    -- Insert common field definitions if table is new
    IF NOT EXISTS (SELECT 1 FROM [dbo].[BaseFormFields] WHERE FieldName = 'ConsumerName')
    BEGIN
        INSERT INTO [dbo].[BaseFormFields] (FieldName, BaseFieldType, DefaultLabel)
        VALUES 
            ('ConsumerName', 'text', 'Full Name'),
            ('Email', 'email', 'Email Address'),
            ('City', 'text', 'City'),
            ('State', 'text', 'State'),
            ('PinCode', 'text', 'PIN Code'),
            ('Address', 'text', 'Address'),
            ('UPI', 'text', 'UPI ID'),
            ('Phone', 'tel', 'Phone Number'),
            ('AccountNumber', 'text', 'Account Number'),
            ('IfscCode', 'text', 'IFSC Code'),
            ('AccountHolderName', 'text', 'Account Holder Name')
    END
    
    PRINT 'Table BaseFormFields created successfully'
END
GO

-- =============================================
-- SEED DATA: Default Code Check Messages for Comp-2299
-- =============================================
IF NOT EXISTS (SELECT 1 FROM LandingPage_CodeCheckMessages WHERE Comp_Id = 'Comp-2299' AND Message_Type = 'Success')
BEGIN
    INSERT INTO [dbo].[LandingPage_CodeCheckMessages] 
    (Comp_Id, Service_Id, Message_Type, Message_Text, IsActive, CreatedDate, CreatedBy)
    VALUES 
        ('Comp-2299', 'SRV1029', 'Success', '✓ Congratulations! Your product is authentic. Cashback of ₹{amount} will be credited to your UPI/Bank account within 24 hours.', 1, GETDATE(), 'System'),
        ('Comp-2299', 'SRV1029', 'AlreadyChecked', 'This code has already been verified. Please use a different code to claim more rewards.', 1, GETDATE(), 'System'),
        ('Comp-2299', 'SRV1029', 'InvalidCode', '❌ Invalid code. This product code does not exist or is fake. Please check and try again.', 1, GETDATE(), 'System'),
        ('Comp-2299', 'SRV1029', 'New', '✓ Welcome! Register your product to instantly claim cashback rewards.', 1, GETDATE(), 'System'),
        ('Comp-2299', 'SRV1029', 'FrequencyLimit', 'You have reached the maximum number of code scans for this period. Please try again later.', 1, GETDATE(), 'System'),
        ('Comp-2299', 'SRV1029', 'Pending', '⏳ Your cashback is being processed. Please wait...', 1, GETDATE(), 'System')
END
GO

-- =============================================
-- SAMPLE DATA: Insert test consumer for mobile 9315742109
-- =============================================
DECLARE @TestConsumerId INT = (SELECT M_Consumerid FROM M_Consumer WHERE RIGHT(MobileNo, 10) = '9315742109' LIMIT 1)

IF @TestConsumerId IS NOT NULL
BEGIN
    -- Initialize wallet if not exists
    IF NOT EXISTS (SELECT 1 FROM tblCashWalletBalance WHERE M_Consumerid = @TestConsumerId AND Comp_Id = 'Comp-2299')
    BEGIN
        INSERT INTO tblCashWalletBalance (M_Consumerid, Comp_Id, Balance, CreatedDate, LastUpdated)
        VALUES (@TestConsumerId, 'Comp-2299', 0, GETDATE(), GETDATE())
        
        PRINT 'Test wallet initialized for consumer'
    END
END
GO

PRINT '=========================================='
PRINT 'Database setup completed successfully!'
PRINT '=========================================='
