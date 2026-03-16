-- =============================================
-- Procedure: USP_GetServiceSubscription_AI
-- Description: Fetch all service subscriptions for a company
-- =============================================
IF OBJECT_ID('USP_GetServiceSubscription_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceSubscription_AI
GO

CREATE PROCEDURE USP_GetServiceSubscription_AI
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        SS.Subscribe_Id,
        SS.Service_ID,
        SS.Comp_ID,
        SS.Pro_ID,
        SS.Plan_ID,
        SS.PlanName,
        SS.PlanMasterPeriod,
        SS.PlanSalePeriod,
        SS.PlanMasterPrice,
        SS.PlanSalePrice,
        SS.DateFrom,
        SS.DateTo,
        SS.EntryDate,
        SS.IsActive,
        SS.IsDelete,
        SS.IsAdminVerify,
        S.ServiceName,
        P.Pro_Name
    FROM M_ServiceSubscription SS
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    WHERE SS.Comp_ID = @Comp_ID
      AND (SS.IsDelete = 0 OR SS.IsDelete IS NULL)
    ORDER BY SS.EntryDate DESC;
END
GO
