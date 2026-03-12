-- =============================================
-- Procedure: USP_GetProductList_AI
-- Description: Returns product list for a company (Register Products report)
-- Called from: ProductController.cs -> GET /api/vendor/products/productList
-- =============================================
IF OBJECT_ID('USP_GetProductList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetProductList_AI
GO

CREATE PROCEDURE USP_GetProductList_AI
    @Comp_ID       NVARCHAR(50) = '',
    @PageNumber    INT = 1,
    @PageSize      INT = 10,
    @SearchQuery   NVARCHAR(200) = '',
    @TimeWindow    NVARCHAR(50) = '',
    @FromDate      DATETIME = NULL,
    @ToDate        DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Date Filtering Logic Map ─────────────────────────────────────────────
    DECLARE @CalculatedFromDate DATETIME = NULL;
    DECLARE @CalculatedToDate DATETIME = NULL;

    IF @TimeWindow = 'this week'
    BEGIN
        SET @CalculatedFromDate = DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @TimeWindow = 'lastweek' OR @TimeWindow = 'last week'
    BEGIN
        SET @CalculatedFromDate = DATEADD(week, DATEDIFF(week, 7, GETDATE()), 0);
        SET @CalculatedToDate = DATEADD(second, -1, DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0));
    END
    ELSE IF @TimeWindow = 'this month'
    BEGIN
        SET @CalculatedFromDate = DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @TimeWindow = 'last month'
    BEGIN
        SET @CalculatedFromDate = DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0);
        SET @CalculatedToDate = DATEADD(second, -1, DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0));
    END
    ELSE IF @TimeWindow = 'quarter'
    BEGIN
        SET @CalculatedFromDate = DATEADD(quarter, DATEDIFF(quarter, 0, GETDATE()), 0);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @TimeWindow = 'from to date'
    BEGIN
        SET @CalculatedFromDate = @FromDate;
        -- Ensure ToDate includes the entire day if time wasn't strictly provided
        SET @CalculatedToDate = ISNULL(DATEADD(day, 1, @ToDate), GETDATE()); 
    END

    -- ── Main Query ──────────────────────────────────────────────────────────
    SELECT
        COUNT(1) OVER()                                       AS TotalRecords,
        ROW_NUMBER() OVER (ORDER BY pr.Pro_Entry_Date DESC)   AS SNo,
        pr.Pro_ID,
        pr.Pro_Name,
        ISNULL(
            CONVERT(NVARCHAR, ml.Label_Name) + ' ( ' + ml.Label_Size + ' )',
            'N/A'
        )                                                     AS LabelName,
        ISNULL(ml.Label_Prise, 0)                             AS RatePerLabel,
        CASE
            WHEN ISNULL(pr.Pro_Desc, '') = '' THEN '---'
            ELSE pr.Pro_Desc
        END                                                   AS ProDesc,
        '../Data/Sound/'
            + SUBSTRING(pr.Comp_ID, 6, 4)
            + '/' + pr.Pro_ID
            + '/' + pr.Pro_ID + '.mp3'                        AS SoundPath,
        CASE
            WHEN pr.Doc_Flag = 1 AND pr.Sound_Flag = 1 THEN 'Verified'
            ELSE 'Pending'
        END                                                   AS Status,
        pr.Pro_Entry_Date,
        pr.Label_Code,
        ISNULL(pr.BatchSize, 0)                               AS BatchSize,
        ISNULL(pr.Dispatch_Location, '')                      AS Dispatch_Location
    FROM   Pro_Reg pr
    LEFT JOIN M_Label ml ON pr.Label_Code = ml.Label_Code
    WHERE
        ('' = @Comp_ID OR pr.Comp_ID = @Comp_ID)
        AND (@SearchQuery = '' OR pr.Pro_Name LIKE '%' + @SearchQuery + '%')
        AND (
            @CalculatedFromDate IS NULL 
            OR pr.Pro_Entry_Date >= @CalculatedFromDate
        )
        AND (
            @CalculatedToDate IS NULL 
            OR pr.Pro_Entry_Date <= @CalculatedToDate
        )
    ORDER BY pr.Pro_Entry_Date DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS 
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
