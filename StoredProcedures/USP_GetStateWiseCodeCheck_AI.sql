USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetStateWiseCodeCheck_AI]    Script Date: 4/7/2026 1:59:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[USP_GetStateWiseCodeCheck_AI] 'Comp-1599','quarter'
CREATE OR ALTER PROCEDURE [dbo].[USP_GetStateWiseCodeCheck_AI] --'Comp-1436'    
(    
    @Comp_id varchar(20),  
    @datePreset NVARCHAR(20) = 'ALL'  
)    
AS      
BEGIN         
    SET NOCOUNT ON;  
    DECLARE @CompanyStartDate DATETIME;  
    SELECT @CompanyStartDate = Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_id AND Status = 1;  
  
    -- Determine start date based on window  
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset,''))));
    
    IF @Win = '' OR @Win = 'NULL' SET @Win = 'ALL';

    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = DATEADD(DAY,1,@Today);
    END
    ELSE IF @Win = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY,-1,@Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'WEEK'
    BEGIN
        SET DATEFIRST 1; -- Monday
        SET @StartDate = DATEADD(DAY,1-DATEPART(WEEKDAY,@Today),@Today);
        SET @EndDate   = DATEADD(DAY,1,@Today); -- till today only
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE =
            DATEADD(DAY,1-DATEPART(WEEKDAY,@Today),@Today);

        SET @StartDate = DATEADD(DAY,-7,@ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1);
        SET @EndDate   = DATEADD(DAY,1,@Today); -- till today only
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE =
            DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1);

        SET @StartDate = DATEADD(MONTH,-1,@ThisMonthStart);
        SET @EndDate   = @ThisMonthStart;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY,-90,@Today);
        SET @EndDate   = DATEADD(DAY,1,@Today);
    END
    ELSE IF @Win = 'ALL'
    BEGIN
        SET @StartDate = '19000101';
        SET @EndDate   = DATEADD(DAY,1,@Today);
    END
    ELSE
    BEGIN
        -- Default = current month till today
        SET @StartDate = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1);
        SET @EndDate   = DATEADD(DAY,1,@Today);
    END

    ------------------------------------------------------
    -- Step 1: Pre-filter M_Code (Deduplicated per code pair)
    ------------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    CREATE TABLE #tempM_Code (
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        Pro_ID VARCHAR(50)
    );

    IF @Comp_id = 'Comp-1693'
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code_PFL a 
            INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_id 
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID)
        SELECT Code1, Code2, Pro_ID
        FROM DistinctCodes
        WHERE rn = 1;
    END
    ELSE
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, 
                a.Code2, 
                a.Pro_ID,
                a.Use_Count,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a 
            INNER JOIN Pro_Reg b ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_id 
              AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID)
        SELECT Code1, Code2, Pro_ID
        FROM DistinctCodes
        WHERE rn = 1;
    END

    CREATE INDEX IX_tempM_Code_Codes ON #tempM_Code(Code1, Code2);

    ------------------------------------------------------
    -- Step 2: Main Scan Data with Geolocation Fallback
    ------------------------------------------------------
    ;WITH ScansWithGeo AS (
        SELECT 
            pe.Received_Code1,
            pe.Received_Code2,
            RIGHT(pe.MobileNo, 10) AS MobileLast10,
            -- Fallback chain: GeoLocation -> Scan Table -> Consumer Table -> Default
            COALESCE(
                NULLIF(g.State, ''), 
                NULLIF(pe.State, ''), 
                NULLIF(mc_usr.State, ''), 
                'Not Available'
            ) AS State
        FROM Pro_Enq pe WITH (NOLOCK)
        LEFT JOIN GeoLocationData g WITH (NOLOCK) 
            ON g.Comp_Id = pe.Comp_Id 
            AND g.Code1 = pe.Received_Code1 
            AND g.Code2 = pe.Received_Code2 
            AND g.MobileNo = pe.MobileNo
        LEFT JOIN M_Consumer mc_usr ON RIGHT(pe.MobileNo, 10) = mc_usr.MobileLast10
        LEFT JOIN #tempM_Code mc ON LTRIM(RTRIM(CAST(mc.Code1 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) 
              AND LTRIM(RTRIM(CAST(mc.Code2 AS VARCHAR(50)))) = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
        WHERE pe.Comp_Id = @Comp_id
          AND pe.Enq_Date >= @StartDate
          AND pe.Enq_Date < @EndDate
          AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
          -- Removed filter to include ALL scans (Genuine, Duplicate, Invalid) per user requirement
    )
    SELECT TOP 10  
        [State],  
        COUNT(DISTINCT CAST(Received_Code1 AS VARCHAR(50)) + '-' + CAST(Received_Code2 AS VARCHAR(50))) AS Total_Checked_Code,  
        COUNT(DISTINCT MobileLast10) AS Total_Users  
    FROM ScansWithGeo  
    WHERE State NOT IN ('NA','undefined','null')  
    GROUP BY State  
    ORDER BY Total_Checked_Code DESC;      
END
GO
