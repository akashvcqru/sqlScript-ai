SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateBankEkyc_AI]
    @M_ConsumerId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ConsumerName NVARCHAR(200);
    DECLARE @AccountHolderName NVARCHAR(200);
    DECLARE @AccountNo VARCHAR(50);
    DECLARE @IfscCode VARCHAR(20);

    SELECT TOP 1 
        @ConsumerName = mc.ConsumerName,
        @AccountHolderName = mba.Account_HolderNm,
        @AccountNo = mba.Account_No,
        @IfscCode = mba.IFSC_Code
    FROM M_Consumer mc
    INNER JOIN M_BankAccount mba ON mc.M_ConsumerId = mba.M_ConsumerId
    WHERE mc.M_ConsumerId = @M_ConsumerId;

    -- If Bank Details are valid
    IF @AccountNo IS NOT NULL AND LTRIM(RTRIM(@AccountNo)) <> '' AND @AccountNo NOT LIKE '%[^0-9]%'
       AND @IfscCode IS NOT NULL AND LTRIM(RTRIM(@IfscCode)) <> '' AND UPPER(@IfscCode) LIKE '[A-Z][A-Z][A-Z][A-Z]0[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]'
       AND ISNULL(@AccountHolderName, '') <> '' AND ISNULL(@ConsumerName, '') <> ''
    BEGIN
        -- Clean and Split comparison logic in T-SQL
        DECLARE @CleanName1 NVARCHAR(200) = LTRIM(RTRIM(UPPER(@AccountHolderName)));
        DECLARE @CleanName2 NVARCHAR(200) = LTRIM(RTRIM(UPPER(@ConsumerName)));

        IF @CleanName1 LIKE 'MR %' SET @CleanName1 = LTRIM(SUBSTRING(@CleanName1, 4, LEN(@CleanName1)))
        ELSE IF @CleanName1 LIKE 'MRS %' SET @CleanName1 = LTRIM(SUBSTRING(@CleanName1, 5, LEN(@CleanName1)))
        ELSE IF @CleanName1 LIKE 'MS %' SET @CleanName1 = LTRIM(SUBSTRING(@CleanName1, 4, LEN(@CleanName1)));

        IF @CleanName2 LIKE 'MR %' SET @CleanName2 = LTRIM(SUBSTRING(@CleanName2, 4, LEN(@CleanName2)))
        ELSE IF @CleanName2 LIKE 'MRS %' SET @CleanName2 = LTRIM(SUBSTRING(@CleanName2, 5, LEN(@CleanName2)))
        ELSE IF @CleanName2 LIKE 'MS %' SET @CleanName2 = LTRIM(SUBSTRING(@CleanName2, 4, LEN(@CleanName2)));

        DECLARE @TotalTokens INT = 0;
        DECLARE @MatchCount INT = 0;
        DECLARE @MatchPercentage DECIMAL(5,2) = 0.00;

        SELECT @TotalTokens = COUNT(1) FROM STRING_SPLIT(@CleanName1, ' ') WHERE LTRIM(RTRIM(value)) <> '';

        IF @TotalTokens > 0
        BEGIN
            SELECT @MatchCount = COUNT(DISTINCT t1.value)
            FROM (SELECT value FROM STRING_SPLIT(@CleanName1, ' ') WHERE LTRIM(RTRIM(value)) <> '') t1
            CROSS APPLY (SELECT value FROM STRING_SPLIT(@CleanName2, ' ') WHERE LTRIM(RTRIM(value)) <> '') t2
            WHERE t2.value LIKE '%' + t1.value + '%';

            SET @MatchPercentage = CAST(@MatchCount AS DECIMAL(5,2)) / CAST(@TotalTokens AS DECIMAL(5,2)) * 100.00;
        END

        -- If match is less than 60%, return early with mismatch message
        IF @MatchPercentage < 60.00
        BEGIN
            SELECT 'Name mismatch' AS Message, 0 AS Success, @AccountHolderName AS HolderName;
            RETURN;
        END
        ELSE
        BEGIN
            -- Check if they are not identical tokens
            IF EXISTS (
                SELECT value FROM STRING_SPLIT(UPPER(@AccountHolderName), ' ') WHERE LTRIM(RTRIM(value)) <> ''
                EXCEPT
                SELECT value FROM STRING_SPLIT(UPPER(@ConsumerName), ' ') WHERE LTRIM(RTRIM(value)) <> ''
            ) OR EXISTS (
                SELECT value FROM STRING_SPLIT(UPPER(@ConsumerName), ' ') WHERE LTRIM(RTRIM(value)) <> ''
                EXCEPT
                SELECT value FROM STRING_SPLIT(UPPER(@AccountHolderName), ' ') WHERE LTRIM(RTRIM(value)) <> ''
            )
            BEGIN
                -- Update ConsumerName with AccountHolderName instead of rejecting
                UPDATE M_Consumer
                SET ConsumerName = @AccountHolderName
                WHERE M_ConsumerId = @M_ConsumerId;

                -- Refresh local variable for subsequent EKYC steps
                SET @ConsumerName = @AccountHolderName;
            END
        END
    END

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
