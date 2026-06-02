SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_UpdatePanEkyc_AI]
    @M_ConsumerId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        -- Insert into tblKycPanDataDetails if not exists and valid PAN
        INSERT INTO dbo.tblKycPanDataDetails
        (
            M_ConsumerId,
            InputPanName,
            PanName,
            PanRefrenceId,
            IspanVerify,
            PanReqdate,
            PanRemarks,
            ResponseCode,
            NameMatchScore,
            PanReqCount,
            Status,
            ReqCount,
            pancardNumber,
            KycMode,
            created_at,
            dateofbirth
        )
        SELECT DISTINCT
            a.M_ConsumerId,
            a.ConsumerName AS InputPanName,
            a.PanHolderName AS PanName,
            NULL AS PanRefrenceId,
            1 AS IspanVerify,
            GETDATE() AS PanReqdate,
            'E kyc done by backend' AS PanRemarks,
            100 AS ResponseCode,
            100 AS NameMatchScore,
            1 AS PanReqCount,
            1 AS Status,
            1 AS ReqCount,
            a.pancard_number AS pancardNumber,
            NULL AS KycMode,
            GETDATE() AS created_at,
            NULL AS dateofbirth
        FROM M_Consumer a
        LEFT JOIN tbl_Vendorvisekycstatus c ON a.M_ConsumerId = c.M_consumerId
        WHERE a.M_ConsumerId = @M_ConsumerId
          AND a.panekycStatus IS NULL
          AND a.pancard_number <> ''
          AND a.pancard_number LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]'
          AND UPPER(REPLACE(ISNULL(a.PanHolderName, ''), ' ', ''))
              = UPPER(REPLACE(ISNULL(a.ConsumerName, ''), ' ', ''))
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.tblKycPanDataDetails k
              WHERE k.M_ConsumerId = a.M_ConsumerId
          )
          AND c.VRKbl_KYC_status = 1;

        -- Update panekycStatus in M_Consumer
        UPDATE mc
        SET mc.panekycStatus = 1
        FROM M_Consumer mc
        INNER JOIN tblKycPanDataDetails k ON mc.M_ConsumerId = k.M_ConsumerId
        WHERE mc.M_ConsumerId = @M_ConsumerId
          AND k.PanRemarks = 'E kyc done by backend';

        COMMIT TRAN;
        SELECT 'PAN KYC updated successfully' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT ERROR_MESSAGE() AS Message, 0 AS Success;
    END CATCH
END
GO
