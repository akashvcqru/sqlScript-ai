SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--exec [dbo].[SP_BL_UpdateKycStatus_AI] 'Comp-2031','1','156308','Approved'
CREATE PROCEDURE [dbo].[SP_BL_UpdateKycStatus_AI]
    @Comp_Id        VARCHAR(15),
    @Status         NVARCHAR(20), --1,2
    @m_consumerid   NVARCHAR(20),
    @Comments       NVARCHAR(200) = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Validate required parameters
    ------------------------------------------------------
    IF (@Comp_Id IS NULL OR @Comp_Id = ''
        OR @Status IS NULL OR @Status = ''
        OR @m_consumerid IS NULL OR @m_consumerid = '')
    BEGIN
        SELECT 'Missing required parameters' AS Message, 0 AS Success;
        RETURN;
    END;

    ------------------------------------------------------
    -- Safely update tables using a transaction
    ------------------------------------------------------
    BEGIN TRY
        BEGIN TRAN;

        UPDATE M_Consumer 
        SET VRKbl_KYC_status = @Status,
            remark = @Comments
        WHERE Comp_id = @Comp_Id 
          AND M_Consumerid = @m_consumerid AND IsDelete=0;

        UPDATE tbl_Vendorvisekycstatus
        SET VRKbl_KYC_status = @Status,
            kycremark = @Comments
        WHERE Comp_id = @Comp_Id 
          AND M_consumerId = @m_consumerid;

		  IF EXISTS (
				SELECT 1 
				FROM UserData_MHCroneJob
				WHERE Comp_id = @Comp_Id 
				  AND M_consumerId = @m_consumerid
			)
			BEGIN
				UPDATE UserData_MHCroneJob
				SET VRKbl_KYC_status = @Status,
					kycremark = @Comments
				WHERE Comp_id = @Comp_Id 
				  AND M_consumerId = @m_consumerid;
			END

		  if(@Comp_Id='Comp-1152')
		  BEGIN
		  insert into TBL_SUPPORT(Mobile_Number,TechnicianID,DealerCode,Call_Status,Notes)
		  SELECT
        MobileNo, DealerTechnicianId,DealerCode,
        CASE 
            WHEN @Status = 1 THEN 'verified customer'
            WHEN @Status = 2 THEN 'NEED AADHAR'
            ELSE 'call again'
        END AS Call_Status,
        @Comments
    FROM UserData_MHCroneJob
    WHERE M_ConsumerId = @m_consumerid;
		  END

        COMMIT TRAN;

        SELECT 'KYC status updated successfully' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;

        SELECT 
            'Error updating KYC status: ' + ERROR_MESSAGE() AS Message,
            0 AS Success;
    END CATCH;
END
GO
