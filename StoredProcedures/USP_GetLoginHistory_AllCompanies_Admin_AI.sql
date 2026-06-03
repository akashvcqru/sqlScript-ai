CREATE OR ALTER PROCEDURE [dbo].[USP_GetLoginHistory_AllCompanies_Admin_AI]
    @Search NVARCHAR(100) = NULL,
    @DatePreset NVARCHAR(50) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Offset INT = 0,
    @Limit INT = 10,
    @IsExport BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;
    DECLARE @Today     DATETIME = CAST(GETDATE() AS DATE);
    DECLARE @Now       DATETIME = GETDATE();

    -- Parse and handle DatePreset if provided
    IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
    BEGIN
        SET @DatePreset = LOWER(LTRIM(RTRIM(@DatePreset)));
        
        IF @DatePreset = 'today' OR @DatePreset = 'day' OR @DatePreset = 'dy'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'yesterday'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            -- Yesterday end of day (23:59:59.997 due to datetime rounding)
            SET @EndDate   = DATEADD(MILLISECOND, -3, @Today);
        END
        ELSE IF @DatePreset = 'week' OR @DatePreset = 'last 7 days'
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, @Today);
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'last 30 days'
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, @Today);
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'month' OR @DatePreset = 'this month'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'last month'
        BEGIN
            DECLARE @LastMonthStart DATETIME = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1));
            SET @StartDate = @LastMonthStart;
            -- Last month end of day
            SET @EndDate   = DATEADD(MILLISECOND, -3, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1));
        END
    END

    -- Explicit Date Range overrides DatePreset
    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END

    -- Query for total count (only if not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM Tbl_Login_History lh WITH (NOLOCK)
        LEFT JOIN Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = lh.Comp_ID
        WHERE (@Search IS NULL OR lh.Comp_ID LIKE '%' + @Search + '%' OR cr.Comp_Name LIKE '%' + @Search + '%')
          AND (@StartDate IS NULL OR lh.LoginTime >= @StartDate)
          AND (@EndDate IS NULL OR lh.LoginTime <= @EndDate);
    END

    -- Query for login history list
    SELECT 
        lh.Email,
        lh.Comp_ID,
        cr.Comp_Name AS CompName,
        lh.LoginTime,
        lh.IPAddress,
        lh.BrowserInfo,
        lh.DeviceInfo,
        lh.OperatingSystem,
        CASE 
            WHEN lh.IsSuccess = 1 THEN 'Successful Login'
            ELSE 'Unsuccessful Login'
        END AS LoginStatus,
        lh.[Message],
        lh.Latitude,
        lh.Longitude
    FROM Tbl_Login_History lh WITH (NOLOCK)
    LEFT JOIN Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = lh.Comp_ID
    WHERE (@Search IS NULL OR lh.Comp_ID LIKE '%' + @Search + '%' OR cr.Comp_Name LIKE '%' + @Search + '%')
      AND (@StartDate IS NULL OR lh.LoginTime >= @StartDate)
      AND (@EndDate IS NULL OR lh.LoginTime <= @EndDate)
    ORDER BY lh.LoginTime DESC
    OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY;
END
GO
