-- =============================================
-- SQL Script: Create Stored Procedure for Retrieving Mahindra Code Status Uploaded Sheet
-- =============================================

IF OBJECT_ID('USP_GetMahindraCodeStatusSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetMahindraCodeStatusSheet_AI
GO

CREATE PROCEDURE USP_GetMahindraCodeStatusSheet_AI
    @Comp_id    NVARCHAR(255),
    @Search     NVARCHAR(255) = NULL,
    @Page       INT = 1,
    @Limit      INT = 10,
    @IsExport   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Defaults
    IF ISNULL(@Page, 0) <= 0 SET @Page = 1;
    IF ISNULL(@Limit, 0) <= 0 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    DECLARE @CompIdWithPrefix NVARCHAR(255) = CASE WHEN @Comp_id LIKE 'Comp-%' THEN @Comp_id ELSE 'Comp-' + @Comp_id END;
    DECLARE @CompIdWithoutPrefix NVARCHAR(255) = REPLACE(@Comp_id, 'Comp-', '');

    -- CTE for filtered search data
    ;WITH FilteredStatus AS (
        SELECT DISTINCT
            ts.Complete_code,
            ts.Transaction_Status,
            ts.Transaction_date
        FROM Transaction_status ts WITH (NOLOCK)
        INNER JOIN ConsumerPointsCashDetails pc WITH (NOLOCK) ON CAST(ts.Complete_code AS NVARCHAR(13)) = CONCAT(pc.Code1, pc.Code2)
        WHERE (pc.Comp_Id = @CompIdWithPrefix OR pc.Comp_Id = @CompIdWithoutPrefix)
          AND (@Search IS NULL OR @Search = ''
               OR CAST(ts.Complete_code AS NVARCHAR(13)) LIKE '%' + @Search + '%'
               OR ts.Transaction_Status LIKE '%' + @Search + '%')
    )
    SELECT * INTO #TempResults FROM FilteredStatus;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #TempResults;

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #TempResults ORDER BY Transaction_date DESC;
    END
    ELSE
    BEGIN
        SELECT * FROM #TempResults 
        ORDER BY Transaction_date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata output
        SELECT 
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CEILING(CAST(@TotalRecords AS FLOAT) / @Limit) AS TotalPages;
    END

    DROP TABLE #TempResults;
END
GO
