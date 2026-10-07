-- =============================================
-- Migration: 20261006_Add_HasUnassignedCodes_To_USP_GetProductList_AI.sql
-- Description: Adds @HasUnassignedCodes parameter to USP_GetProductList_AI
--              to allow filtering products that have unassigned codes in M_Code (Batch_No IS NULL)
-- =============================================

CREATE OR ALTER PROCEDURE USP_GetProductList_AI
    @Comp_ID            NVARCHAR(50) = '',
    @PageNumber         INT = 1,
    @PageSize           INT = 10,
    @SearchQuery        NVARCHAR(200) = '',
    @datePreset         NVARCHAR(50) = '',
    @FromDate           DATETIME = NULL,
    @ToDate             DATETIME = NULL,
    @Status             NVARCHAR(50) = '',
    @HasUnassignedCodes BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ── Date Filtering Logic Map ─────────────────────────────────────────────
    DECLARE @CalculatedFromDate DATETIME = NULL;
    DECLARE @CalculatedToDate DATETIME = NULL;

    DECLARE @Win NVARCHAR(50) = LOWER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    
    IF @Win = 'today'
    BEGIN
        SET @CalculatedFromDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @Win = 'lastday'
    BEGIN
        SET @CalculatedFromDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        SET @CalculatedToDate = DATEADD(SECOND, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF @Win = 'week' OR @Win = 'this week'
    BEGIN
        SET @CalculatedFromDate = DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @Win = 'lastweek'
    BEGIN
        SET @CalculatedFromDate = DATEADD(week, DATEDIFF(week, 7, GETDATE()), 0);
        SET @CalculatedToDate = DATEADD(second, -1, DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0));
    END
    ELSE IF @Win = 'month' OR @Win = 'this month'
    BEGIN
        SET @CalculatedFromDate = DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @Win = 'lastmonth'
    BEGIN
        SET @CalculatedFromDate = DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0);
        SET @CalculatedToDate = DATEADD(second, -1, DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0));
    END
    ELSE IF @Win = 'quarter'
    BEGIN
        SET @CalculatedFromDate = DATEADD(quarter, DATEDIFF(quarter, 0, GETDATE()), 0);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @Win = 'year'
    BEGIN
        SET @CalculatedFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @CalculatedToDate = GETDATE();
    END
    ELSE IF @Win = 'lastyear'
    BEGIN
        SET @CalculatedFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
        SET @CalculatedToDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
    END
    ELSE IF @Win = 'custom' OR @FromDate IS NOT NULL OR @ToDate IS NOT NULL
    BEGIN
        SET @CalculatedFromDate = @FromDate;
        SET @CalculatedToDate = ISNULL(DATEADD(second, -1, DATEADD(day, 1, @ToDate)), GETDATE()); 
    END

    -- ── Main Query ──────────────────────────────────────────────────────────
    SELECT
        COUNT(1) OVER()                                       AS TotalRecords,
        ROW_NUMBER() OVER (ORDER BY pr.Pro_Entry_Date DESC)   AS SNo,
        pr.Pro_ID,
        pr.Pro_Name,
        ISNULL(
            CONVERT(NVARCHAR, ml.Label_Name) + ' ( ' + ml.Label_Size + ' )',
            'N/A'
        )                                                     AS LabelName,
        ISNULL(ml.Label_Prise, 0)                             AS RatePerLabel,
        CASE
            WHEN ISNULL(pr.Pro_Desc, '') = '' THEN '---'
            ELSE pr.Pro_Desc
        END                                                   AS ProDesc,
        '/assets/Product/comp-'
            + SUBSTRING(pr.Comp_ID, 6, 4)
            + '/' + pr.Pro_ID
            + '/' + pr.Pro_ID + '.mp3'                        AS SoundPath,
        CASE
            WHEN pr.Doc_Flag = 1 AND pr.Sound_Flag = 1 THEN 'Verified'
            ELSE 'Pending'
        END                                                   AS Status,
        pr.Pro_Entry_Date,
        pr.Label_Code,
        ISNULL(pr.BatchSize, 0)                               AS BatchSize,
        ISNULL(pr.Dispatch_Location, '')                      AS Dispatch_Location,
        '/assets/Product/comp-' 
            + SUBSTRING(pr.Comp_ID, 6, 4) 
            + '/' + pr.Pro_ID                                 AS ImgPath,
        ISNULL(latest_batch.Batch_No, '')                     AS Batch_No,
        ISNULL(CONVERT(VARCHAR, latest_batch.Mfd_Date, 105), '') AS Mfd_Date,
        ISNULL(CONVERT(VARCHAR, latest_batch.Exp_Date, 105), '') AS Exp_Date,
        sub.Subscribe_Id,
        sub.Service_ID,
        sub.IsActive,
        sub.DateFrom,
        sub.DateTo,
        sub.PlanPeriod
    FROM   Pro_Reg pr
    LEFT JOIN M_Label ml ON pr.Label_Code = ml.Label_Code
    OUTER APPLY (
        SELECT TOP 1 t.Batch_No, t.Mfd_Date, t.Exp_Date
        FROM T_Pro t
        WHERE t.Pro_ID = pr.Pro_ID
        ORDER BY t.Entry_Date DESC
    ) AS latest_batch
    OUTER APPLY (
        SELECT TOP 1 
            ss.Subscribe_Id, 
            ss.Service_ID, 
            ss.IsActive, 
            ss.DateFrom, 
            ss.DateTo, 
            ss.PlanMasterPeriod AS PlanPeriod
        FROM M_ServiceSubscription ss
        WHERE ss.Pro_ID = pr.Pro_ID
          AND (ss.IsDelete = 0 OR ss.IsDelete IS NULL)
        ORDER BY ss.EntryDate ASC
    ) AS sub
    WHERE
        ('' = @Comp_ID OR pr.Comp_ID = @Comp_ID)
        AND (
            @SearchQuery = '' 
            OR pr.Pro_Name LIKE '%' + @SearchQuery + '%' 
            OR pr.Pro_ID LIKE '%' + @SearchQuery + '%'
            OR pr.Pro_Desc LIKE '%' + @SearchQuery + '%'
        )
        AND (
            @CalculatedFromDate IS NULL 
            OR pr.Pro_Entry_Date >= @CalculatedFromDate
        )
        AND (
            @CalculatedToDate IS NULL 
            OR pr.Pro_Entry_Date <= @CalculatedToDate
        )
        AND (
            ISNULL(@Status, '') = ''
            OR (@Status = 'Verified' AND pr.Doc_Flag = 1 AND pr.Sound_Flag = 1)
            OR (@Status = 'Pending' AND (ISNULL(pr.Doc_Flag, 0) != 1 OR ISNULL(pr.Sound_Flag, 0) != 1))
        )
        AND (
            @HasUnassignedCodes IS NULL
            OR (@HasUnassignedCodes = 1 AND (
                CASE WHEN @Comp_ID = 'Comp-1693' THEN
                    CASE WHEN EXISTS (
                        SELECT 1 FROM M_Code_PFL mc WITH (NOLOCK)
                        WHERE mc.Pro_ID = pr.Pro_ID
                          AND (mc.Batch_No IS NULL OR mc.Batch_No = '')
                          AND mc.Print_Status = 1
                          AND ISNULL(mc.ScrapeFlag, 0) = 0
                          AND mc.DispatchFlag = 1
                          AND mc.ReceiveFlag = 1
                    ) THEN 1 ELSE 0 END
                ELSE
                    CASE WHEN EXISTS (
                        SELECT 1 FROM M_Code mc WITH (NOLOCK)
                        WHERE mc.Pro_ID = pr.Pro_ID
                          AND (mc.Batch_No IS NULL OR mc.Batch_No = '')
                          AND mc.Print_Status = 1
                          AND ISNULL(mc.ScrapeFlag, 0) = 0
                          AND mc.DispatchFlag = 1
                          AND mc.ReceiveFlag = 1
                    ) THEN 1 ELSE 0 END
                END
            ) = 1)
        )
    ORDER BY pr.Pro_Entry_Date DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS 
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
