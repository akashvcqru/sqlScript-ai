    SET ANSI_NULLS ON
    GO
    SET QUOTED_IDENTIFIER ON
    GO
    -- =============================================
    -- Author:      AI
    -- Create date: 2026-04-02
    -- Description: Get state-wise scanning report for a specific company with consumer demographics
    -- =============================================
    CREATE OR ALTER PROCEDURE [dbo].[USP_GetStateWiseReport_AI]
        @Comp_ID NVARCHAR(50),
        @datePreset NVARCHAR(20) = 'week',
        @FromDate DATETIME = NULL,
        @ToDate DATETIME = NULL,
        @PageNumber INT = 1,
        @PageSize INT = 10,
        @IsExport BIT = 0
    AS
    BEGIN
        SET NOCOUNT ON;
        SET @IsExport = ISNULL(@IsExport, 0);

        DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
        SET @finalToDate = GETDATE()

        IF @datePreset = 'all'
        BEGIN
            SET @finalFromDate = NULL
            SET @finalToDate = NULL
        END
        ELSE IF @datePreset = 'custom'
        BEGIN
            SET @finalFromDate = @FromDate
            SET @finalToDate = @ToDate
        END
        ELSE
        BEGIN
            IF @datePreset IS NULL OR @datePreset = '' SET @datePreset = 'week'
            
            DECLARE @today DATE = CAST(GETDATE() AS DATE)

            IF @datePreset = 'today'
            BEGIN
                SET @finalFromDate = @today
                SET @finalToDate = GETDATE()
            END
            ELSE IF @datePreset = 'week'
            BEGIN
                SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
                SET @finalToDate = GETDATE()
            END
            ELSE IF @datePreset = 'lastweek'
            BEGIN
                DECLARE @thisMonday DATE = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
                SET @finalFromDate = DATEADD(DAY, -7, @thisMonday)
                SET @finalToDate = DATEADD(SECOND, -1, CAST(@thisMonday AS DATETIME))
            END
            ELSE IF @datePreset = 'month'
            BEGIN
                SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
                SET @finalToDate = GETDATE()
            END
            ELSE IF @datePreset = 'lastmonth'
            BEGIN
                SET @finalFromDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
                SET @finalToDate = DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME))
            END
            ELSE IF @datePreset = 'quarter'
            BEGIN
                SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0)
                SET @finalToDate = GETDATE()
            END
            ELSE
            BEGIN
                SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
                SET @finalToDate = GETDATE()
            END
        END

        IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;

        SELECT a.* 
        INTO #tempM_Code 
        FROM M_Code a 
        INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
        WHERE b.Comp_ID = @Comp_ID;

        -- Get unique locations from scans and consumers
        ;WITH RawData AS (
            SELECT 
                pe.State,
                pe.City,
                mc.PinCode AS PostCode,
                pe.MobileNo,
                mc.IsActive,
                mc.Entry_Date AS ConsumerEntryDate,
                pe.Is_Success,
                pe.Enq_Date,
                m.Code1 AS CodeExists
            FROM Pro_Enq pe
            LEFT JOIN M_Consumer mc ON pe.MobileNo = mc.MobileNo
            LEFT JOIN #tempM_Code m ON pe.Received_Code1 = m.Code1 AND pe.Received_Code2 = m.Code2
            WHERE pe.Comp_ID = @Comp_ID
            AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
            AND (@finalToDate IS NULL OR pe.Enq_Date < DATEADD(DAY, 1, @finalToDate))
            AND (ISNULL(pe.State, '') <> '' OR ISNULL(pe.City, '') <> '' OR ISNULL(mc.PinCode, '') <> '')
        ),
        LocationGroups AS (
            SELECT 
                State,
                City,
                PostCode,
                COUNT(DISTINCT CASE WHEN IsActive = 1 THEN MobileNo END) AS ActiveConsumers,
                COUNT(DISTINCT CASE WHEN ConsumerEntryDate >= @finalFromDate AND ConsumerEntryDate < DATEADD(DAY, 1, @finalToDate) THEN MobileNo END) AS NewConsumers,
                COUNT(DISTINCT CASE WHEN ConsumerEntryDate < @finalFromDate THEN MobileNo END) AS ReturningConsumers,
                COUNT(*) AS TotalScans,
                SUM(CASE WHEN Is_Success = 1 THEN 1 ELSE 0 END) AS GenuineScans,
                SUM(CASE WHEN Is_Success = 0 AND CodeExists IS NOT NULL THEN 1 ELSE 0 END) AS DuplicateScans,
                SUM(CASE WHEN Is_Success = 0 AND CodeExists IS NULL THEN 1 ELSE 0 END) AS CounterfeitScans,
                CAST(CAST(COUNT(*) AS DECIMAL(18,2)) / NULLIF(COUNT(DISTINCT MobileNo), 0) AS DECIMAL(18,2)) AS AvgScansPerConsumer
            FROM RawData
            GROUP BY State, City, PostCode
        )
        SELECT 
            ROW_NUMBER() OVER (ORDER BY State, City, PostCode) AS SNo,
            *,
            COUNT(*) OVER() AS TotalRecords
        FROM LocationGroups
        ORDER BY State, City, PostCode
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);
    END
    GO
