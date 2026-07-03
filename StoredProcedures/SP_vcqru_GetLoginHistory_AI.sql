USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_vcqru_GetLoginHistory_AI]    Script Date: 5/27/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec SP_vcqru_GetLoginHistory_AI 'Comp-1555'
CREATE OR ALTER PROCEDURE [dbo].[SP_vcqru_GetLoginHistory_AI]
    @Comp_ID VARCHAR(15),
    @Page    INT = NULL,     
    @Limit   INT = NULL,
    @IsExport BIT = NULL,
    @datePreset VARCHAR(50) = NULL,
    @exportFormat VARCHAR(50) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
  SET NOCOUNT ON;

    ----------------------------------------------------
    -- Normalize
    ----------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);

    ----------------------------------------------------
    -- Date Range Calculation based on DatePreset / Custom Range
    ----------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

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

    ----------------------------------------------------
    -- EXPORT MODE (NO PAGINATION)
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Email,
            LoginTime,
            IPAddress,
            BrowserInfo,
            DeviceInfo,
            OperatingSystem,
            CASE 
                WHEN IsSuccess = 1 THEN 'Successful Login'
                ELSE 'Unsuccessful Login'
            END AS LoginStatus,
            [Message],
            Latitude,
            Longitude
        FROM Tbl_Login_History
        WHERE Comp_ID = @Comp_ID
          AND (@StartDate IS NULL OR LoginTime >= @StartDate)
          AND (@EndDate IS NULL OR LoginTime < @EndDate)
        ORDER BY LoginTime DESC;

        RETURN;
    END

    ----------------------------------------------------
    -- Pagination Defaults
    ----------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ----------------------------------------------------
    -- RESULT SET 1 : PAGINATED DATA
    ----------------------------------------------------
    SELECT 
        Email,
        LoginTime,
        IPAddress,
        BrowserInfo,
        DeviceInfo,
        OperatingSystem,
        CASE 
            WHEN IsSuccess = 1 THEN 'Successful Login'
            ELSE 'Unsuccessful Login'
        END AS LoginStatus,
        [Message],
        Latitude,
        Longitude
    FROM Tbl_Login_History
    WHERE Comp_ID = @Comp_ID
      AND (@StartDate IS NULL OR LoginTime >= @StartDate)
      AND (@EndDate IS NULL OR LoginTime < @EndDate)
    ORDER BY LoginTime DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ----------------------------------------------------
    -- RESULT SET 2 : PAGINATION META
    ----------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM Tbl_Login_History
    WHERE Comp_ID = @Comp_ID
      AND (@StartDate IS NULL OR LoginTime >= @StartDate)
      AND (@EndDate IS NULL OR LoginTime < @EndDate);
END
GO
