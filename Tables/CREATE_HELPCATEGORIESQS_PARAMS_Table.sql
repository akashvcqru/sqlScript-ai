-- =========================================================================================
-- Script Name: CREATE_HELPCATEGORIESQS_PARAMS_Table.sql
-- Description: Creates table HELPCATEGORIESQS_PARAMS to store dynamic required/optional
--              input parameters for each Help Question (e.g. coupon code, claim id, etc.)
-- Date: 2026-09-21
-- =========================================================================================

USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------------------
-- 1. CREATE TABLE: HELPCATEGORIESQS_PARAMS
-------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIESQS_PARAMS')
BEGIN
    CREATE TABLE [dbo].[HELPCATEGORIESQS_PARAMS](
        [ParamId]         [int] IDENTITY(1,1) NOT NULL,
        [QuestionId]      [int] NOT NULL,                                           -- FK to HELPCATEGORIESQS
        [ParamKey]        [varchar](100) NOT NULL,                                  -- API key name (e.g., 'code_number', 'claim_id', 'new_mobile_no')
        [ParamLabel]      [nvarchar](150) NOT NULL,                                 -- UI Display Label (e.g., 'Coupon / Code Number')
        [ParamType]       [varchar](50) NOT NULL CONSTRAINT [DF_HELPCATEGORIESQS_PARAMS_ParamType] DEFAULT ('text'), -- 'text', 'number', 'date', 'file', 'dropdown', 'textarea'
        [Placeholder]     [nvarchar](200) NULL,                                     -- UI placeholder hint
        [IsRequired]      [bit] NOT NULL CONSTRAINT [DF_HELPCATEGORIESQS_PARAMS_IsRequired] DEFAULT ((1)),          -- 1 = Mandatory, 0 = Optional
        [ValidationRegex] [nvarchar](300) NULL,                                     -- Optional regex validation (e.g., '^[0-9]{10}$')
        [ErrorMessage]    [nvarchar](250) NULL,                                     -- Error message if validation fails
        [Options]         [nvarchar](MAX) NULL,                                     -- Comma-separated or JSON values for 'dropdown'
        [DisplayOrder]    [int] NOT NULL CONSTRAINT [DF_HELPCATEGORIESQS_PARAMS_DisplayOrder] DEFAULT ((0)),
        [IsActive]        [bit] NOT NULL CONSTRAINT [DF_HELPCATEGORIESQS_PARAMS_IsActive] DEFAULT ((1)),
        [CreatedOn]       [datetime] NOT NULL CONSTRAINT [DF_HELPCATEGORIESQS_PARAMS_CreatedOn] DEFAULT (GETDATE()),
        [UpdatedOn]       [datetime] NULL,
        CONSTRAINT [PK_HELPCATEGORIESQS_PARAMS] PRIMARY KEY CLUSTERED ([ParamId] ASC),
        CONSTRAINT [FK_HELPCATEGORIESQS_PARAMS_QS] FOREIGN KEY ([QuestionId]) 
            REFERENCES [dbo].[HELPCATEGORIESQS] ([QuestionId]) ON DELETE CASCADE
    ) ON [PRIMARY];

    PRINT 'Table [dbo].[HELPCATEGORIESQS_PARAMS] created successfully.';
END
ELSE
BEGIN
    PRINT 'Table [dbo].[HELPCATEGORIESQS_PARAMS] already exists.';
END
GO

-------------------------------------------------------------------------------------------
-- 2. CREATE INDEX FOR FASTER LOOKUPS
-------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_HELPCATEGORIESQS_PARAMS_QuestionId' AND object_id = OBJECT_ID('dbo.HELPCATEGORIESQS_PARAMS'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_HELPCATEGORIESQS_PARAMS_QuestionId] 
    ON [dbo].[HELPCATEGORIESQS_PARAMS] ([QuestionId], [IsActive])
    INCLUDE ([ParamKey], [ParamLabel], [ParamType], [Placeholder], [IsRequired], [DisplayOrder]);
    
    PRINT 'Index [IX_HELPCATEGORIESQS_PARAMS_QuestionId] created successfully.';
END
GO

