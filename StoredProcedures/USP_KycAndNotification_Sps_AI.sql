-- =============================================
-- Author:      AI Assistant
-- Create date: 2026-03-31
-- Description: Optimized SPs for KYC status and Notification counting
-- =============================================

-- 1. USP_CountnotificationBL_AI
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_CountnotificationBL_AI]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_CountnotificationBL_AI]
GO

CREATE PROCEDURE [dbo].[USP_CountnotificationBL_AI]
    @Mobileno NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Normalize mobile number to 10 digits for comparison
    DECLARE @Mobile10 NVARCHAR(10) = RIGHT(@Mobileno, 10);

    SELECT COUNT(*) 
    FROM tblappNotification 
    WHERE (RIGHT(Mobile, 10) = @Mobile10 OR Mobile IS NULL OR Mobile = '')
      AND IsActive = 1 
      AND GETDATE() BETWEEN Valid_from AND Valid_till;
END
GO

-- 2. USP_GetConsumerKYCStatus_BL_AI
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_GetConsumerKYCStatus_BL_AI]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_GetConsumerKYCStatus_BL_AI]
GO

CREATE PROCEDURE [dbo].[USP_GetConsumerKYCStatus_BL_AI]
    @MobileNo NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 
        ISNULL(bankekycStatus, '0') AS bankekycStatus, 
        ISNULL(panekycStatus, '0') AS panekycStatus, 
        ISNULL(Manual_KYC_Status, '0') AS Manual_KYC_Status, 
        ISNULL(aadharkycStatus, '0') AS aadharkycStatus, 
        ISNULL(UPIKYCSTATUS, '0') AS UPIKYCSTATUS 
    FROM m_consumer 
    WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) 
      AND IsDelete = 0
    ORDER BY M_Consumerid DESC;
END
GO

-- 3. USP_GetKycDetails_AI
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_GetKycDetails_AI]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_GetKycDetails_AI]
GO

CREATE PROCEDURE [dbo].[USP_GetKycDetails_AI]
    @MobileNo NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MID INT;
    SELECT TOP 1 @MID = M_Consumerid FROM m_consumer WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete = 0 ORDER BY M_Consumerid DESC;

    IF @MID IS NOT NULL
    BEGIN
        -- Result Set 0: Bank Details
        SELECT TOP 1 * FROM tblKycBankDataDetails WHERE M_Consumerid = @MID ORDER BY Id DESC;

        -- Result Set 1: PAN Details
        SELECT TOP 1 * FROM tblKycPanDataDetails WHERE M_Consumerid = @MID ORDER BY Id DESC;

        -- Result Set 2: Aadhar Details
        SELECT TOP 1 * FROM tblKycAadharDataDetails WHERE M_Consumerid = @MID ORDER BY Id DESC;

        -- Result Set 3: UPI/Manual/Other Details (Returning Consumer Table Record for fallback)
        SELECT TOP 1 UPIId, UPIKYCSTATUS FROM m_consumer WHERE M_Consumerid = @MID;
    END
    ELSE
    BEGIN
        -- Return empty sets if consumer not found
        SELECT TOP 0 * FROM tblKycBankDataDetails;
        SELECT TOP 0 * FROM tblKycPanDataDetails;
        SELECT TOP 0 * FROM tblKycAadharDataDetails;
        -- Return a set with matching columns for Result Set 3
        SELECT TOP 0 UPIId, UPIKYCSTATUS FROM m_consumer;
    END
END
GO
