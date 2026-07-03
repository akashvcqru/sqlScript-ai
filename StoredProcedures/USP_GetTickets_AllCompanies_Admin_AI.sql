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

    -- Query for total count (only if not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(DISTINCT t.TicketId) AS TotalRecords
        FROM Tickets t  
        LEFT JOIN Comp_Reg cr ON cr.Comp_ID = t.Comp_id
        WHERE (@Search IS NULL OR t.Comp_id LIKE '%' + @Search + '%' OR cr.Comp_Name LIKE '%' + @Search + '%')
          AND (@StartDate IS NULL OR t.CreatedAt >= @StartDate)
          AND (@EndDate IS NULL OR t.CreatedAt < @EndDate);
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
        STRING_AGG(i.ImagePath, ',') AS ImagePaths
    FROM Tickets t  
    LEFT JOIN TicketImages i ON t.TicketId = i.TicketId  
    LEFT JOIN M_Consumer mc ON mc.M_Consumerid = TRY_CAST(t.M_Consumerid AS INT)
    LEFT JOIN Comp_Reg cr ON cr.Comp_ID = t.Comp_id
    WHERE (@Search IS NULL OR t.Comp_id LIKE '%' + @Search + '%' OR cr.Comp_Name LIKE '%' + @Search + '%')
      AND (@StartDate IS NULL OR t.CreatedAt >= @StartDate)
      AND (@EndDate IS NULL OR t.CreatedAt < @EndDate)
    GROUP BY 
        t.TicketId,  
        t.M_Consumerid,  
        t.Description,  
        t.CreatedAt,  
        t.Status,  
        t.Category,
        t.Comp_id,
        cr.Comp_Name,
        mc.MobileNo
    ORDER BY t.CreatedAt DESC
    OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY;
END
GO
