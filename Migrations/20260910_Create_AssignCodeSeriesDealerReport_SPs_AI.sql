-- Migration: 20260910_Create_AssignCodeSeriesDealerReport_SPs_AI.sql
-- Description: Create Stored Procedures for Assign Code Series Dealer Report Summary, Details, and Deletion

USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 1. USP_GetAssignCodeseriesdealerReportSummary_AI
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetAssignCodeseriesdealerReportSummary_AI]
(
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @DealerName NVARCHAR(100) = NULL,
    @FromSeries NVARCHAR(50) = NULL,
    @ToSeries NVARCHAR(50) = NULL,
    @Passcode NVARCHAR(20) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SET @DealerName = LTRIM(RTRIM(REPLACE(ISNULL(@DealerName, ''), '%20', ' ')));
    SET @FromSeries = LTRIM(RTRIM(REPLACE(ISNULL(@FromSeries, ''), '%20', ' ')));
    SET @ToSeries = LTRIM(RTRIM(REPLACE(ISNULL(@ToSeries, ''), '%20', ' ')));
    SET @Passcode = LTRIM(RTRIM(REPLACE(ISNULL(@Passcode, ''), '%20', ' ')));
    SET @Search = LTRIM(RTRIM(REPLACE(ISNULL(@Search, ''), '%20', ' ')));

    IF LEN(@DealerName) >= 2 AND LEFT(@DealerName, 1) = '"' AND RIGHT(@DealerName, 1) = '"'
        SET @DealerName = SUBSTRING(@DealerName, 2, LEN(@DealerName) - 2);

    DECLARE @StartDate DATETIME = @FromDate;
    DECLARE @EndDate   DATETIME = @ToDate;

    IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null' AND LOWER(@datePreset) <> 'all')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'WEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, DATEADD(DAY, 6, @StartDate)));
        END
        ELSE IF (@Win = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1));
        END
    END
    ELSE IF (@StartDate IS NOT NULL AND @EndDate IS NOT NULL)
    BEGIN
        IF CAST(@EndDate AS TIME) = '00:00:00'
            SET @EndDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @EndDate));
    END

    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + @Search + '%';

    ;WITH FilteredBase AS (
        SELECT 
            a.fromseries,
            a.toseries,
            a.Passcode,
            a.dealer_name,
            a.Comp_ID,
            a.Pro_ID,
            a.entry_date,
            pr.Pro_Name AS ProductName
        FROM [dbo].[tbl_assigncodelocation] a WITH (NOLOCK)
        LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) ON pr.Pro_ID = a.Pro_ID AND pr.Comp_ID = a.Comp_ID
        WHERE a.Comp_ID = @Comp_Id
          AND (@StartDate IS NULL OR a.entry_date >= @StartDate)
          AND (@EndDate IS NULL OR a.entry_date <= @EndDate)
          AND (@Passcode IS NULL OR @Passcode = '' OR a.Passcode = @Passcode)
          AND (@DealerName IS NULL OR @DealerName = '' OR a.dealer_name = @DealerName OR a.dealer_name LIKE '%' + @DealerName + '%')
          AND (@FromSeries IS NULL OR @FromSeries = '' OR a.fromseries = @FromSeries OR a.fromseries LIKE '%' + @FromSeries + '%')
          AND (@ToSeries IS NULL OR @ToSeries = '' OR a.toseries = @ToSeries OR a.toseries LIKE '%' + @ToSeries + '%')
          AND (@SearchParam IS NULL 
               OR a.Passcode LIKE @SearchParam 
               OR a.dealer_name LIKE @SearchParam 
               OR a.fromseries LIKE @SearchParam 
               OR a.toseries LIKE @SearchParam 
               OR pr.Pro_Name LIKE @SearchParam)
    ),
    GroupedResult AS (
        SELECT 
            fromseries AS FromSeries,
            toseries AS ToSeries,
            COUNT(1) AS Quantity,
            Passcode AS Passcode,
            dealer_name AS DealerName,
            MAX(entry_date) AS EntryDate,
            Pro_ID AS ProId,
            ProductName AS ProductName
        FROM FilteredBase
        GROUP BY fromseries, toseries, Passcode, dealer_name, Pro_ID, ProductName
    )
    SELECT * 
    FROM GroupedResult
    ORDER BY EntryDate DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS 
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @Limit END ROWS ONLY;

    IF @IsExport = 0
    BEGIN
        ;WITH FilteredBase AS (
            SELECT 
                a.fromseries,
                a.toseries,
                a.Passcode,
                a.dealer_name,
                a.Comp_ID,
                a.Pro_ID,
                pr.Pro_Name AS ProductName
            FROM [dbo].[tbl_assigncodelocation] a WITH (NOLOCK)
            LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) ON pr.Pro_ID = a.Pro_ID AND pr.Comp_ID = a.Comp_ID
            WHERE a.Comp_ID = @Comp_Id
              AND (@StartDate IS NULL OR a.entry_date >= @StartDate)
              AND (@EndDate IS NULL OR a.entry_date <= @EndDate)
              AND (@Passcode IS NULL OR @Passcode = '' OR a.Passcode = @Passcode)
              AND (@DealerName IS NULL OR @DealerName = '' OR a.dealer_name = @DealerName OR a.dealer_name LIKE '%' + @DealerName + '%')
              AND (@FromSeries IS NULL OR @FromSeries = '' OR a.fromseries = @FromSeries OR a.fromseries LIKE '%' + @FromSeries + '%')
              AND (@ToSeries IS NULL OR @ToSeries = '' OR a.toseries = @ToSeries OR a.toseries LIKE '%' + @ToSeries + '%')
              AND (@SearchParam IS NULL 
                   OR a.Passcode LIKE @SearchParam 
                   OR a.dealer_name LIKE @SearchParam 
                   OR a.fromseries LIKE @SearchParam 
                   OR a.toseries LIKE @SearchParam 
                   OR pr.Pro_Name LIKE @SearchParam)
            GROUP BY a.fromseries, a.toseries, a.Passcode, a.dealer_name, a.Comp_ID, a.Pro_ID, pr.Pro_Name
        )
        SELECT 
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM FilteredBase;
    END
