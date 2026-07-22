CREATE PROCEDURE [dbo].[GetBankDetailsIfExists_ByMobile_AI]
(
    @MobileNo VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize mobile -> last 10 digits
    SET @MobileNo = RIGHT(
        REPLACE(REPLACE(REPLACE(@MobileNo, '+', ''), '-', ''), ' ', ''),
        10
    );

    -- 1. First check bank detail in table M_BankAccount
    IF EXISTS (
        SELECT 1 
        FROM M_BankAccount B
        INNER JOIN M_Consumer C ON B.M_Consumerid = C.M_Consumerid
        WHERE RIGHT(C.MobileNo, 10) = @MobileNo
          AND ISNULL(B.Account_No, '') <> ''
          AND ISNULL(B.IFSC_Code, '') <> ''
          AND C.IsDelete = 0
    )
    BEGIN
        SELECT TOP 1
            CAST(1 AS BIT)     AS success,
            B.Account_HolderNm AS name_at_bank,
            B.Account_No       AS account_number,
            B.IFSC_Code        AS ifsc_code,
            ''                 AS bank_reference,
            ''                 AS reference_id,
            GETDATE()          AS requested_at
        FROM M_BankAccount B
        INNER JOIN M_Consumer C ON B.M_Consumerid = C.M_Consumerid
        WHERE RIGHT(C.MobileNo, 10) = @MobileNo
          AND ISNULL(B.Account_No, '') <> ''
          AND ISNULL(B.IFSC_Code, '') <> ''
          AND C.IsDelete = 0
        ORDER BY B.Row_ID DESC;
    END
    -- 2. If not found in M_BankAccount, check table MobileToAccount_Audit
    ELSE IF EXISTS (
        SELECT 1 
        FROM MobileToAccount_Audit 
        WHERE RIGHT(MobileNo, 10) = @MobileNo
    )
    BEGIN
        SELECT TOP 1
            CAST(1 AS BIT)   AS success,
            Name_At_Bank     AS name_at_bank,
            Account_Number   AS account_number,
            IFSC_Code        AS ifsc_code,
            Bank_Reference   AS bank_reference,
            Reference_Id     AS reference_id,
            Requested_At     AS requested_at
        FROM MobileToAccount_Audit
        WHERE RIGHT(MobileNo, 10) = @MobileNo
        ORDER BY Completed_At DESC, Id DESC;
    END
    -- 3. If not found in either table
    ELSE
    BEGIN
        SELECT
            CAST(0 AS BIT) AS success,
            NULL AS name_at_bank,
            NULL AS account_number,
            NULL AS ifsc_code,
            NULL AS bank_reference,
            NULL AS reference_id,
            NULL AS requested_at;
    END
END
GO
