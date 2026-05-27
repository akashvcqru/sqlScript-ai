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
    @exportFormat VARCHAR(50) = NULL
AS
BEGIN
  SET NOCOUNT ON;

    ----------------------------------------------------
    -- Normalize
    ----------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);

    ----------------------------------------------------
    -- Date Range Calculation based on DatePreset
    ----------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

    IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> '' AND LOWER(LTRIM(RTRIM(@DatePreset))) <> 'all'
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
        ELSE IF @DatePreset = 'last 7 days' OR @DatePreset = '7 days' OR @DatePreset = 'last7days'
        BEGIN
            SET @StartDate = CAST(DATEADD(day, -7, GETDATE()) AS DATE);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'last 30 days' OR @DatePreset = '30 days' OR @DatePreset = 'last30days'
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
    -- EXPORT MODE (NO PAGINATION)
    ----------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Email,
            Comp_ID,
            LoginTime,
            IPAddress,
            BrowserInfo,
            DeviceInfo,
            OperatingSystem,
            CASE 
                WHEN IsSuccess = 1 THEN 'Successful Login'
                ELSE 'Unsuccessful Login'
            END AS LoginStatus,
            [Message]
        FROM Tbl_Login_History
        WHERE Comp_ID = @Comp_ID
          AND (@StartDate IS NULL OR LoginTime >= @StartDate)
          AND (@EndDate IS NULL OR LoginTime <= @EndDate)
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
        Comp_ID,
        LoginTime,
        IPAddress,
        BrowserInfo,
        DeviceInfo,
        OperatingSystem,
        CASE 
            WHEN IsSuccess = 1 THEN 'Successful Login'
            ELSE 'Unsuccessful Login'
        END AS LoginStatus,
        [Message]
    FROM Tbl_Login_History
    WHERE Comp_ID = @Comp_ID
      AND (@StartDate IS NULL OR LoginTime >= @StartDate)
      AND (@EndDate IS NULL OR LoginTime <= @EndDate)
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
      AND (@EndDate IS NULL OR LoginTime <= @EndDate);
END
GO
