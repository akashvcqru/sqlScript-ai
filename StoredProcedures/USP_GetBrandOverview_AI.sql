/****** Object:  StoredProcedure [dbo].[USP_GetBrandOverview_AI]    Script Date: 4/7/2026 11:04:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[USP_GetBrandOverview_AI]     
    @CompanyKey         NVARCHAR(100),          -- Comp_ID OR Comp_Email OR Comp_Name    
    @Window             VARCHAR(20) = NULL,    
    @CompanyKeyType     VARCHAR(10) = 'ID',     -- 'ID' | 'EMAIL' | 'NAME'    
    @FromDate           DATE        = NULL,     -- inclusive start (defaults to current month)    
    @ToDate             DATE        = NULL,     -- inclusive end    
    @ServiceID          INT         = NULL,     -- optional filter    
    @OveruseThreshold   INT         = 10        -- distinct (code1, code2) count > threshold => suspicious    
as                
begin                  
              
 SET NOCOUNT ON;    
    
    drop table if exists #TPro_id;
    drop table if exists #TM_Code;
    drop table if exists #tPro_Enq;

    declare @LifetimeCodeGeneration int;
    declare @AntiCounterfeitMeasures int;
    declare @CounterfeitAttemptsDetected int;
    declare @NumberofScans int;
    declare @RepeatedCodes int;
    declare @NumberofActiveUsers int;

    ---------------------------------------------------------
    -- DATE RANGE LOGIC
    ---------------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    IF UPPER(@Window) = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF UPPER(@Window) = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @Today);
        SET @EndDate   = @Today;
    END
    -- Current calendar week (Monday–Sunday)
    ELSE IF UPPER(@Window) = 'WEEK'
    BEGIN
        SET DATEFIRST 1; -- Monday = 1
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @EndDate   = DATEADD(DAY, 7, @StartDate);
    END
    -- Previous calendar week
    ELSE IF UPPER(@Window) = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    -- Current calendar month
    ELSE IF UPPER(@Window) = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
    END
    -- Previous calendar month
    ELSE IF UPPER(@Window) = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
        SET @EndDate   = @ThisMonthStart;
    END
    ELSE IF UPPER(@Window) = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    -- Default fallback
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(MONTH, 1, @StartDate);
    END

    -----------------------END__________________--
 
    select Pro_ID into #TPro_id from Pro_reg WITH (NOLOCK) where Comp_id = @CompanyKey
    select * into #TM_Code from M_Code WITH (NOLOCK) where Pro_id in (select * from #TPro_id WITH (NOLOCK)) and Use_Count is not null
    

    SELECT received_code1,received_code2, MobileNo,Is_Success
    into #tPro_Enq FROM Pro_enq pe WITH (NOLOCK)
    INNER JOIN #TM_Code mc WITH (NOLOCK)
       ON pe.received_code1 = CAST(mc.code1 AS NVARCHAR(50))
       AND pe.received_code2 = CAST(mc.code2 AS NVARCHAR(50))
     WHERE pe.Enq_Date >= @StartDate
     AND pe.Enq_Date <  @EndDate
     AND pe.Comp_ID = @CompanyKey; -- Add filter fix if missing

    select @LifetimeCodeGeneration =  count(Row_ID)  from M_Code WITH (NOLOCK) where Pro_id in (select * from #TPro_id WITH (NOLOCK))
    select @AntiCounterfeitMeasures = count(received_code2) from #tPro_Enq WITH (NOLOCK) where Is_Success = 1
    select @NumberofScans = count(received_code2) from #tPro_Enq WITH (NOLOCK) 
    select @NumberofActiveUsers = COUNT(DISTINCT MobileNo) FROM #tPro_Enq where Is_Success = 1;
    select @RepeatedCodes = count(received_code2) from #tPro_Enq where Is_Success > 1
    select @CounterfeitAttemptsDetected = count(pe.received_code2) from Pro_enq pe WITH (NOLOCK) 
                                                                      left join #TM_Code mc WITH (NOLOCK) 
                                                                      ON pe.received_code1 = CAST(mc.code1 AS NVARCHAR(50))
                                                                         AND pe.received_code2 = CAST(mc.code2 AS NVARCHAR(50))    
                                                                      where mc.Code2 is null and pe.Comp_ID = @CompanyKey
                                                                       and  pe.Enq_Date >= @StartDate
                                                                       AND pe.Enq_Date <  @EndDate;
    
    SELECT 'Anti-Counterfeit Measures'      AS title, @AntiCounterfeitMeasures      AS TotalCount,
           0.00 AS per, '#FFC107' AS ColorCode, '/anti-counterfeit' AS link
    UNION ALL
    SELECT 'Counterfeit Attempts Detected', @CounterfeitAttemptsDetected,
           0.00, '#FF0000', '/anti-counterfeit'
    UNION ALL
    SELECT 'Number of Scans',               @NumberofScans,
           0.00, '#E2852E', '/anti-counterfeit'
    UNION ALL
    SELECT 'Repeated Codes (= 10)',         @RepeatedCodes,
           0.00, '#62109F', '/anti-counterfeit'
    UNION ALL
    SELECT 'Number of Active Users',        @NumberofActiveUsers,
           0.00, '#F87B1B', '/anti-counterfeit'
    UNION ALL
    SELECT 'Lifetime Code Generation',      @LifetimeCodeGeneration,
           100.00, '#FC5185', '/anti-counterfeit';
    
END;
GO
