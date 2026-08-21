USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'ScrapProductBulkType')
BEGIN
    CREATE TYPE [dbo].[ScrapProductBulkType] AS TABLE(
        [CompId] [nvarchar](50) NULL,
        [ProId] [nvarchar](50) NULL,
        [Series_Order] [nvarchar](50) NULL,
        [Series_Serial] [nvarchar](50) NULL
    );
END
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_ScrapProductBulk_pfl_vcqru]
(
    @BulkData dbo.ScrapProductBulkType READONLY,
    @SuccessCount INT OUTPUT,
    @AlreadyScrapedCount INT OUTPUT,
    @NotFoundCount INT OUTPUT,
    @Message NVARCHAR(200) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Clean temp tables
    IF OBJECT_ID('tempdb..#InputRows') IS NOT NULL DROP TABLE #InputRows;
    IF OBJECT_ID('tempdb..#MatchedCodes') IS NOT NULL DROP TABLE #MatchedCodes;
    IF OBJECT_ID('tempdb..#NewCodesToScrape') IS NOT NULL DROP TABLE #NewCodesToScrape;

    -- 1. Parse and index input
    SELECT 
        CompId,
        ProId,
        TRY_CAST(Series_Order AS NUMERIC(10,0)) AS SeriesOrder,
        TRY_CAST(Series_Serial AS NUMERIC(4,0)) AS SeriesSerial,
        CONCAT(ProId, '-', Series_Order, '-', Series_Serial) AS SerialCode
    INTO #InputRows
    FROM @BulkData;

    CREATE CLUSTERED INDEX IX_Input_Pro_Series ON #InputRows(ProId, SeriesOrder, SeriesSerial);

    -- 2. Match with M_Code_PFL
    SELECT 
        mc.Code1,
        mc.Code2,
        mc.ScrapeFlag,
        inp.CompId,
        inp.SerialCode
    INTO #MatchedCodes
    FROM M_Code_PFL mc WITH (NOLOCK)
    INNER JOIN #InputRows inp 
        ON mc.Pro_ID = inp.ProId 
       AND mc.Series_Order = inp.SeriesOrder 
       AND mc.Series_Serial = inp.SeriesSerial;

    -- 3. Calculate counts
    DECLARE @TotalInput INT = (SELECT COUNT(1) FROM #InputRows);
    DECLARE @TotalMatched INT = (SELECT COUNT(1) FROM #MatchedCodes);
    
    SET @AlreadyScrapedCount = ISNULL((SELECT COUNT(1) FROM #MatchedCodes WHERE ScrapeFlag = 1), 0);
    SET @NotFoundCount = @TotalInput - @TotalMatched;

    -- Filter new codes to scrape
    SELECT * INTO #NewCodesToScrape FROM #MatchedCodes WHERE ISNULL(ScrapeFlag, 0) = 0;

    -- 4. Update M_Code_PFL ScrapeFlag
    UPDATE mc
    SET mc.ScrapeFlag = 1
    FROM M_Code_PFL mc
    INNER JOIN #NewCodesToScrape n ON mc.Code1 = n.Code1 AND mc.Code2 = n.Code2;

    SET @SuccessCount = @@ROWCOUNT;

    -- 5. Update existing records in tblScrapdatapfl
    UPDATE s
    SET s.scrapeCodeDate = GETDATE(),
        s.ScrapeCodeStatus = 1
    FROM tblScrapdatapfl s
    INNER JOIN #MatchedCodes mc 
        ON (s.Code1 = mc.Code1 AND s.Code2 = mc.Code2) 
        OR s.SerialCode = mc.SerialCode;

    -- 6. Insert missing records in tblScrapdatapfl
    INSERT INTO tblScrapdatapfl (Code1, Code2, SerialCode, CompanyId, ScrapedDate, scrapeCodeDate, ScrapeCodeStatus)
    SELECT 
        mc.Code1, 
        mc.Code2, 
        mc.SerialCode, 
        ISNULL(mc.CompId, 'Comp-1693'), 
        GETDATE(), 
        GETDATE(), 
        1
    FROM #MatchedCodes mc
    WHERE NOT EXISTS (
        SELECT 1 
        FROM tblScrapdatapfl s 
        WHERE (s.Code1 = mc.Code1 AND s.Code2 = mc.Code2) 
           OR s.SerialCode = mc.SerialCode
    );

    SET @Message = 'Bulk scrap completed successfully';

    DROP TABLE IF EXISTS #InputRows;
    DROP TABLE IF EXISTS #MatchedCodes;
    DROP TABLE IF EXISTS #NewCodesToScrape;
END
GO
