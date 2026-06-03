SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-08
-- Description: Update KYC status for Mahindra & Mahindra (Comp-1152)
-- =============================================
-- exec [dbo].[SP_BL_UpdateKycStatus_MAndM_AI] 'Comp-1152','1','156308','Approved'
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_UpdateKycStatus_MAndM_AI]
    @Comp_Id        VARCHAR(15),
    @Status         NVARCHAR(20), -- 0:Pending, 1:Approved, 2:Rejected
    @m_consumerid   NVARCHAR(20),
    @Comments       NVARCHAR(200) = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId VARCHAR(15) = @Comp_Id;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

    -- Validate required parameters
    IF (@Comp_Id IS NULL OR @Comp_Id = ''
        OR @Status IS NULL OR @Status = ''
        OR @m_consumerid IS NULL OR @m_consumerid = '')
    BEGIN
        SELECT 'Missing required parameters' AS Message, 0 AS Success;
        RETURN;
    END;

    -- Mahindra specific check (though the SP name implies it)
    IF (@ActualCompId <> 'Comp-1152')
    BEGIN
        SELECT 'This procedure is only for Mahindra & Mahindra (Comp-1152)' AS Message, 0 AS Success;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        -- Update main consumer table
        UPDATE M_Consumer 
        SET VRKbl_KYC_status = @Status,
            remark = @Comments
        WHERE Comp_id = @ActualCompId 
          AND M_Consumerid = @m_consumerid 
          AND IsDelete = 0;

        -- Update vendor specific KYC status table
        UPDATE tbl_Vendorvisekycstatus
        SET VRKbl_KYC_status = @Status,
            kycremark = @Comments
        WHERE Comp_id = @ActualCompId 
          AND M_consumerId = @m_consumerid;

        -- Update Mahindra Cron Job table if exists
        IF EXISTS (
            SELECT 1 
            FROM UserData_MHCroneJob
            WHERE Comp_id = @ActualCompId 
              AND M_consumerId = @m_consumerid
        )
        BEGIN
            UPDATE UserData_MHCroneJob
            SET VRKbl_KYC_status = @Status,
                kycremark = @Comments
            WHERE Comp_id = @ActualCompId 
              AND M_consumerId = @m_consumerid;
        END

        -- Mahindra specific support ticket logic
        INSERT INTO TBL_SUPPORT(Mobile_Number, TechnicianID, DealerCode, Call_Status, Notes)
        SELECT
            MobileNo, 
            DealerTechnicianId, 
            DealerCode,
            CASE 
                WHEN @Status = '1' THEN 'verified customer'
                WHEN @Status = '2' THEN 'NEED AADHAR'
                ELSE 'call again'
            END AS Call_Status,
            @Comments
        FROM UserData_MHCroneJob
        WHERE M_ConsumerId = @m_consumerid;

        COMMIT TRAN;

        SELECT 'KYC status updated successfully for Mahindra & Mahindra' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SELECT 
            'Error updating KYC status: ' + ERROR_MESSAGE() AS Message,
            0 AS Success;
    END CATCH;
END
GO
