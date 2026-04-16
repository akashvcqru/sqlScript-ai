SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_GetKycDetails_AI]
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
        -- Added panekycStatus alias to match the column the C# code expects or to provide a default '1' when the record exists
        SELECT TOP 1 1 as panekycStatus, * FROM tblKycPanDataDetails WHERE M_Consumerid = @MID ORDER BY Id DESC;

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
