-- Migration: Fix duplicate records in SP_PFL_GetBatchScrapeDetails
-- Date: 2026-08-18

CREATE OR ALTER PROCEDURE [dbo].[SP_PFL_GetBatchScrapeDetails]
(
    @BatchNo      NVARCHAR(50) = NULL,
    @MobileNo     NVARCHAR(20) = NULL,
    @FromSerial   NVARCHAR(50) = NULL,
    @ToSerial     NVARCHAR(50) = NULL,
    @Id           INT = NULL,

    @Page         INT = NULL,
    @Limit        INT = NULL,
    @IsExport     BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DROP TABLE IF EXISTS #FinalData;

    -------------------------------------------------
    -- Pagination defaults
    -------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -------------------------------------------------
    -- Main Data Load
    -------------------------------------------------
    SELECT
        s.Id,
        s.SerialCode,
        CONCAT(s.Code1, s.Code2) AS ScrapedCode,
        s.ScrapedBy AS MobileNo,
        u.UserName,
        s.ScrapedDate,
        b.[Batch No] AS BatchNo,
        b.SKU
    INTO #FinalData
    FROM PFL_Batchlist b WITH (NOLOCK)
    INNER JOIN tblScrapdatapfl s WITH (NOLOCK)
        ON s.SerialCode >= b.[From] 
       AND s.SerialCode <= b.[To]
       AND s.CompanyId = 'Comp-1693'
    LEFT JOIN (
        SELECT UserMobile, MAX(UserName) AS UserName
        FROM tbl_pflUsers WITH (NOLOCK)
        GROUP BY UserMobile
    ) u ON u.UserMobile = s.ScrapedBy
    WHERE (@MobileNo IS NULL OR s.ScrapedBy = @MobileNo)
      AND (@BatchNo IS NULL OR b.[Batch No] = @BatchNo)
      AND (@FromSerial IS NULL OR s.SerialCode >= @FromSerial)
      AND (@ToSerial IS NULL OR s.SerialCode <= @ToSerial)
      AND NOT EXISTS (
           SELECT 1
           FROM M_code_PFL m WITH (NOLOCK)
           WHERE m.code1 = s.code1
             AND m.code2 = s.code2
             AND m.ScrapeFlag = 1
      );

    -------------------------------------------------
    -- Output
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT *
        FROM #FinalData
        ORDER BY ScrapedDate DESC;
    END
    ELSE
    BEGIN
        SELECT *
        FROM #FinalData
        ORDER BY ScrapedDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
