SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GenerateAndSaveCodes_Unified_AI]
    @TotalQ INT
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE to generate numbers
    ;WITH Numbers AS (
        SELECT TOP (CAST(@TotalQ * 1.5 AS INT)) -- Generate 50% extra to account for duplicates/existing codes
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    ),
    -- CTE to generate random codes
    Generated AS (
        SELECT DISTINCT
            CAST(ABS(CHECKSUM(NEWID())) % 90000 + 10000 AS NUMERIC(5,0))  AS Code1,  -- random 5-digit numeric
            CAST(ABS(CHECKSUM(NEWID())) % 90000000 + 10000000 AS NUMERIC(8,0)) AS Code2  -- random 8-digit numeric
        FROM Numbers
    )
    -- Insert into M_Code
    INSERT INTO M_Code (Code1, Code2, Gen_By, Gen_Date, QRCodeStatus, Use_Count, ScrapeFlag)
    SELECT TOP (@TotalQ)
           g.Code1, g.Code2, 'Admin', GETDATE(), 0, NULL, NULL
    FROM Generated g
    WHERE 
      -- Ensure no leading zero issues (though % 90000 + 10000 handles it for 5-digit)
      g.Code1 >= 10000 AND g.Code1 <= 99999
      AND g.Code2 >= 10000000 AND g.Code2 <= 99999999
      -- Prevention of duplicates in M_Code
      AND NOT EXISTS (
            SELECT 1
            FROM M_Code m
            WHERE m.Code1 = g.Code1
              AND m.Code2 = g.Code2
      )
      -- Prevention of duplicates in M_Code_PFL
      AND NOT EXISTS (
            SELECT 1
            FROM M_Code_PFL mp
            WHERE mp.Code1 = g.Code1
              AND mp.Code2 = g.Code2
      )
    ORDER BY NEWID(); -- Shuffle

    -- Return the number of rows inserted
    SELECT @@ROWCOUNT AS InsertedCount;
END
GO
