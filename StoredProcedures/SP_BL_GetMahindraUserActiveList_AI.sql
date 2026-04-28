/****** Object:  StoredProcedure [dbo].[SP_BL_GetMahindraUserActiveList_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_BL_GetMahindraUserActiveList_AI]
(
    @Comp_Id VARCHAR(15),
    @DealerType  VARCHAR(20) = NULL, -- TechMaster / Mstar
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
)
AS
BEGIN
SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Pagination Defaults
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Build Combined Data ONCE
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#CombinedDealers') IS NOT NULL
        DROP TABLE #CombinedDealers;

    SELECT
        DealerTechnicianId,
        DealerCode,
        D_Status,
        'Mstar' AS DealerType
    INTO #CombinedDealers
    FROM m_dealermaster_mahindra_emp WITH (NOLOCK)
    WHERE Comp_id = @Comp_Id

    UNION ALL

    SELECT
        DealerTechnicianId,
        DealerCode,
        D_Status,
        'TechMaster' AS DealerType
    FROM m_dealermaster WITH (NOLOCK)
    WHERE Comp_id = @Comp_Id
      AND DealerType IS NULL;

    ---------------------------------------------------------
    -- RESULT SET 1 : PAGINATED + FILTERED DATA
    ---------------------------------------------------------
    SELECT
        DealerTechnicianId,
        DealerCode,
        D_Status,
        DealerType
    FROM #CombinedDealers
    WHERE
        @DealerType IS NULL
        OR DealerType = @DealerType
    ORDER BY DealerTechnicianId
    OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
    FETCH NEXT CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END ROWS ONLY;

    ---------------------------------------------------------
    -- RESULT SET 2 : PAGINATION META (FILTER-AWARE)
    ---------------------------------------------------------
    IF (@IsExport = 0)
    BEGIN
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #CombinedDealers
        WHERE
            @DealerType IS NULL
            OR DealerType = @DealerType;

        ---------------------------------------------------------
        -- Cleanup
        ---------------------------------------------------------
        DROP TABLE IF EXISTS #CombinedDealers;
    END
END
GO