END
GO

-- =============================================
-- 2. USP_GetAssignCodeseriesdealerReport_AI
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetAssignCodeseriesdealerReport_AI]
(
    @Comp_Id VARCHAR(50),
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @DealerName NVARCHAR(100) = NULL,
    @FromSeries NVARCHAR(50) = NULL,
    @ToSeries NVARCHAR(50) = NULL,
    @Passcode NVARCHAR(20) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SET @DealerName = LTRIM(RTRIM(REPLACE(ISNULL(@DealerName, ''), '%20', ' ')));
    SET @FromSeries = LTRIM(RTRIM(REPLACE(ISNULL(@FromSeries, ''), '%20', ' ')));
    SET @ToSeries = LTRIM(RTRIM(REPLACE(ISNULL(@ToSeries, ''), '%20', ' ')));
    SET @Passcode = LTRIM(RTRIM(REPLACE(ISNULL(@Passcode, ''), '%20', ' ')));
    SET @Search = LTRIM(RTRIM(REPLACE(ISNULL(@Search, ''), '%20', ' ')));

    IF LEN(@DealerName) >= 2 AND LEFT(@DealerName, 1) = '"' AND RIGHT(@DealerName, 1) = '"'
        SET @DealerName = SUBSTRING(@DealerName, 2, LEN(@DealerName) - 2);

    DECLARE @StartDate DATETIME = @FromDate;
    DECLARE @EndDate   DATETIME = @ToDate;

    IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null' AND LOWER(@datePreset) <> 'all')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'WEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, DATEADD(DAY, 6, @StartDate)));
        END
        ELSE IF (@Win = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1));
        END
    END
    ELSE IF (@StartDate IS NOT NULL AND @EndDate IS NOT NULL)
    BEGIN
        IF CAST(@EndDate AS TIME) = '00:00:00'
            SET @EndDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @EndDate));
    END

    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + @Search + '%';

    SELECT 
        a.ID AS Id,
        CONCAT(ISNULL(a.Code1, ''), '-', ISNULL(a.Code2, '')) AS Code,
        CONCAT(ISNULL(a.Pro_ID, ''), '-', ISNULL(a.Series_Order, ''), '-', ISNULL(a.Series_Serial, '')) AS Series,
        a.Pro_ID AS ProId,
        a.Series_Order AS SeriesOrder,
        a.Series_Serial AS SeriesSerial,
        a.Passcode AS Passcode,
        a.dealer_name AS DealerName,
        a.entry_date AS EntryDate
    FROM [dbo].[tbl_assigncodelocation] a WITH (NOLOCK)
    WHERE a.Comp_ID = @Comp_Id
      AND (@StartDate IS NULL OR a.entry_date >= @StartDate)
      AND (@EndDate IS NULL OR a.entry_date <= @EndDate)
      AND (@Passcode IS NULL OR @Passcode = '' OR a.Passcode = @Passcode)
      AND (@DealerName IS NULL OR @DealerName = '' OR a.dealer_name = @DealerName OR a.dealer_name LIKE '%' + @DealerName + '%')
      AND (@FromSeries IS NULL OR @FromSeries = '' OR a.fromseries = @FromSeries OR a.fromseries LIKE '%' + @FromSeries + '%')
      AND (@ToSeries IS NULL OR @ToSeries = '' OR a.toseries = @ToSeries OR a.toseries LIKE '%' + @ToSeries + '%')
      AND (@SearchParam IS NULL 
           OR a.Passcode LIKE @SearchParam 
           OR a.dealer_name LIKE @SearchParam 
           OR a.Code1 LIKE @SearchParam 
           OR a.Code2 LIKE @SearchParam 
           OR CONCAT(a.Code1, '-', a.Code2) LIKE @SearchParam 
           OR CONCAT(a.Code1, a.Code2) LIKE @SearchParam 
           OR a.fromseries LIKE @SearchParam 
           OR a.toseries LIKE @SearchParam 
           OR CONCAT(a.Pro_ID, '-', a.Series_Order, '-', a.Series_Serial) LIKE @SearchParam)
    ORDER BY a.entry_date DESC, a.ID DESC
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS 
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @Limit END ROWS ONLY;

    IF @IsExport = 0
    BEGIN
        SELECT 
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM [dbo].[tbl_assigncodelocation] a WITH (NOLOCK)
        WHERE a.Comp_ID = @Comp_Id
          AND (@StartDate IS NULL OR a.entry_date >= @StartDate)
          AND (@EndDate IS NULL OR a.entry_date <= @EndDate)
          AND (@Passcode IS NULL OR @Passcode = '' OR a.Passcode = @Passcode)
          AND (@DealerName IS NULL OR @DealerName = '' OR a.dealer_name = @DealerName OR a.dealer_name LIKE '%' + @DealerName + '%')
          AND (@FromSeries IS NULL OR @FromSeries = '' OR a.fromseries = @FromSeries OR a.fromseries LIKE '%' + @FromSeries + '%')
          AND (@ToSeries IS NULL OR @ToSeries = '' OR a.toseries = @ToSeries OR a.toseries LIKE '%' + @ToSeries + '%')
          AND (@SearchParam IS NULL 
               OR a.Passcode LIKE @SearchParam 
               OR a.dealer_name LIKE @SearchParam 
               OR a.Code1 LIKE @SearchParam 
               OR a.Code2 LIKE @SearchParam 
               OR CONCAT(a.Code1, '-', a.Code2) LIKE @SearchParam 
               OR CONCAT(a.Code1, a.Code2) LIKE @SearchParam 
               OR a.fromseries LIKE @SearchParam 
               OR a.toseries LIKE @SearchParam 
               OR CONCAT(a.Pro_ID, '-', a.Series_Order, '-', a.Series_Serial) LIKE @SearchParam);
    END
