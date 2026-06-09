-- =============================================
-- SQL Script: Create Stored Procedure for Retrieving Mahindra Mstar Uploaded Sheet
-- =============================================

IF OBJECT_ID('USP_GetMahindraMstarSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetMahindraMstarSheet_AI
GO

CREATE PROCEDURE USP_GetMahindraMstarSheet_AI
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

    -- CTE for filtered search data (DealerType IS NULL specifies Mstar records)
    ;WITH FilteredRecords AS (
        SELECT 
            DealerCode,
            DealerTechnicianId,
            D_Status AS Status,
            D_Name AS DealerName,
            City,
            Mobile_Num AS MobileNo,
            Zone,
            D_State AS State,
            Created_Date,
            Comp_id
        FROM m_dealermaster WITH (NOLOCK)
        WHERE Comp_id = @Comp_id AND DealerType IS NULL
          AND (@Search IS NULL OR @Search = ''
               OR D_Name LIKE '%' + @Search + '%'
               OR DealerCode LIKE '%' + @Search + '%'
               OR DealerTechnicianId LIKE '%' + @Search + '%'
               OR Mobile_Num LIKE '%' + @Search + '%')
    )
    SELECT * INTO #TempResults FROM FilteredRecords;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #TempResults;

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #TempResults ORDER BY Created_Date DESC;
    END
    ELSE
    BEGIN
        SELECT * FROM #TempResults 
        ORDER BY Created_Date DESC
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
