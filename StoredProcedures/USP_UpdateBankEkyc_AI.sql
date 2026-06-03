SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateBankEkyc_AI]
    @M_ConsumerId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        -- Insert into tblKycBankDataDetails if not exists and valid Bank details
        INSERT INTO dbo.tblKycBankDataDetails
        (
            M_ConsumerId,
            AccountHolderName,
            BankRefrenceId,
            IsBankAccountVerify,
            BankReqdate,
            BankReqCount,
            BankRemarks,
            ResponseCode,
            Status,
            ReqCount,
            IFSC_Code,
            AccountNo,
            KycMode,
            created_at
        )
        SELECT DISTINCT
            mc.M_ConsumerId,
            mba.Account_HolderNm,
            NULL AS BankRefrenceId,
            1 AS IsBankAccountVerify,
            GETDATE() AS BankReqdate,
            1 AS BankReqCount,
            'E kyc done by backend' AS BankRemarks,
            100 AS ResponseCode,
            1 AS Status,
            1 AS ReqCount,
            mba.IFSC_Code,
            mba.Account_No,
            NULL AS KycMode,
            GETDATE() AS created_at
        FROM M_Consumer mc
        INNER JOIN M_BankAccount mba ON mc.M_ConsumerId = mba.M_ConsumerId
        LEFT JOIN tbl_Vendorvisekycstatus v ON mc.M_ConsumerId = v.M_consumerId
        WHERE mc.M_ConsumerId = @M_ConsumerId
          AND mc.bankekycStatus IS NULL
          AND ISNULL(mba.Account_HolderNm, '') <> ''
          AND ISNULL(mc.ConsumerName, '') <> ''
          AND NOT EXISTS (
              SELECT value FROM STRING_SPLIT(UPPER(mba.Account_HolderNm), ' ') WHERE LTRIM(RTRIM(value)) <> ''
              EXCEPT
              SELECT value FROM STRING_SPLIT(UPPER(mc.ConsumerName), ' ') WHERE LTRIM(RTRIM(value)) <> ''
          )
          AND NOT EXISTS (
              SELECT value FROM STRING_SPLIT(UPPER(mc.ConsumerName), ' ') WHERE LTRIM(RTRIM(value)) <> ''
              EXCEPT
              SELECT value FROM STRING_SPLIT(UPPER(mba.Account_HolderNm), ' ') WHERE LTRIM(RTRIM(value)) <> ''
          )
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.tblKycBankDataDetails k
              WHERE k.M_ConsumerId = mc.M_ConsumerId
          )
          AND v.VRKbl_KYC_status = 1
          AND mba.Account_No IS NOT NULL
          AND LTRIM(RTRIM(mba.Account_No)) <> ''
          AND mba.Account_No NOT LIKE '%[^0-9]%'
          AND mba.IFSC_Code IS NOT NULL
          AND LTRIM(RTRIM(mba.IFSC_Code)) <> ''
          AND UPPER(mba.IFSC_Code) LIKE '[A-Z][A-Z][A-Z][A-Z]0[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]';

        -- Update bankekycStatus in M_Consumer
        UPDATE mc
        SET mc.bankekycStatus = 1
        FROM M_Consumer mc
        INNER JOIN tblKycBankDataDetails k ON mc.M_ConsumerId = k.M_ConsumerId
        WHERE mc.M_ConsumerId = @M_ConsumerId
          AND k.BankRemarks = 'E kyc done by backend';

        COMMIT TRAN;
        SELECT 'Bank KYC updated successfully' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT ERROR_MESSAGE() AS Message, 0 AS Success;
    END CATCH
END
GO
