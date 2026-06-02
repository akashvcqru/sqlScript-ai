SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_BL_ManageBlockCode]
    @Action VARCHAR(10),        -- 'GET', 'ADD', 'UNBLOCK'
    @Comp_Id VARCHAR(20) = NULL,
    @Code1 VARCHAR(20) = NULL,
    @Code2 VARCHAR(20) = NULL,
    @Search VARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @IsExport BIT = 0,
    @DatePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- Construct Date Range
    -------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@DatePreset,''))));
    
    IF @Win = '' OR @Win = 'NULL' SET @Win = 'ALL';

    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'WEEK'
    BEGIN
        SET DATEFIRST 1; -- Monday
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
        SET @EndDate   = @ThisMonthStart;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTYEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today), 1, 1);
    END
    ELSE IF @Win = 'ALL'
    BEGIN
        SET @StartDate = '1900-01-01';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'CUSTOM'
    BEGIN
        SET @StartDate = ISNULL(CAST(@FromDate AS DATE), '1900-01-01');
        SET @EndDate   = DATEADD(DAY, 1, ISNULL(CAST(@ToDate AS DATE), @Today));
    END
    ELSE
    BEGIN
        SET @StartDate = '1900-01-01';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    IF @Action = 'GET'
    BEGIN
        IF @IsExport = 1
        BEGIN
            SELECT 
                (CAST(mc.Code1 AS VARCHAR(50)) + CAST(mc.Code2 AS VARCHAR(50))) AS Code,
                pr.Pro_Name AS ProductName,
                mc.Block_Code_Date AS Block_Code_Date
            FROM M_Code mc WITH (NOLOCK)
            INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
            WHERE pr.Comp_ID = @Comp_Id 
              AND mc.blockCodeStatus = 1
              AND mc.Block_Code_Date >= @StartDate
              AND mc.Block_Code_Date < @EndDate
              AND (
                  @Search IS NULL 
                  OR CAST(mc.Code1 AS VARCHAR(50)) LIKE '%' + @Search + '%'
                  OR CAST(mc.Code2 AS VARCHAR(50)) LIKE '%' + @Search + '%'
                  OR (CAST(mc.Code1 AS VARCHAR(50)) + CAST(mc.Code2 AS VARCHAR(50))) LIKE '%' + @Search + '%'
              )
            ORDER BY mc.Block_Code_Date DESC;
        END
        ELSE
        BEGIN
            SELECT 
                (CAST(mc.Code1 AS VARCHAR(50)) + CAST(mc.Code2 AS VARCHAR(50))) AS Code,
                pr.Pro_Name AS ProductName,
                mc.Block_Code_Date AS Block_Code_Date
            FROM M_Code mc WITH (NOLOCK)
            INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
            WHERE pr.Comp_ID = @Comp_Id 
              AND mc.blockCodeStatus = 1
              AND mc.Block_Code_Date >= @StartDate
              AND mc.Block_Code_Date < @EndDate
              AND (
                  @Search IS NULL 
                  OR CAST(mc.Code1 AS VARCHAR(50)) LIKE '%' + @Search + '%'
                  OR CAST(mc.Code2 AS VARCHAR(50)) LIKE '%' + @Search + '%'
                  OR (CAST(mc.Code1 AS VARCHAR(50)) + CAST(mc.Code2 AS VARCHAR(50))) LIKE '%' + @Search + '%'
              )
            ORDER BY mc.Block_Code_Date DESC
            OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;

            -- Pagination metadata
            SELECT 
                COUNT(1) AS TotalRecords,
                @Page AS CurrentPage,
                @Limit AS Limit,
                CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
            FROM M_Code mc WITH (NOLOCK)
            INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
            WHERE pr.Comp_ID = @Comp_Id 
              AND mc.blockCodeStatus = 1
              AND mc.Block_Code_Date >= @StartDate
              AND mc.Block_Code_Date < @EndDate
              AND (
                  @Search IS NULL 
                  OR CAST(mc.Code1 AS VARCHAR(50)) LIKE '%' + @Search + '%'
                  OR CAST(mc.Code2 AS VARCHAR(50)) LIKE '%' + @Search + '%'
                  OR (CAST(mc.Code1 AS VARCHAR(50)) + CAST(mc.Code2 AS VARCHAR(50))) LIKE '%' + @Search + '%'
              );
        END
    END
    ELSE IF @Action = 'ADD'
    BEGIN
        UPDATE M_Code
        SET blockCodeStatus = 1,
            Block_Code_Date = GETDATE()
        WHERE Code1 = CAST(@Code1 AS NUMERIC(5,0)) 
          AND Code2 = CAST(@Code2 AS NUMERIC(8,0))
          AND Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WHERE Comp_ID = @Comp_Id);

        SELECT 1 AS Status, 'Code marked as Blocked.' AS Message;
    END
    ELSE IF @Action = 'UNBLOCK'
    BEGIN
        UPDATE M_Code
        SET blockCodeStatus = 0,
            Block_Code_Date = NULL
        WHERE Code1 = CAST(@Code1 AS NUMERIC(5,0)) 
          AND Code2 = CAST(@Code2 AS NUMERIC(8,0))
          AND Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WHERE Comp_ID = @Comp_Id);

        SELECT 1 AS Status, 'Code marked as Unblocked.' AS Message;
    END
END
GO
