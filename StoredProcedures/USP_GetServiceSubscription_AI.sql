-- =============================================
-- Procedure: USP_GetServiceSubscription_AI
-- Description: Fetch all service subscriptions for a company
-- =============================================
IF OBJECT_ID('USP_GetServiceSubscription_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceSubscription_AI
GO

CREATE PROCEDURE USP_GetServiceSubscription_AI
    @Comp_ID NVARCHAR(50),
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        SS.Subscribe_Id,
        SS.Service_ID,
        P.Comp_ID,
        P.Pro_ID,
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
        P.Pro_Name,
        COUNT(*) OVER() AS TotalRecords
    FROM Pro_Reg P
    LEFT JOIN M_ServiceSubscription SS ON P.Pro_ID = SS.Pro_ID AND (SS.IsDelete = 0 OR SS.IsDelete IS NULL)
    LEFT JOIN M_Service S ON SS.Service_ID = S.Service_ID
    WHERE P.Comp_ID = @Comp_ID
    ORDER BY COALESCE(SS.EntryDate, P.Pro_Entry_Date) DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
