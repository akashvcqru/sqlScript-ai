-- =========================================================================================
-- Script Name: CREATE_HELPCATEGORIES_AND_HELPCATEGORIESQS.sql
-- Description: Creates tables HELPCATEGORIES and HELPCATEGORIESQS with idempotent SEED INSERT statements.
-- Date: 2026-09-17
-- =========================================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------------------
-- 1. CREATE TABLE: HELPCATEGORIES
-------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIES')
BEGIN
    CREATE TABLE [dbo].[HELPCATEGORIES](
        [CategoryId] [int] IDENTITY(1,1) NOT NULL,
        [CategoryCode] [varchar](50) NOT NULL,
        [CategoryName] [nvarchar](150) NOT NULL,
        [CategoryIcon] [nvarchar](50) NULL,
        [PriorityOrder] [int] NOT NULL DEFAULT ((0)),
        [IsActive] [bit] NOT NULL DEFAULT ((1)),
        [CreatedOn] [datetime] NOT NULL DEFAULT (GETDATE()),
        [UpdatedOn] [datetime] NULL,
        CONSTRAINT [PK_HELPCATEGORIES] PRIMARY KEY CLUSTERED ([CategoryId] ASC),
        CONSTRAINT [UQ_HELPCATEGORIES_CategoryCode] UNIQUE ([CategoryCode])
    ) ON [PRIMARY];
END
GO

-------------------------------------------------------------------------------------------
-- 2. CREATE TABLE: HELPCATEGORIESQS
-------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIESQS')
BEGIN
    CREATE TABLE [dbo].[HELPCATEGORIESQS](
        [QuestionId] [int] IDENTITY(1,1) NOT NULL,
        [CategoryId] [int] NOT NULL,
        [QuestionCode] [varchar](100) NOT NULL,
        [QuestionText] [nvarchar](300) NOT NULL,
        [ActionTarget] [nvarchar](200) NULL,
        [DisplayOrder] [int] NOT NULL DEFAULT ((0)),
        [IsActive] [bit] NOT NULL DEFAULT ((1)),
        [CreatedOn] [datetime] NOT NULL DEFAULT (GETDATE()),
        [UpdatedOn] [datetime] NULL,
        CONSTRAINT [PK_HELPCATEGORIESQS] PRIMARY KEY CLUSTERED ([QuestionId] ASC),
        CONSTRAINT [FK_HELPCATEGORIESQS_HELPCATEGORIES] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[HELPCATEGORIES] ([CategoryId]) ON DELETE CASCADE
    ) ON [PRIMARY];
END
GO

-------------------------------------------------------------------------------------------
-- 3. SEED INSERT QUERY: HELPCATEGORIES
-------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIES')
BEGIN
    -- Category 1: KYC & Verification
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'KYC_VERIFICATION')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('KYC_VERIFICATION', N'KYC & Verification', N'🪪', 1, 1);

    -- Category 2: Payments & Rewards
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'PAYMENTS_REWARDS')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('PAYMENTS_REWARDS', N'Payments & Rewards', N'💳', 2, 1);

    -- Category 3: Claims
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'CLAIMS')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('CLAIMS', N'Claims', N'🎯', 3, 1);

    -- Category 4: Coupon / Code Scan
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'COUPON_CODE_SCAN')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('COUPON_CODE_SCAN', N'Coupon & Code Scan', N'▣', 4, 1);

    -- Category 5: Account & Login
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'ACCOUNT_LOGIN')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('ACCOUNT_LOGIN', N'Account & Login', N'👤', 5, 1);

    -- Category 6: App & Technical Help
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'APP_TECHNICAL_HELP')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('APP_TECHNICAL_HELP', N'App & Technical Help', N'📱', 6, 1);

    -- Category 7: Other Issue
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIES WHERE CategoryCode = 'OTHER_ISSUE')
        INSERT INTO HELPCATEGORIES (CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive) 
        VALUES ('OTHER_ISSUE', N'Other Issue', N'❓', 7, 1);
END
GO

