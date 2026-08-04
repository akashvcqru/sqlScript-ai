USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[USP_PFLCodeScrapSelectedByReport]
    @SeriesSerial NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE mc
    SET mc.ScrapeFlag = 1
    FROM M_Code_PFL mc
    INNER JOIN (
        SELECT 
            TRIM(SUBSTRING(val, 1, CHARINDEX('-', val) - 1)) AS ProId,
            TRIM(SUBSTRING(val, CHARINDEX('-', val) + 1, CHARINDEX('-', val, CHARINDEX('-', val) + 1) - CHARINDEX('-', val) - 1)) AS SeriesOrder,
            TRIM(SUBSTRING(val, CHARINDEX('-', val, CHARINDEX('-', val) + 1) + 1, LEN(val))) AS SeriesSerial
        FROM (
            SELECT TRIM(value) AS val
            FROM STRING_SPLIT(@SeriesSerial, ',')
            WHERE TRIM(value) LIKE '%-%-%'
        ) t
    ) temp ON mc.Pro_ID = temp.ProId 
          AND mc.Series_Order = TRY_CAST(temp.SeriesOrder AS NUMERIC(10,0))
          AND mc.Series_Serial = TRY_CAST(temp.SeriesSerial AS NUMERIC(4,0));

    SELECT @@ROWCOUNT AS AffectedRows;
END
GO
