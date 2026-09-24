-- =============================================
-- Migration: 20260924_Update_USP_GetServiceSubscription_AI_Filters_Search_Export.sql
-- Description: Update USP_GetServiceSubscription_AI with Search, Filters and isExport support
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetServiceSubscription_AI]
    @Comp_ID       NVARCHAR(50),
    @PageNumber    INT = 1,
    @PageSize      INT = 10,
    @Search        NVARCHAR(100) = NULL,
    @Pro_ID        NVARCHAR(50) = NULL,
    @Service_ID    NVARCHAR(50) = NULL,
    @IsActive      INT = NULL,
    @DateFrom      DATETIME = NULL,
    @DateTo        DATETIME = NULL,
    @IsExport      BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SET @Comp_ID = LTRIM(RTRIM(@Comp_ID));
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');
    SET @Pro_ID = NULLIF(LTRIM(RTRIM(@Pro_ID)), '');
    SET @Service_ID = NULLIF(LTRIM(RTRIM(@Service_ID)), '');

    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;

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
    FROM Pro_Reg P WITH (NOLOCK)
    LEFT JOIN M_ServiceSubscription SS WITH (NOLOCK) ON P.Pro_ID = SS.Pro_ID AND (SS.IsDelete = 0 OR SS.IsDelete IS NULL)
    LEFT JOIN M_Service S WITH (NOLOCK) ON SS.Service_ID = S.Service_ID
    WHERE P.Comp_ID = @Comp_ID
      AND (@Pro_ID IS NULL OR P.Pro_ID = @Pro_ID OR P.Pro_ID LIKE '%' + @Pro_ID + '%')
      AND (@Service_ID IS NULL OR SS.Service_ID = @Service_ID)
      AND (@IsActive IS NULL OR SS.IsActive = @IsActive)
      AND (@DateFrom IS NULL OR SS.DateFrom >= @DateFrom OR SS.EntryDate >= @DateFrom)
      AND (@DateTo IS NULL OR SS.DateTo <= @DateTo OR SS.EntryDate <= @DateTo)
      AND (
          @Search IS NULL
          OR P.Pro_Name LIKE '%' + @Search + '%'
          OR P.Pro_ID LIKE '%' + @Search + '%'
          OR S.ServiceName LIKE '%' + @Search + '%'
          OR SS.Service_ID LIKE '%' + @Search + '%'
          OR SS.PlanName LIKE '%' + @Search + '%'
          OR SS.Subscribe_Id LIKE '%' + @Search + '%'
      )
    ORDER BY COALESCE(SS.EntryDate, P.Pro_Entry_Date) DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE (@PageNumber - 1) * @PageSize END ROWS
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END ROWS ONLY;
END
GO
