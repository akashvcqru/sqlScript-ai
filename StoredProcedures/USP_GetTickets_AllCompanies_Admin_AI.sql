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
    DECLARE @Today     DATETIME = CAST(GETDATE() AS DATE);
    DECLARE @Now       DATETIME = GETDATE();

    -- Parse and handle DatePreset if provided
    IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
    BEGIN
        SET @DatePreset = LOWER(LTRIM(RTRIM(@DatePreset)));
        
        IF @DatePreset = 'today' OR @DatePreset = 'day'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'yesterday'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            -- Yesterday end of day (23:59:59.997 due to 3.33ms datetime rounding)
            SET @EndDate   = DATEADD(MILLISECOND, -3, @Today);
        END
        ELSE IF @DatePreset = 'week' OR @DatePreset = 'last 7 days'
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, @Today);
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'last 30 days'
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, @Today);
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'month' OR @DatePreset = 'this month'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = @Now;
        END
        ELSE IF @DatePreset = 'last month'
        BEGIN
            DECLARE @LastMonthStart DATETIME = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1));
            SET @StartDate = @LastMonthStart;
            -- Last month end of day (one tick before first day of current month)
            SET @EndDate   = DATEADD(MILLISECOND, -3, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1));
        END
    END

    -- Explicit Date Range overrides DatePreset
    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END

    -- Query for total count (only if not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(DISTINCT t.TicketId) AS TotalRecords
        FROM Tickets t  
        LEFT JOIN Comp_Reg cr ON cr.Comp_ID = t.Comp_id
        WHERE (@Search IS NULL OR t.Comp_id LIKE '%' + @Search + '%' OR cr.Comp_Name LIKE '%' + @Search + '%')
          AND (@StartDate IS NULL OR t.CreatedAt >= @StartDate)
          AND (@EndDate IS NULL OR t.CreatedAt <= @EndDate);
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
      AND (@EndDate IS NULL OR t.CreatedAt <= @EndDate)
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
