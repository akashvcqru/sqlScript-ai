-- =============================================
-- Procedure: USP_GetServiceSubscription_AI
-- Description: Fetch service subscription details for a company
-- Called from: VendorController.cs -> GET /api/vendor/services/getServiceSubscription
-- =============================================
IF OBJECT_ID('USP_GetServiceSubscription_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceSubscription_AI
GO

CREATE PROCEDURE USP_GetServiceSubscription_AI
    @Comp_ID NVARCHAR(100) = NULL,
    @Pro_ID NVARCHAR(100) = NULL,
    @Service_ID NVARCHAR(100) = NULL,
    @Subscribe_Id NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.Subscribe_Id, 
        t.Service_ID, 
        t.Comp_ID, 
        t.Pro_ID, 
        t.Plan_ID, 
        t.PlanName, 
        t.PlanMasterPeriod, 
        t.PlanSalePeriod, 
        t.PlanMasterPrice, 
        t.PlanSalePrice, 
        t.DateFrom, 
        t.DateTo, 
        t.EntryDate, 
        t.IsActive, 
        t.IsDelete, 
        t.IsAdminVerify, 
        CASE 
            WHEN t.start_order IS NULL THEN m.ServiceName 
            ELSE CONCAT(m.ServiceName, CONCAT(t.start_order, '-', t.start_series, ',', CONCAT(t.end_order, '-', t.end_series))) 
        END AS ServiceName, 
        p.Pro_Name 
    FROM M_ServiceSubscription AS t 
    INNER JOIN Pro_Reg AS p ON t.Pro_ID = p.Pro_ID 
    INNER JOIN M_Service AS m ON t.Service_ID = m.Service_ID  
    WHERE (@Comp_ID IS NULL OR t.Comp_ID = @Comp_ID)
      AND (@Pro_ID IS NULL OR t.Pro_ID = @Pro_ID)
      AND (@Service_ID IS NULL OR t.Service_ID = @Service_ID)
      AND (@Subscribe_Id IS NULL OR t.Subscribe_Id = @Subscribe_Id)
      AND t.IsDelete = 0 
    ORDER BY t.EntryDate DESC
END
GO