END
GO

-- =============================================
-- 3. USP_DeleteAssignCodeseriesdealerReport_AI
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_DeleteAssignCodeseriesdealerReport_AI]
(
    @Comp_Id VARCHAR(50),
    @Mode VARCHAR(20) = 'CODES', -- 'CODES' or 'BATCH'
    @Id INT = NULL,
    @Ids NVARCHAR(MAX) = NULL,
    @Code1 VARCHAR(20) = NULL,
    @Code2 VARCHAR(20) = NULL,
    @FromSeries NVARCHAR(50) = NULL,
    @ToSeries NVARCHAR(50) = NULL,
    @DealerName NVARCHAR(100) = NULL,
    @Passcode NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DeletedCount INT = 0;

    SET @DealerName = LTRIM(RTRIM(REPLACE(ISNULL(@DealerName, ''), '%20', ' ')));
    SET @FromSeries = LTRIM(RTRIM(REPLACE(ISNULL(@FromSeries, ''), '%20', ' ')));
    SET @ToSeries = LTRIM(RTRIM(REPLACE(ISNULL(@ToSeries, ''), '%20', ' ')));
    SET @Passcode = LTRIM(RTRIM(REPLACE(ISNULL(@Passcode, ''), '%20', ' ')));

    IF LEN(@DealerName) >= 2 AND LEFT(@DealerName, 1) = '"' AND RIGHT(@DealerName, 1) = '"'
        SET @DealerName = SUBSTRING(@DealerName, 2, LEN(@DealerName) - 2);

    IF UPPER(@Mode) = 'BATCH'
    BEGIN
        IF (@FromSeries IS NULL OR @FromSeries = '' OR @ToSeries IS NULL OR @ToSeries = '')
        BEGIN
            SELECT 0 AS DeletedCount, 0 AS Success, 'FromSeries and ToSeries are required for batch deletion.' AS Message;
            RETURN;
        END

        DELETE FROM [dbo].[tbl_assigncodelocation]
        WHERE Comp_ID = @Comp_Id
          AND fromseries = @FromSeries
          AND toseries = @ToSeries
          AND (@DealerName IS NULL OR @DealerName = '' OR dealer_name = @DealerName OR dealer_name LIKE '%' + @DealerName + '%')
          AND (@Passcode IS NULL OR @Passcode = '' OR Passcode = @Passcode);

        SET @DeletedCount = @@ROWCOUNT;

        SELECT @DeletedCount AS DeletedCount, 1 AS Success, CONCAT(@DeletedCount, ' code(s) removed from assigned series batch.') AS Message;
    END
    ELSE
    BEGIN
        IF (@Id IS NOT NULL AND @Id > 0)
        BEGIN
            DELETE FROM [dbo].[tbl_assigncodelocation]
            WHERE Comp_ID = @Comp_Id AND ID = @Id;

            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE IF (@Ids IS NOT NULL AND @Ids <> '')
        BEGIN
            DELETE FROM [dbo].[tbl_assigncodelocation]
            WHERE Comp_ID = @Comp_Id 
              AND ID IN (SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT) FROM STRING_SPLIT(@Ids, ',') WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL);

            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE IF (@Code1 IS NOT NULL AND @Code1 <> '' AND @Code2 IS NOT NULL AND @Code2 <> '')
        BEGIN
            DELETE FROM [dbo].[tbl_assigncodelocation]
            WHERE Comp_ID = @Comp_Id AND Code1 = @Code1 AND Code2 = @Code2;

            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            SELECT 0 AS DeletedCount, 0 AS Success, 'Valid ID, IDs, or Code1 & Code2 must be provided.' AS Message;
            RETURN;
        END

        SELECT @DeletedCount AS DeletedCount, 1 AS Success, CONCAT(@DeletedCount, ' code(s) deleted successfully.') AS Message;
    END
END
GO
