USE [Vcqru]
GO

/****** Object:  StoredProcedure [dbo].[SP_BL_GetCombinedActivityClaimPayoutReport_AI]    Script Date: 9/14/2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCombinedActivityClaimPayoutReport_AI]
(
    @CompId     VARCHAR(50),
    @MobileNo   VARCHAR(50)  = NULL,
    @Page       INT          = 1,
    @Limit      INT          = 50,
    @IsExport   BIT          = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Pagination Safety Defaults
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 50;
    IF @IsExport IS NULL SET @IsExport = 0;
    IF @MobileNo IS NOT NULL AND LTRIM(RTRIM(@MobileNo)) = '' SET @MobileNo = NULL;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Clean up Temp Tables if exist
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#CombinedResult') IS NOT NULL DROP TABLE #CombinedResult;
    IF OBJECT_ID('tempdb..#FinalCalculatedResult') IS NOT NULL DROP TABLE #FinalCalculatedResult;

    ---------------------------------------------------------
    -- 1. Combine Results directly from the 3 Pre-Populated Tables
    ---------------------------------------------------------
    CREATE TABLE #CombinedResult (
        [Type]       NVARCHAR(50),
        [Points]     DECIMAL(18,2),
        [Date]       DATETIME,
        [UniqueCode] NVARCHAR(100),
        [Pro_Name]   NVARCHAR(200),
        [Result]     NVARCHAR(50)
    );

    -- Point Earned
    INSERT INTO #CombinedResult ([Type], [Points], [Date], [UniqueCode], [Pro_Name], [Result])
    SELECT 
        'Point Earned'              AS [Type],
        ABS(ISNULL(WornPoint, 0))   AS [Points],
        Enq_Date                    AS [Date],
        ISNULL(UniqueCode, '')      AS [UniqueCode],
        ISNULL(Pro_Name, '')        AS [Pro_Name],
        ISNULL(Result, '')          AS [Result]
    FROM dbo.tbl_BL_CodesActivityReport_AI WITH (NOLOCK)
    WHERE Comp_ID = @CompId
      AND (@MobileNo IS NULL OR MobileNo = @MobileNo)
      AND [Result] = 'Verified';

    -- Point Claimed
    INSERT INTO #CombinedResult ([Type], [Points], [Date], [UniqueCode], [Pro_Name], [Result])
    SELECT 
        'Point Claimed'             AS [Type],
        -1 * ABS(ISNULL(Points, 0)) AS [Points],
        Claim_date                  AS [Date],
        ''                          AS [UniqueCode],
        ''                          AS [Pro_Name],
        ISNULL(PaymentStatus, '')   AS [Result]
    FROM dbo.tbl_BL_PaymentClaimReport_AI WITH (NOLOCK)
    WHERE Comp_ID = @CompId
      AND (@MobileNo IS NULL OR Mobileno = @MobileNo)
      AND (Claim_Status = 'Approved' OR Claim_Status = 'Pending');

    -- Point Paid
    INSERT INTO #CombinedResult ([Type], [Points], [Date], [UniqueCode], [Pro_Name], [Result])
    SELECT 
        'Point Paid'                AS [Type],
        -1 * ABS(ISNULL(Amount, 0)) AS [Points],
        ReqDate                     AS [Date],
        ISNULL(Code1, '') + ISNULL(Code2, '') AS [UniqueCode],
        ''                          AS [Pro_Name],
        ISNULL(BankStatus, '')      AS [Result]
    FROM dbo.tbl_BL_UPIPayoutReport_AI WITH (NOLOCK)
    WHERE Comp_ID = @CompId
      AND (@MobileNo IS NULL OR MobileNo = @MobileNo)
      AND BankStatus = 'Success' 
      AND ISNUMERIC(Code1) = 1 AND CAST(Code1 AS BIGINT) > 0;

    ---------------------------------------------------------
    -- 2. Final Output with Pagination & Running Balance
    ---------------------------------------------------------
    SELECT 
        [Type],
        [Points],
        [Date],
        [UniqueCode],
        [Pro_Name],
        [Result],
        SUM([Points]) OVER (
            ORDER BY [Date] ASC, [UniqueCode] ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS [RunningBalance]
    INTO #FinalCalculatedResult
    FROM #CombinedResult;

    IF @IsExport = 1
    BEGIN
        SELECT 
            [Type],
            [Points],
            [Date],
            [UniqueCode],
            [Pro_Name],
            [Result],
            [RunningBalance]
        FROM #FinalCalculatedResult
        ORDER BY [Date] DESC;
    END
    ELSE
    BEGIN
        -- Paginated records
        SELECT 
            [Type],
            [Points],
            [Date],
            [UniqueCode],
            [Pro_Name],
            [Result],
            [RunningBalance]
        FROM #FinalCalculatedResult
        ORDER BY [Date] DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata result set
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalCalculatedResult;
    END
END
GO