-------------------------------------------------------------------------------------------
-- 3. SEED SAMPLE PARAMETERS FOR COMMON QUESTIONS
-------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIESQS_PARAMS') AND EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIESQS')
BEGIN
    DECLARE @QId INT;

    -- 3.1 CODE_NOT_SCANNING (Code Scan issue -> requires Code Number)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_NOT_SCANNING';
    IF @QId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'code_number')
    BEGIN
        INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, ValidationRegex, ErrorMessage, DisplayOrder)
        VALUES (@QId, 'code_number', N'Coupon / QR Code Number', 'text', N'Enter 12 or 16 digit code', 1, '^[a-zA-Z0-9]{8,20}$', N'Please enter a valid code number.', 1);
    END

    -- 3.2 CODE_ALREADY_USED (Code already used -> requires Code Number)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_ALREADY_USED';
    IF @QId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'code_number')
    BEGIN
        INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, ValidationRegex, ErrorMessage, DisplayOrder)
        VALUES (@QId, 'code_number', N'Used Code Number', 'text', N'Enter 12 or 16 digit code', 1, '^[a-zA-Z0-9]{8,20}$', N'Please enter a valid code number.', 1);
    END

    -- 3.3 CODE_DAMAGED (Damaged code -> requires partial code + photo upload)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'CODE_DAMAGED';
    IF @QId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'partial_code')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'partial_code', N'Visible / Partial Code (Optional)', 'text', N'Enter readable characters', 0, 1);

        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'code_photo')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'code_photo', N'Upload Photo of Damaged Code', 'file', N'Take or choose photo', 1, 2);
    END

    -- 3.4 PAY_NOT_RECEIVED (Payment not received -> optional Transaction ID and Claim Date)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_NOT_RECEIVED';
    IF @QId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'claim_id')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'claim_id', N'Claim / Transaction ID (Optional)', 'text', N'Enter Claim ID if available', 0, 1);

        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'claim_date')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'claim_date', N'Date of Claim', 'date', N'Select date', 0, 2);
    END

    -- 3.5 PAY_LESS_AMOUNT (Less amount received -> Claim ID, Expected Amount, Received Amount)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'PAY_LESS_AMOUNT';
    IF @QId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'claim_id')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'claim_id', N'Claim / Transaction ID', 'text', N'Enter Claim ID', 1, 1);

        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'expected_amount')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'expected_amount', N'Expected Amount (₹)', 'number', N'e.g. 500', 1, 2);

        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'received_amount')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'received_amount', N'Received Amount (₹)', 'number', N'e.g. 400', 1, 3);
    END

    -- 3.6 CLAIM_AMOUNT_INCORRECT (Claim amount incorrect -> Claim ID and Expected Points)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'CLAIM_AMOUNT_INCORRECT';
    IF @QId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'claim_id')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'claim_id', N'Claim ID', 'text', N'Enter Claim ID', 1, 1);

        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'expected_points')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'expected_points', N'Expected Points / Amount', 'number', N'e.g. 100', 1, 2);
    END

    -- 3.7 ACC_CHANGE_MOBILE (Change mobile number -> New Mobile Number)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_CHANGE_MOBILE';
    IF @QId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'new_mobile_no')
    BEGIN
        INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, ValidationRegex, ErrorMessage, DisplayOrder)
        VALUES (@QId, 'new_mobile_no', N'New Mobile Number', 'number', N'Enter 10-digit mobile number', 1, '^[6-9][0-9]{9}$', N'Please enter a valid 10-digit mobile number starting with 6, 7, 8, or 9.', 1);
    END

    -- 3.8 ACC_CHANGE_BANK (Change bank details -> Account No, IFSC, Account Holder Name)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'ACC_CHANGE_BANK';
    IF @QId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'account_number')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
            VALUES (@QId, 'account_number', N'Bank Account Number', 'text', N'Enter bank account number', 1, 1);

        IF NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'ifsc_code')
            INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, ValidationRegex, ErrorMessage, DisplayOrder)
            VALUES (@QId, 'ifsc_code', N'IFSC Code', 'text', N'Enter 11-character IFSC code', 1, '^[A-Z]{4}0[A-Z0-9]{6}$', N'Please enter a valid 11-character IFSC code.', 2);
    END

    -- 3.9 OTHER_GENERAL_ISSUE / TECH_OTHER_TECHNICAL_ISSUE (Issue description)
    SELECT @QId = QuestionId FROM HELPCATEGORIESQS WHERE QuestionCode = 'OTHER_GENERAL_ISSUE';
    IF @QId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HELPCATEGORIESQS_PARAMS WHERE QuestionId = @QId AND ParamKey = 'description')
    BEGIN
        INSERT INTO HELPCATEGORIESQS_PARAMS (QuestionId, ParamKey, ParamLabel, ParamType, Placeholder, IsRequired, DisplayOrder)
        VALUES (@QId, 'description', N'Describe your issue in detail', 'textarea', N'Please tell us what went wrong...', 1, 1);
    END

    PRINT 'Seed data for HELPCATEGORIESQS_PARAMS inserted successfully.';
END
GO
