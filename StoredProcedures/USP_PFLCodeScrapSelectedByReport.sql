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

    -- 1. Parse SeriesSerial and find matching codes from M_Code_PFL
    SELECT mc.Code1, mc.Code2, temp.SerialCode
    INTO #TempCodes
    FROM M_Code_PFL mc
    INNER JOIN (
        SELECT 
            TRIM(SUBSTRING(val, 1, CHARINDEX('-', val) - 1)) AS ProId,
            TRIM(SUBSTRING(val, CHARINDEX('-', val) + 1, CHARINDEX('-', val, CHARINDEX('-', val) + 1) - CHARINDEX('-', val) - 1)) AS SeriesOrder,
            TRIM(SUBSTRING(val, CHARINDEX('-', val, CHARINDEX('-', val) + 1) + 1, LEN(val))) AS SeriesSerial,
            val AS SerialCode
        FROM (
            SELECT TRIM(value) AS val
            FROM STRING_SPLIT(@SeriesSerial, ',')
            WHERE TRIM(value) LIKE '%-%-%'
        ) t
    ) temp ON mc.Pro_ID = temp.ProId 
          AND mc.Series_Order = TRY_CAST(temp.SeriesOrder AS NUMERIC(10,0))
          AND mc.Series_Serial = TRY_CAST(temp.SeriesSerial AS NUMERIC(4,0));

    -- 2. Update ScrapeFlag in M_Code_PFL
    UPDATE mc
    SET mc.ScrapeFlag = 1
    FROM M_Code_PFL mc
    INNER JOIN #TempCodes tc ON mc.Code1 = tc.Code1 AND mc.Code2 = tc.Code2;

    DECLARE @AffectedRows INT = @@ROWCOUNT;

    -- 3. Update existing records in tblScrapdatapfl
    UPDATE s
    SET s.scrapeCodeDate = GETDATE()
    FROM tblScrapdatapfl s
    INNER JOIN #TempCodes tc ON s.Code1 = tc.Code1 AND s.Code2 = tc.Code2;

    -- 4. Insert missing records in tblScrapdatapfl
    INSERT INTO tblScrapdatapfl (Code1, Code2, SerialCode, CompanyId, scrapeCodeDate)
    SELECT tc.Code1, tc.Code2, tc.SerialCode, ISNULL(@CompId, 'Comp-1693'), GETDATE()
    FROM #TempCodes tc
    WHERE NOT EXISTS (
        SELECT 1 
        FROM tblScrapdatapfl s 
        WHERE s.Code1 = tc.Code1 AND s.Code2 = tc.Code2
    );

    -- 5. Return count of affected rows in M_Code_PFL
    SELECT @AffectedRows AS AffectedRows;

    DROP TABLE IF EXISTS #TempCodes;
END
GO
