CREATE OR ALTER PROCEDURE [dbo].[USP_GetAppErrorLogs_AI]
(
    @Page            INT = 1,
    @Limit           INT = 10,
    @Search          NVARCHAR(250) = NULL,
    @ApplicationType VARCHAR(50) = NULL,
    @DatePreset      VARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------
    -- Pagination Defaults
    ----------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ----------------------------------------------------
    -- Date Range Calculation based on DatePreset
    ----------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

    IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
    BEGIN
        SET @DatePreset = LOWER(LTRIM(RTRIM(@DatePreset)));
        IF @DatePreset = 'today'
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'yesterday'
        BEGIN
            SET @StartDate = CAST(DATEADD(day, -1, GETDATE()) AS DATE);
            SET @EndDate = DATEADD(second, 86399, CAST(CAST(DATEADD(day, -1, GETDATE()) AS DATE) AS DATETIME));
        END
        ELSE IF @DatePreset = 'last 7 days'
        BEGIN
            SET @StartDate = CAST(DATEADD(day, -7, GETDATE()) AS DATE);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'last 30 days'
        BEGIN
            SET @StartDate = CAST(DATEADD(day, -30, GETDATE()) AS DATE);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'this month'
        BEGIN
            SET @StartDate = CAST(DATEADD(day, -DAY(GETDATE()) + 1, GETDATE()) AS DATE);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'last month'
        BEGIN
            SET @StartDate = CAST(DATEADD(month, -1, DATEADD(day, -DAY(GETDATE()) + 1, GETDATE())) AS DATE);
            SET @EndDate = DATEADD(second, 86399, CAST(DATEADD(day, -DAY(GETDATE()), GETDATE()) AS DATE));
        END
    END

    ----------------------------------------------------
    -- Search Pattern Normalization
    ----------------------------------------------------
    DECLARE @SearchPattern NVARCHAR(252) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
    BEGIN
        SET @SearchPattern = '%' + LTRIM(RTRIM(@Search)) + '%';
    END

    ----------------------------------------------------
    -- RESULT SET 1 : PAGINATED DATA
    ----------------------------------------------------
    SELECT 
        el.Id,
        el.DeviceInfo,
        el.ApiResponse,
        el.ApiName,
        el.Username,
        el.UserMobile,
        el.PageName,
        el.ErrorResponse,
        el.ApplicationType,
        el.CreatedAt,
        mc.Comp_id AS CompId,
        cr.Comp_Name AS CompName
    FROM dbo.tbl_AppErrorLog el WITH (NOLOCK)
    OUTER APPLY (
        SELECT TOP 1 mc.Comp_id 
        FROM dbo.M_Consumer mc WITH (NOLOCK) 
        WHERE mc.IsDelete = 0 AND RIGHT(mc.MobileNo, 10) = RIGHT(el.UserMobile, 10)
    ) mc
    LEFT JOIN dbo.Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = mc.Comp_id
    WHERE 
        (@StartDate IS NULL OR el.CreatedAt >= @StartDate)
        AND (@EndDate IS NULL OR el.CreatedAt <= @EndDate)
        AND (@ApplicationType IS NULL OR LTRIM(RTRIM(@ApplicationType)) = '' OR el.ApplicationType = @ApplicationType)
        AND (@SearchPattern IS NULL OR 
             el.Username LIKE @SearchPattern 
             OR el.UserMobile LIKE @SearchPattern 
             OR el.ApiName LIKE @SearchPattern 
             OR el.PageName LIKE @SearchPattern 
             OR el.ErrorResponse LIKE @SearchPattern
             OR el.DeviceInfo LIKE @SearchPattern
             OR el.ApiResponse LIKE @SearchPattern
             OR mc.Comp_id LIKE @SearchPattern
             OR cr.Comp_Name LIKE @SearchPattern)
    ORDER BY el.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ----------------------------------------------------
    -- RESULT SET 2 : PAGINATION META
    ----------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM dbo.tbl_AppErrorLog el WITH (NOLOCK)
    OUTER APPLY (
        SELECT TOP 1 mc.Comp_id 
        FROM dbo.M_Consumer mc WITH (NOLOCK) 
        WHERE mc.IsDelete = 0 AND RIGHT(mc.MobileNo, 10) = RIGHT(el.UserMobile, 10)
    ) mc
    LEFT JOIN dbo.Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = mc.Comp_id
    WHERE 
        (@StartDate IS NULL OR el.CreatedAt >= @StartDate)
        AND (@EndDate IS NULL OR el.CreatedAt <= @EndDate)
        AND (@ApplicationType IS NULL OR LTRIM(RTRIM(@ApplicationType)) = '' OR el.ApplicationType = @ApplicationType)
        AND (@SearchPattern IS NULL OR 
             el.Username LIKE @SearchPattern 
             OR el.UserMobile LIKE @SearchPattern 
             OR el.ApiName LIKE @SearchPattern 
             OR el.PageName LIKE @SearchPattern 
             OR el.ErrorResponse LIKE @SearchPattern
             OR el.DeviceInfo LIKE @SearchPattern
             OR el.ApiResponse LIKE @SearchPattern
             OR mc.Comp_id LIKE @SearchPattern
             OR cr.Comp_Name LIKE @SearchPattern);
END
GO
