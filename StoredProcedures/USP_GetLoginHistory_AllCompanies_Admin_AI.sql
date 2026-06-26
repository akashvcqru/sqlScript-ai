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

    -- Explicit date range wins
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        SET @DatePreset = UPPER(LTRIM(RTRIM(ISNULL(@DatePreset, ''))));

        IF (@DatePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTDAY' OR @DatePreset = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@DatePreset = 'WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@DatePreset = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@DatePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@DatePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@DatePreset = 'LAST7DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@DatePreset = 'LAST30DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            SET @StartDate = '2015-01-01';
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    -- Query for total count (only if not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM Tbl_Login_History lh WITH (NOLOCK)
        LEFT JOIN Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = lh.Comp_ID
        WHERE (@Search IS NULL OR lh.Comp_ID LIKE '%' + @Search + '%' OR cr.Comp_Name LIKE '%' + @Search + '%')
          AND (@StartDate IS NULL OR lh.LoginTime >= @StartDate)
          AND (@EndDate IS NULL OR lh.LoginTime < @EndDate);
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
      AND (@EndDate IS NULL OR lh.LoginTime < @EndDate)
    ORDER BY lh.LoginTime DESC
    OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY;
END
GO
