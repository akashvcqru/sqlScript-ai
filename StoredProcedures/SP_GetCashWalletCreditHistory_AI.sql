USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_GetCashWalletCreditHistory_AI]
    @CompId NVARCHAR(50) = NULL,
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @Search NVARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    DECLARE @CompanyStartDate DATETIME = '2015-01-01';
    IF (@CompId IS NOT NULL AND @CompId <> '' AND @CompId <> 'null')
    BEGIN
        SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @CompId AND Status = 1;
    END

    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    -- Explicit date range wins
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        SET @datePreset = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

        IF (@datePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTDAY' OR @datePreset = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@datePreset = 'WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@datePreset = 'LAST7DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LAST30DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    -- Build paged result set
    SELECT 
        b.Comp_Id AS Comp_Id,
        c.Comp_Name AS Comp_Name,
        b.OldBal AS OldBal,
        b.Amount AS Amount,
        b.NewBal AS NewBal,
        b.Cr_Dr_Type AS Cr_Dr_Type,
        b.ReqDate AS ReqDate
    INTO #TempReport
    FROM tblCashWalletBalance b WITH (NOLOCK)
    INNER JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = b.Comp_Id
    WHERE b.M_Consumerid IS NULL 
      AND b.PayrefId IS NULL
      AND b.ReqDate >= @StartDate
      AND b.ReqDate < @EndDate
      AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'null' OR b.Comp_Id = @CompId)
      AND (
          @Search IS NULL 
          OR LTRIM(RTRIM(@Search)) = '' 
          OR c.Comp_Name LIKE '%' + @Search + '%' 
          OR b.Comp_Id LIKE '%' + @Search + '%'
      );

    -- Result Set 1: Data Rows
    SELECT 
        Comp_Id,
        Comp_Name,
        OldBal,
        Amount,
        NewBal,
        Cr_Dr_Type,
        ReqDate
    FROM #TempReport
    ORDER BY ReqDate DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    -- Result Set 2: Pagination Metadata
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #TempReport;

    DROP TABLE #TempReport;
END
GO
