SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_ScrapCodes_ExcelUpload_AI]
    @Comp_ID VARCHAR(50) = NULL,
    @ScrapedBy NVARCHAR(100) = NULL,
    @FileName NVARCHAR(255) = NULL,
    @JsonData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalUploaded INT = 0;
    DECLARE @ScrappedCount INT = 0;
    DECLARE @AlreadyScrappedCount INT = 0;
    DECLARE @NotFoundCount INT = 0;

    -- Temp table for input data
    DROP TABLE IF EXISTS #InputCodes;
    CREATE TABLE #InputCodes (
        RowId INT IDENTITY(1,1) PRIMARY KEY,
        Code1 NUMERIC(5,0),
        Code2 NUMERIC(8,0),
        CompleteCode NVARCHAR(50)
    );

    BEGIN TRY
        INSERT INTO #InputCodes (Code1, Code2, CompleteCode)
        SELECT 
            TRY_CAST(Code1 AS NUMERIC(5,0)),
            TRY_CAST(Code2 AS NUMERIC(8,0)),
            CompleteCode
        FROM OPENJSON(@JsonData) WITH (
            Code1 NVARCHAR(20) '$.Code1',
            Code2 NVARCHAR(20) '$.Code2',
            CompleteCode NVARCHAR(50) '$.CompleteCode'
        )
        WHERE TRY_CAST(Code1 AS NUMERIC(5,0)) IS NOT NULL
          AND TRY_CAST(Code2 AS NUMERIC(8,0)) IS NOT NULL;

        SELECT @TotalUploaded = COUNT(1) FROM #InputCodes;

        IF @TotalUploaded = 0
        BEGIN
            SELECT 
                0 AS Success,
                'No valid codes found in payload.' AS Message,
                0 AS TotalUploaded,
                0 AS ScrappedCount,
                0 AS AlreadyScrappedCount,
                0 AS NotFoundCount;
            RETURN;
        END

        -- Temp table to capture existing code status in M_Code
        DROP TABLE IF EXISTS #CodesToUpdate;
        CREATE TABLE #CodesToUpdate (
            Code1 NUMERIC(5,0),
            Code2 NUMERIC(8,0),
            ExistingScrapeFlag TINYINT
        );

        INSERT INTO #CodesToUpdate (Code1, Code2, ExistingScrapeFlag)
        SELECT 
            i.Code1, 
            i.Code2, 
            m.ScrapeFlag
        FROM #InputCodes i
        INNER JOIN M_Code m WITH (NOLOCK) ON m.Code1 = i.Code1 AND m.Code2 = i.Code2;

        -- 1. Perform update on M_Code (setting ScrapeFlag = 1 and Block_Code_Date = GETDATE())
        UPDATE m
        SET m.ScrapeFlag = 1,
            m.Block_Code_Date = GETDATE()
        FROM M_Code m
        INNER JOIN #CodesToUpdate u
            ON m.Code1 = u.Code1
           AND m.Code2 = u.Code2
        WHERE ISNULL(m.ScrapeFlag, 0) <> 1;

        SET @ScrappedCount = @@ROWCOUNT;

        SELECT @AlreadyScrappedCount = COUNT(1) 
        FROM #CodesToUpdate 
        WHERE ExistingScrapeFlag = 1;

        SELECT @NotFoundCount = COUNT(1)
        FROM #InputCodes i
        WHERE NOT EXISTS (
            SELECT 1 FROM #CodesToUpdate u 
            WHERE u.Code1 = i.Code1 AND u.Code2 = i.Code2
        );

        SELECT 
            1 AS Success,
            CONCAT('Processing completed: ', @ScrappedCount, ' newly scrapped, ', @AlreadyScrappedCount, ' previously scrapped, ', @NotFoundCount, ' not found.') AS Message,
            @TotalUploaded AS TotalUploaded,
            @ScrappedCount AS ScrappedCount,
            @AlreadyScrappedCount AS AlreadyScrappedCount,
            @NotFoundCount AS NotFoundCount;

        DROP TABLE IF EXISTS #InputCodes;
        DROP TABLE IF EXISTS #CodesToUpdate;
    END TRY
    BEGIN CATCH
        DROP TABLE IF EXISTS #InputCodes;
        DROP TABLE IF EXISTS #CodesToUpdate;

        SELECT 
            0 AS Success,
            ERROR_MESSAGE() AS Message,
            0 AS TotalUploaded,
            0 AS ScrappedCount,
            0 AS AlreadyScrappedCount,
            0 AS NotFoundCount;
    END CATCH
END
GO
