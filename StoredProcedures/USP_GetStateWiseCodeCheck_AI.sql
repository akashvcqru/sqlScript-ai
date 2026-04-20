USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetStateWiseCodeCheck_AI]    Script Date: 4/7/2026 1:59:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[USP_GetStateWiseCodeCheck_AI] 'Comp-1599','quarter'
CREATE PROCEDURE [dbo].[USP_GetStateWiseCodeCheck_AI] --'Comp-1436'    
(    
    @Comp_id varchar(20),  
    @Window NVARCHAR(10) = NULL  
)    
AS      
BEGIN         
    SET NOCOUNT ON;  
    DECLARE @CompanyStartDate DATETIME;  
    SELECT @CompanyStartDate = Reg_Date FROM Comp_Reg WHERE Comp_ID = @Comp_id AND Status = 1;  
  
    -- Determine start date based on window  
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

    ;WITH ValidScans AS (  
        SELECT   
            PE.Received_Code1,  
            PE.Received_Code2,  
            MC.P_MobileNo,  
            ISNULL(NULLIF(MC.[State], ''), 'Not Available') AS State  
        FROM (SELECT * FROM Pro_Enq WITH (NOLOCK) WHERE enq_date >= @StartDate) PE     
        INNER JOIN ( 
            SELECT
                G.Comp_Id AS G_Comp_Id,
                P.Comp_Id AS P_Comp_Id,
                G.MobileNo AS G_MobileNo,
                P.MobileNo AS P_MobileNo,
                LEFT(G.Latitude,6) AS G_Latitude,
                LEFT(G.Longitude,6) AS G_Longitude,
                LEFT(P.Latitude,6) AS P_Latitude,
                LEFT(P.Longitude,6) AS P_Longitude,
                P.Is_Success,
                G.Code1 AS G_Code1,
                P.Received_Code1 AS P_Code1,
                G.Code2 AS G_Code2,
                P.Received_Code2 AS P_Code2,
                G.Postcode,
                G.State,
                G.City,
                G.StateDistrict,
                G.Town,
                G.Suburb,
                G.Enq_Date,
                ROW_NUMBER() OVER
                (
                    PARTITION BY RIGHT(G.MobileNo,10),code1,code2,G.Enq_Date
                    ORDER BY G.Enq_Date DESC
                ) AS rn
            FROM GeoLocationData G WITH (NOLOCK)
            OUTER APPLY
            (
                SELECT TOP 1 *
                FROM Pro_Enq P WITH (NOLOCK)
                WHERE P.Comp_Id = G.Comp_Id
                  AND P.Received_Code1 = G.Code1
                  AND P.Received_Code2 = G.Code2
                  AND P.MobileNo = G.MobileNo
                  AND P.Enq_Date >= @StartDate
            ) P
            WHERE 
                G.Comp_Id = @Comp_id
                AND G.Enq_Date >= @StartDate
                AND ISNULL(G.State,'') <> ''
                AND LEN(LTRIM(RTRIM(G.State))) >= 2
        ) MC ON MC.P_MobileNo = PE.MobileNo  
        INNER JOIN (
            SELECT * FROM M_Code WITH (NOLOCK) 
            WHERE pro_id IN (SELECT Pro_ID FROM Pro_Reg PR WITH (NOLOCK) WHERE PR.Comp_ID = @Comp_id) 
              AND Gen_Date >= @CompanyStartDate
        ) MCO ON (CAST(PE.Received_Code1 AS NVARCHAR(20)) + CAST(PE.Received_Code2 AS NVARCHAR(20))) =  
               (CAST(MCO.Code1 AS NVARCHAR(20)) + CAST(MCO.Code2 AS NVARCHAR(20)))  
        INNER JOIN Pro_Reg PR WITH (NOLOCK)  
            ON PR.Pro_ID = MCO.Pro_ID  
           AND PR.Comp_ID = @Comp_id  
        WHERE PE.Enq_Date >= @StartDate  
          AND MC.State NOT IN ('NA','undefined','null')  
    )  
    SELECT TOP 10  
        [State],  
        COUNT(DISTINCT CAST(Received_Code1 AS NVARCHAR(20)) + CAST(Received_Code2 AS NVARCHAR(20))) AS Total_Checked_Code,  
        COUNT(DISTINCT P_MobileNo) AS Total_Users  
    FROM ValidScans  
    GROUP BY State  
    ORDER BY Total_Checked_Code DESC;      
END      
GO
