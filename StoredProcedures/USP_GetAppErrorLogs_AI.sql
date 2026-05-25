CREATE PROCEDURE [dbo].[USP_GetAppErrorLogs_AI]
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
        Id,
        DeviceInfo,
        ApiResponse,
        ApiName,
        Username,
        UserMobile,
        PageName,
        ErrorResponse,
        ApplicationType,
        CreatedAt
    FROM dbo.tbl_AppErrorLog
    WHERE 
        (@StartDate IS NULL OR CreatedAt >= @StartDate)
        AND (@EndDate IS NULL OR CreatedAt <= @EndDate)
        AND (@ApplicationType IS NULL OR LTRIM(RTRIM(@ApplicationType)) = '' OR ApplicationType = @ApplicationType)
        AND (@SearchPattern IS NULL OR 
             Username LIKE @SearchPattern 
             OR UserMobile LIKE @SearchPattern 
             OR ApiName LIKE @SearchPattern 
             OR PageName LIKE @SearchPattern 
             OR ErrorResponse LIKE @SearchPattern
             OR DeviceInfo LIKE @SearchPattern
             OR ApiResponse LIKE @SearchPattern)
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ----------------------------------------------------
    -- RESULT SET 2 : PAGINATION META
    ----------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM dbo.tbl_AppErrorLog
    WHERE 
        (@StartDate IS NULL OR CreatedAt >= @StartDate)
        AND (@EndDate IS NULL OR CreatedAt <= @EndDate)
        AND (@ApplicationType IS NULL OR LTRIM(RTRIM(@ApplicationType)) = '' OR ApplicationType = @ApplicationType)
        AND (@SearchPattern IS NULL OR 
             Username LIKE @SearchPattern 
             OR UserMobile LIKE @SearchPattern 
             OR ApiName LIKE @SearchPattern 
             OR PageName LIKE @SearchPattern 
             OR ErrorResponse LIKE @SearchPattern
             OR DeviceInfo LIKE @SearchPattern
             OR ApiResponse LIKE @SearchPattern);
END
GO
