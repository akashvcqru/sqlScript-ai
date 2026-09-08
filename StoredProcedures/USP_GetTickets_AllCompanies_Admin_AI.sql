CREATE OR ALTER PROCEDURE [dbo].[USP_GetTickets_AllCompanies_Admin_AI]
    @Search NVARCHAR(100) = NULL,
    @DatePreset NVARCHAR(50) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Offset INT = 0,
    @Limit INT = 10,
    @IsExport BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Explicit Date Range overrides DatePreset
    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
        BEGIN
            SET @DatePreset = UPPER(LTRIM(RTRIM(@DatePreset)));
            
            IF @DatePreset = 'TODAY'
            BEGIN
                SET @StartDate = CAST(GETDATE() AS DATE);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTDAY'
            BEGIN
                SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
                SET @EndDate   = CAST(GETDATE() AS DATE);
            END
            ELSE IF @DatePreset = 'WEEK'
            BEGIN
                SET DATEFIRST 1;
                SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTWEEK'
            BEGIN
                SET DATEFIRST 1;
                SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'MONTH'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTMONTH'
            BEGIN
                SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'QUARTER'
            BEGIN
                SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'YEAR'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTYEAR'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
                SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            END
            ELSE IF @DatePreset = 'ALL' OR @DatePreset = 'NULL'
            BEGIN
                SET @StartDate = NULL;
                SET @EndDate   = NULL;
            END
        END
    END

    -- Search Pattern Normalization
    DECLARE @SearchPattern NVARCHAR(252) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
    BEGIN
        SET @SearchPattern = '%' + LTRIM(RTRIM(@Search)) + '%';
    END

    -- Query for total count (only if not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM Tickets t WITH (NOLOCK)
        LEFT JOIN M_Consumer mc WITH (NOLOCK) ON mc.M_Consumerid = TRY_CAST(t.M_Consumerid AS INT)
        LEFT JOIN Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = t.Comp_id
        WHERE (@StartDate IS NULL OR t.CreatedAt >= @StartDate)
          AND (@EndDate IS NULL OR t.CreatedAt < @EndDate)
          AND (@SearchPattern IS NULL OR 
               CAST(t.TicketId AS NVARCHAR(50)) LIKE @SearchPattern OR
               t.Comp_id LIKE @SearchPattern OR
               cr.Comp_Name LIKE @SearchPattern OR
               mc.MobileNo LIKE @SearchPattern OR
               mc.ConsumerName LIKE @SearchPattern OR
               t.Description LIKE @SearchPattern OR
               t.Category LIKE @SearchPattern OR
               t.Status LIKE @SearchPattern);
    END

    -- Query for ticket list
    SELECT  
        t.TicketId,  
        t.Description,  
        mc.MobileNo,  
        t.CreatedAt,  
        t.Status,  
        t.Category,
        t.Comp_id AS CompId,
        cr.Comp_Name AS CompName,
        img.ImagePaths
    FROM Tickets t WITH (NOLOCK)
    LEFT JOIN M_Consumer mc WITH (NOLOCK) ON mc.M_Consumerid = TRY_CAST(t.M_Consumerid AS INT)
    LEFT JOIN Comp_Reg cr WITH (NOLOCK) ON cr.Comp_ID = t.Comp_id
    OUTER APPLY (
        SELECT STRING_AGG(i.ImagePath, ',') AS ImagePaths
        FROM TicketImages i WITH (NOLOCK)
        WHERE i.TicketId = t.TicketId
    ) img
    WHERE (@StartDate IS NULL OR t.CreatedAt >= @StartDate)
      AND (@EndDate IS NULL OR t.CreatedAt < @EndDate)
      AND (@SearchPattern IS NULL OR 
           CAST(t.TicketId AS NVARCHAR(50)) LIKE @SearchPattern OR
           t.Comp_id LIKE @SearchPattern OR
           cr.Comp_Name LIKE @SearchPattern OR
           mc.MobileNo LIKE @SearchPattern OR
           mc.ConsumerName LIKE @SearchPattern OR
           t.Description LIKE @SearchPattern OR
           t.Category LIKE @SearchPattern OR
           t.Status LIKE @SearchPattern)
    ORDER BY t.CreatedAt DESC, t.TicketId DESC
    OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY;
END
GO
