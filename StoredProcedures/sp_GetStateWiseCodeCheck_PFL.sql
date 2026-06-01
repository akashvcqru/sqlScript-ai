USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec sp_GetStateWiseCodeCheck_PFL 'Comp-1693', 'MONTH'
CREATE OR ALTER procedure [dbo].[sp_GetStateWiseCodeCheck_PFL]     
(    
    @Comp_id varchar(20),  
    @Window NVARCHAR(10) = NULL  
)    
as      
begin         
    SET NOCOUNT ON;  

    ------------------------------------------------------
    -- Company start date
    ------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;  
    SELECT @CompanyStartDate = Reg_Date 
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_id AND Status = 1;  

    ------------------------------------------------------
    -- Calendar based Date Window
    ------------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(10) = UPPER(ISNULL(@Window,''));

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
    -- Main query
    ------------------------------------------------------
    ;WITH ValidScans AS 
    (  
        SELECT  
            pe.UniqueCode,
            pe.MobileNo,  
            COALESCE(
                NULLIF(g.State, ''), 
                NULLIF(pe.State, ''), 
                NULLIF(mc.State, ''), 
                'Not Available'
            ) AS State  
        FROM pfl_codecheckData pe WITH (NOLOCK)
        LEFT JOIN M_Consumer mc WITH (NOLOCK) ON RIGHT(pe.MobileNo, 10) = mc.MobileLast10
        LEFT JOIN GeoLocationData g WITH (NOLOCK) 
            ON g.Comp_Id = pe.Comp_Id 
            AND g.MobileNo = pe.MobileNo
            AND g.Code1 = pe.Code1V
            AND g.Code2 = pe.Code2V
        WHERE pe.Enq_Date >= @StartDate  
          AND pe.Enq_Date < @EndDate
          AND (@CompanyStartDate IS NULL OR pe.Enq_Date >= @CompanyStartDate)
          AND COALESCE(NULLIF(g.State, ''), NULLIF(pe.State, ''), NULLIF(mc.State, ''), 'Not Available') NOT IN ('NA','undefined','null')  
    )
    SELECT TOP 10  
        State,  
        COUNT(1) AS Total_Checked_Code,
        COUNT(DISTINCT MobileNo) AS Total_Users  
    FROM ValidScans  
    GROUP BY State  
    ORDER BY Total_Checked_Code DESC;

end
GO
