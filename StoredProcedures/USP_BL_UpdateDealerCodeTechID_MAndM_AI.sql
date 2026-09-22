SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-09-22
-- Description: Verify and Update DealerCode and DealerTechnicianId for Mahindra & Mahindra
-- =============================================
-- EXEC [dbo].[USP_BL_UpdateDealerCodeTechID_MAndM_AI] @Comp_Id = 'Comp-1152', @M_Consumerid = '34022', @DealerCode = 'LHR551469', @DealerTechnicianId = '179592'
CREATE OR ALTER PROCEDURE [dbo].[USP_BL_UpdateDealerCodeTechID_MAndM_AI]
    @Comp_Id            VARCHAR(50),
    @M_Consumerid       VARCHAR(50),
    @DealerCode         VARCHAR(50),
    @DealerTechnicianId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActualCompId VARCHAR(50) = ISNULL(@Comp_Id, 'Comp-1152');
    IF (@ActualCompId = 'Comp-2345' OR @ActualCompId = '')
    BEGIN
        SET @ActualCompId = 'Comp-1152';
    END

    -- Validate input parameters
    IF (@M_Consumerid IS NULL OR LTRIM(RTRIM(@M_Consumerid)) = ''
        OR @DealerCode IS NULL OR LTRIM(RTRIM(@DealerCode)) = ''
        OR @DealerTechnicianId IS NULL OR LTRIM(RTRIM(@DealerTechnicianId)) = '')
    BEGIN
        SELECT 0 AS Success, 'Missing required parameters.' AS Message;
        RETURN;
    END

    SET @M_Consumerid = LTRIM(RTRIM(@M_Consumerid));
    SET @DealerCode = LTRIM(RTRIM(@DealerCode));
    SET @DealerTechnicianId = LTRIM(RTRIM(@DealerTechnicianId));

    -- Verify existence in m_dealermaster or m_dealermaster_mahindra_emp
    DECLARE @CountMaster INT = 0;
    DECLARE @CountEmp INT = 0;

    SELECT @CountMaster = COUNT(1) 
    FROM m_dealermaster WITH (NOLOCK)
    WHERE DealerTechnicianId = @DealerTechnicianId 
      AND DealerCode = @DealerCode 
      AND Comp_id = @ActualCompId;

    SELECT @CountEmp = COUNT(1) 
    FROM m_dealermaster_mahindra_emp WITH (NOLOCK)
    WHERE DealerTechnicianId = @DealerTechnicianId 
      AND DealerCode = @DealerCode 
      AND Comp_id = @ActualCompId;

    IF (@CountMaster > 0 OR @CountEmp > 0)
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            -- Update M_Consumer
            UPDATE M_Consumer 
            SET employeeID = @DealerTechnicianId, 
                distributorID = @DealerCode, 
                IsActive = 1 
            WHERE M_Consumerid = @M_Consumerid;

            -- Update UserData_MHCroneJob
            UPDATE UserData_MHCroneJob 
            SET DealerTechnicianId = @DealerTechnicianId, 
                DealerCode = @DealerCode 
            WHERE M_Consumerid = @M_Consumerid;

            COMMIT TRANSACTION;

            SELECT 1 AS Success, 'Dealer Code and Technician ID updated successfully.' AS Message;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
        END CATCH
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid enter Dealer Code or DealerTechnicianId.' AS Message;
    END
END
GO
