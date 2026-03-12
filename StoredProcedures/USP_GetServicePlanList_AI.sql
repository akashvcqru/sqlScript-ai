-- =============================================
-- Procedure: USP_GetServicePlanList_AI
-- Description: Fetch active service plans from M_ServicePlan table by Service_ID
-- Called from: VendorController.cs -> GET /api/vendor/services/getServicePlan
-- =============================================
IF OBJECT_ID('USP_GetServicePlanList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServicePlanList_AI
GO

CREATE PROCEDURE USP_GetServicePlanList_AI
    @ServiceID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Get IsShowPrice flag for the service
    DECLARE @IsShowPrice INT;
    SELECT @IsShowPrice = IsShowPrice FROM M_Service WHERE Service_ID = @ServiceID;

    -- Return Service Info and Plan List
    SELECT 
        sp.Plan_ID, 
        sp.Service_ID,
        s.ServiceName, 
        sp.PlanName, 
        sp.PlanPeriod, 
        sp.PlanPrice, 
        sp.EntryDate, 
        ISNULL(@IsShowPrice, 0) AS IsShowPrice
    FROM M_ServicePlan sp
    INNER JOIN M_Service s ON sp.Service_ID = s.Service_ID
    WHERE sp.Service_ID = @ServiceID 
      AND sp.IsActive = 0 
      AND sp.IsDelete = 0;
END
GO