-------------------------------------------------------------------------------------------
-- 4. SEED INSERT QUERY: HELPCATEGORIESQS
-------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIESQS') AND EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIES')
BEGIN
    DECLARE @CatKyc INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'KYC_VERIFICATION');
    DECLARE @CatPay INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'PAYMENTS_REWARDS');
    DECLARE @CatClaim INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'CLAIMS');
    DECLARE @CatCode INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'COUPON_CODE_SCAN');
    DECLARE @CatAcc INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'ACCOUNT_LOGIN');
    DECLARE @CatTech INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'APP_TECHNICAL_HELP');
    DECLARE @CatOther INT = (SELECT CategoryId FROM HELPCATEGORIES WHERE CategoryCode = 'OTHER_ISSUE');

    ---------------------------------------------------------------------------------------
    -- 4.1 KYC & Verification Questions
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'KYC_PENDING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatKyc, 'KYC_PENDING', N'Why is my KYC still pending?', NULL, 1);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'KYC_REJECTED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatKyc, 'KYC_REJECTED', N'Why was my KYC rejected?', NULL, 2);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'KYC_UPDATE_DETAILS')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatKyc, 'KYC_UPDATE_DETAILS', N'I want to update my KYC details', 'vcqru://app/kyc/edit', 3);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'KYC_PAN_FAILED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatKyc, 'KYC_PAN_FAILED', N'My PAN verification failed', NULL, 4);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'KYC_BANK_FAILED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatKyc, 'KYC_BANK_FAILED', N'My bank verification failed', NULL, 5);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'KYC_UPLOAD_FAILED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatKyc, 'KYC_UPLOAD_FAILED', N'I am unable to upload KYC documents', 'vcqru://app/help/permissions', 6);

    ---------------------------------------------------------------------------------------
    -- 4.2 Payments & Rewards Questions
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_NOT_RECEIVED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_NOT_RECEIVED', N'I haven''t received my payment', NULL, 1);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_CHECK_STATUS')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_CHECK_STATUS', N'Check my payment status', NULL, 2);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_REWARD_TIMELINE')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_REWARD_TIMELINE', N'When will I receive my reward?', NULL, 3);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_POINTS_NOT_ADDED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_POINTS_NOT_ADDED', N'My reward points were not added', NULL, 4);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_WALLET_INCORRECT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_WALLET_INCORRECT', N'My wallet balance looks incorrect', NULL, 5);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_FAILED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_FAILED', N'A payment failed', NULL, 6);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_LESS_AMOUNT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_LESS_AMOUNT', N'I received less payment than expected', NULL, 7);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_DOWNLOAD_TDS')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatPay, 'PAY_DOWNLOAD_TDS', N'I want to download my TDS certificate', 'vcqru://app/account/tds-download', 8);

    ---------------------------------------------------------------------------------------
    -- 4.3 Claims Questions
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_PENDING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatClaim, 'CLAIM_PENDING', N'Why is my claim pending?', NULL, 1);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_REJECTED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatClaim, 'CLAIM_REJECTED', N'Why was my claim rejected?', NULL, 2);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_NOT_SHOWING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatClaim, 'CLAIM_NOT_SHOWING', N'My claim is not showing', NULL, 3);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_TXN_NOT_SHOWING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatClaim, 'CLAIM_TXN_NOT_SHOWING', N'My transaction is not showing', NULL, 4);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_AMOUNT_INCORRECT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatClaim, 'CLAIM_AMOUNT_INCORRECT', N'My claim amount is incorrect', NULL, 5);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_CHECK_STATUS')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatClaim, 'CLAIM_CHECK_STATUS', N'I want to check my claim status', NULL, 6);

    ---------------------------------------------------------------------------------------
    -- 4.4 Coupon & Code Scan Questions
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_NOT_SCANNING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_NOT_SCANNING', N'My QR/code is not scanning', 'vcqru://app/help/camera-guide', 1);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_ALREADY_USED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_ALREADY_USED', N'My code shows "Already Used"', NULL, 2);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_INVALID')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_INVALID', N'My code shows "Invalid"', NULL, 3);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_DAMAGED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_DAMAGED', N'My code is damaged or unreadable', 'vcqru://app/help/upload-qr', 4);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_NO_POINTS_ADDED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_NO_POINTS_ADDED', N'I scanned successfully but did not receive reward points', NULL, 5);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_PRODUCT_VERIFY_INCORRECT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_PRODUCT_VERIFY_INCORRECT', N'The product verification result looks incorrect', NULL, 6);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_CANNOT_FIND_ON_PRODUCT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatCode, 'CODE_CANNOT_FIND_ON_PRODUCT', N'I cannot find the QR/code on the product', 'vcqru://app/help/packaging-guide', 7);

    ---------------------------------------------------------------------------------------
    -- 4.5 Account & Login Questions
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_CANT_LOGIN')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_CANT_LOGIN', N'I can''t log in', NULL, 1);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_NO_OTP')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_NO_OTP', N'I didn''t receive the OTP', NULL, 2);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_CHANGE_MOBILE')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_CHANGE_MOBILE', N'Change my mobile number', 'vcqru://app/account/change-mobile', 3);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_CHANGE_BANK')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_CHANGE_BANK', N'Change my bank details', 'vcqru://app/account/change-bank', 4);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_PROFILE_INCORRECT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_PROFILE_INCORRECT', N'My profile information is incorrect', 'vcqru://app/account/profile', 5);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_CHANGE_LANGUAGE')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_CHANGE_LANGUAGE', N'Change app language', 'vcqru://app/settings/language', 6);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_BLOCKED')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_BLOCKED', N'My account is blocked', NULL, 7);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_DELETE_ACCOUNT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatAcc, 'ACC_DELETE_ACCOUNT', N'I want to delete/deactivate my account', 'vcqru://app/account/delete', 8);

    ---------------------------------------------------------------------------------------
    -- 4.6 App & Technical Help Questions
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_APP_NOT_OPENING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_APP_NOT_OPENING', N'App is not opening', 'vcqru://app/help/clear-cache', 1);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_APP_SLOW_FREEZING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_APP_SLOW_FREEZING', N'App is slow or freezing', 'vcqru://app/help/app-info', 2);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_CAMERA_NOT_WORKING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_CAMERA_NOT_WORKING', N'Scanner/camera is not working', 'vcqru://app/help/camera-permissions', 3);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_SCANNING_ERROR')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_SCANNING_ERROR', N'Something went wrong while scanning', NULL, 4);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_PAGE_NOT_LOADING')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_PAGE_NOT_LOADING', N'Page is not loading', 'vcqru://app/help/network-test', 5);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_KEEPS_LOGGING_OUT')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_KEEPS_LOGGING_OUT', N'App keeps logging me out', NULL, 6);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_NOT_RECEIVING_NOTIFS')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_NOT_RECEIVING_NOTIFS', N'I am not receiving notifications', NULL, 7);

    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'TECH_OTHER_TECHNICAL_ISSUE')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatTech, 'TECH_OTHER_TECHNICAL_ISSUE', N'I found another technical problem', 'vcqru://app/help/create-ticket', 8);

    ---------------------------------------------------------------------------------------
    -- 4.7 Other Issue Question
    ---------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS WHERE QuestionCode = 'OTHER_GENERAL_ISSUE')
        INSERT INTO HELPCATEGORIESQS (CategoryId, QuestionCode, QuestionText, ActionTarget, DisplayOrder)
        VALUES (@CatOther, 'OTHER_GENERAL_ISSUE', N'Other Issue / General Inquiry', 'vcqru://app/help/create-ticket', 1);

END
GO

-------------------------------------------------------------------------------------------
-- 5. VERIFICATION QUERY
-------------------------------------------------------------------------------------------
SELECT CategoryId, CategoryCode, CategoryName, CategoryIcon, PriorityOrder, IsActive 
FROM HELPCATEGORIES 
ORDER BY PriorityOrder ASC;

SELECT q.QuestionId, c.CategoryName, q.QuestionCode, q.QuestionText, q.ActionTarget, q.DisplayOrder 
FROM HELPCATEGORIESQS q
INNER JOIN HELPCATEGORIES c ON q.CategoryId = c.CategoryId
ORDER BY c.PriorityOrder ASC, q.DisplayOrder ASC;
GO
