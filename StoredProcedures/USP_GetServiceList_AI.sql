-- =============================================
-- Procedure: USP_GetServiceList_AI
-- Description: Fetch active services from M_Service table
-- Called from: VendorController.cs -> GET /api/vendor/services/serviceList
-- =============================================
IF OBJECT_ID('USP_GetServiceList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceList_AI
GO

CREATE PROCEDURE USP_GetServiceList_AI
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Service_ID, 
        ServiceName, 
        IsShowPrice, 
        EntryDate, 
        Image, 
        IsActive, 
        IsDelete 
    FROM M_Service 
    WHERE IsActive = 0 AND IsDelete = 0;
END
GO
