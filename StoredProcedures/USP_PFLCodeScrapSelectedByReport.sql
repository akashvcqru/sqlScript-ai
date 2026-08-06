USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_PFLCodeScrapSelectedByReport]
    @SeriesSerial NVARCHAR(MAX),
    @CompId NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Parse SeriesSerial into a typed temp table
    DROP TABLE IF EXISTS #ParsedInput;
    CREATE TABLE #ParsedInput (
        ProId NVARCHAR(50),
        SeriesOrder NUMERIC(10,0),
        SeriesSerial NUMERIC(4,0),
        SerialCode NVARCHAR(100)
    );

    INSERT INTO #ParsedInput (ProId, SeriesOrder, SeriesSerial, SerialCode)
    SELECT 
        CAST(TRIM(SUBSTRING(val, 1, CHARINDEX('-', val) - 1)) AS NVARCHAR(50)) AS ProId,
        TRY_CAST(TRIM(SUBSTRING(val, CHARINDEX('-', val) + 1, CHARINDEX('-', val, CHARINDEX('-', val) + 1) - CHARINDEX('-', val) - 1)) AS NUMERIC(10,0)) AS SeriesOrder,
        TRY_CAST(TRIM(SUBSTRING(val, CHARINDEX('-', val, CHARINDEX('-', val) + 1) + 1, LEN(val))) AS NUMERIC(4,0)) AS SeriesSerial,
        val AS SerialCode
    FROM (
        SELECT TRIM(value) AS val
        FROM STRING_SPLIT(@SeriesSerial, ',')
        WHERE TRIM(value) LIKE '%-%-%'
    ) t;

    -- Create index on the parsed input to assist the optimizer
    CREATE CLUSTERED INDEX IX_ParsedInput_Lookup ON #ParsedInput (ProId, SeriesOrder, SeriesSerial);

    -- 2. Find matching codes from M_Code_PFL
    SELECT mc.Code1, mc.Code2, temp.SerialCode
    INTO #TempCodes
    FROM M_Code_PFL mc
    INNER JOIN #ParsedInput temp 
        ON mc.Pro_ID = temp.ProId 
       AND mc.Series_Order = temp.SeriesOrder
       AND mc.Series_Serial = temp.SeriesSerial;

    -- 3. Update ScrapeFlag in M_Code_PFL
    UPDATE mc
    SET mc.ScrapeFlag = 1
    FROM M_Code_PFL mc
    INNER JOIN #TempCodes tc ON mc.Code1 = tc.Code1 AND mc.Code2 = tc.Code2;

    DECLARE @AffectedRows INT = @@ROWCOUNT;

    -- 4. Update existing records in tblScrapdatapfl
    UPDATE s
    SET s.scrapeCodeDate = GETDATE()
    FROM tblScrapdatapfl s
    INNER JOIN #TempCodes tc ON s.Code1 = tc.Code1 AND s.Code2 = tc.Code2;

    -- 5. Insert missing records in tblScrapdatapfl
    INSERT INTO tblScrapdatapfl (Code1, Code2, SerialCode, CompanyId, scrapeCodeDate)
    SELECT tc.Code1, tc.Code2, tc.SerialCode, ISNULL(@CompId, 'Comp-1693'), GETDATE()
    FROM #TempCodes tc
    WHERE NOT EXISTS (
        SELECT 1 
        FROM tblScrapdatapfl s 
        WHERE s.Code1 = tc.Code1 AND s.Code2 = tc.Code2
    );

    -- 6. Return count of affected rows in M_Code_PFL
    SELECT @AffectedRows AS AffectedRows;

    DROP TABLE IF EXISTS #ParsedInput;
    DROP TABLE IF EXISTS #TempCodes;
END
GO
