USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI
-- Create date: 2026-04-14
-- Description: Recent Code Check for Company Dashboard
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetRecentCodeCheck_AI]    
(    
    @Comp_Id VARCHAR(20),
    @Window NVARCHAR(20) = NULL
)    
AS    
BEGIN    
    SET NOCOUNT ON;

    -------------------------------------------------
    -- 1. Get Company Registration Date
    -------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;

    SELECT @CompanyStartDate = Reg_Date 
    FROM Comp_Reg 
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    IF @CompanyStartDate IS NULL
        SET @CompanyStartDate = '1900-01-01';

    -------------------------------------------------
    -- 2. Setup Date Range based ONLY on Window
    -------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@Window,''));

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
        SET @EndDate   = DATEADD(DAY,1,@Today);
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
    ELSE
    BEGIN
        -- Default = current month till today
        SET @StartDate = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1);
        SET @EndDate   = DATEADD(DAY,1,@Today);
    END


    -------------------------------------------------
    -- 3. Prepare M_Code Mapping
    -------------------------------------------------
    ;WITH MC AS
    (
        SELECT 
              MC.Pro_ID
            , MC.Batch_No
            , MC.Use_Count
            , PR.Pro_Name
            , CAST(MC.Code1 AS NVARCHAR(10)) AS Code1V
            , CAST(MC.Code2 AS NVARCHAR(10)) AS Code2V
        FROM M_Code MC WITH (NOLOCK)
        JOIN Pro_Reg PR WITH (NOLOCK)
             ON MC.Pro_ID = PR.Pro_ID
            AND PR.Comp_ID = @Comp_Id
        WHERE MC.Gen_Date >= @CompanyStartDate
    ),

    -------------------------------------------------
    -- 4. Latest Geo per MobileNo
    -------------------------------------------------
    Geo AS
    (
        SELECT *
        FROM
        (
            SELECT
                  RIGHT(G.MobileNo,10) AS Mobile10
                , G.City, G.State, G.Postcode, G.Latitude,G.Longitude
                , ROW_NUMBER() OVER (PARTITION BY RIGHT(G.MobileNo,10) ORDER BY G.Enq_Date DESC) AS rn
            FROM GeoLocationData G WITH (NOLOCK)
            WHERE G.Comp_Id = @Comp_Id
              AND G.Enq_Date >= @StartDate
        ) X
        WHERE rn = 1
    ),

    -------------------------------------------------
    -- 5. Calculate Distinct Locations per Code
    -------------------------------------------------
    CodeStats AS
    (
        SELECT 
              Received_Code1
            , Received_Code2
            , COUNT(*) AS TotalScans
            , COUNT(DISTINCT CONCAT(Latitude, '|', Longitude)) AS DistinctLocations
        FROM Pro_Enq WITH (NOLOCK)
        WHERE Comp_Id = @Comp_Id
          AND Enq_Date >= @StartDate
        GROUP BY Received_Code1, Received_Code2
    )

    -------------------------------------------------
    -- 6. Final Output
    -------------------------------------------------
    SELECT TOP 5
          PE.MobileNo
        , MC.Pro_ID
        , MC.Pro_Name
        , MC.Batch_No
        , MC.Code1V
        , MC.Code2V
        , (MC.Code1V + MC.Code2V) AS UniqueCode
        , PE.Enq_Date
        , PE.Dial_Mode
        
        -------------------------------------------------
        -- Scan Status
        -------------------------------------------------
        , CASE 
              WHEN PE.is_success = 1 THEN 'Authenticate'
              WHEN PE.is_success = 2 THEN 'Reauthenticate'
              ELSE 'Invalid'
          END AS Status,

          CASE WHEN PE.is_success = 1 THEN 'First' ELSE 'Repeat' END AS Use_Count_Indication

        -------------------------------------------------
        -- Risk Level
        -------------------------------------------------
        , CASE   
              WHEN CS.TotalScans > 1 AND CS.DistinctLocations = 1 THEN 'Medium Risk'
              WHEN CS.DistinctLocations > 1 THEN 'High Risk'
              ELSE 'Low Risk'
          END AS RiskLevel

        , MC.Use_Count
        , GEO.State
        , GEO.City
        , GEO.Postcode AS PinCode
        , GEO.Latitude
        , GEO.Longitude

    FROM Pro_Enq PE WITH (NOLOCK)
    JOIN MC 
        ON PE.Received_Code1 = MC.Code1V
       AND PE.Received_Code2 = MC.Code2V

    LEFT JOIN Geo GEO
        ON GEO.Mobile10 = RIGHT(PE.MobileNo,10)
    
    LEFT JOIN CodeStats CS
        ON CS.Received_Code1 = PE.Received_Code1
       AND CS.Received_Code2 = PE.Received_Code2

    WHERE 
        PE.Comp_Id = @Comp_Id
        AND PE.Enq_Date >= @StartDate
        AND PE.Enq_Date <  DATEADD(DAY,1,@EndDate)
        AND PE.Enq_Date >= @CompanyStartDate

    ORDER BY PE.Enq_Date DESC;
END 
GO
