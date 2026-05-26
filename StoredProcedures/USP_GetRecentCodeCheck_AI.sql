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
    @Comp_Id VARCHAR(20)
)    
AS    
BEGIN    
    SET NOCOUNT ON;

    -------------------------------------------------
    -- 1. Get Company Registration Date
    -------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;

    SELECT @CompanyStartDate = Reg_Date 
    FROM Comp_Reg WITH (NOLOCK)
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    IF @CompanyStartDate IS NULL
        SET @CompanyStartDate = '1900-01-01';

    -------------------------------------------------
    -- 2. Get Recent Scans (Fetch more to ensure we get enough valid ones after join)
    -------------------------------------------------
    ;WITH PE_Recent AS
    (
        SELECT TOP 20 
              Received_Code1
            , Received_Code2
            , MobileNo
            , Enq_Date
            , Dial_Mode
            , is_success
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_Id = @Comp_Id
          AND PE.Enq_Date >= @CompanyStartDate
        ORDER BY PE.Enq_Date DESC
    ),

    -------------------------------------------------
    -- 3. Prepare M_Code Mapping for these specific codes
    -------------------------------------------------
    MC AS
    (
        SELECT 
              MC.Pro_ID
            , MC.Batch_No
            , MC.Use_Count
            , PR.Pro_Name
            , CAST(MC.Code1 AS NVARCHAR(10)) AS Code1V
            , CAST(MC.Code2 AS NVARCHAR(10)) AS Code2V
        FROM M_Code MC WITH (NOLOCK)
        JOIN Pro_Reg PR WITH (NOLOCK) ON MC.Pro_ID = PR.Pro_ID
        WHERE PR.Comp_ID = @Comp_Id AND @Comp_Id <> 'Comp-1693'
          AND EXISTS (SELECT 1 FROM PE_Recent PE WHERE PE.Received_Code1 = CAST(MC.Code1 AS NVARCHAR(10)) AND PE.Received_Code2 = CAST(MC.Code2 AS NVARCHAR(10)))

        UNION ALL

        SELECT 
              MC.Pro_ID
            , MC.Batch_No
            , MC.Use_Count
            , PR.Pro_Name
            , CAST(MC.Code1 AS NVARCHAR(10)) AS Code1V
            , CAST(MC.Code2 AS NVARCHAR(10)) AS Code2V
        FROM M_Code_PFL MC WITH (NOLOCK)
        JOIN Pro_Reg PR WITH (NOLOCK) ON MC.Pro_ID = PR.Pro_ID
        WHERE PR.Comp_ID = @Comp_Id AND @Comp_Id = 'Comp-1693'
          AND EXISTS (SELECT 1 FROM PE_Recent PE WHERE PE.Received_Code1 = CAST(MC.Code1 AS NVARCHAR(10)) AND PE.Received_Code2 = CAST(MC.Code2 AS NVARCHAR(10)))
    ),

    -------------------------------------------------
    -- 4. Latest Geo only for the mobiles in the candidates
    -------------------------------------------------
    Geo AS
    (
        SELECT *
        FROM
        (
            SELECT
                  RIGHT(G.MobileNo,10) AS Mobile10
                , G.City, G.State, G.Postcode, G.Latitude, G.Longitude
                , ROW_NUMBER() OVER (PARTITION BY RIGHT(G.MobileNo,10) ORDER BY G.Enq_Date DESC) AS rn
            FROM GeoLocationData G WITH (NOLOCK)
            WHERE G.Comp_Id = @Comp_Id
              AND EXISTS (SELECT 1 FROM PE_Recent PE WHERE RIGHT(PE.MobileNo,10) = RIGHT(G.MobileNo,10))
        ) X
        WHERE rn = 1
    ),

    -------------------------------------------------
    -- 5. Calculate Distinct Locations for these candidates
    -------------------------------------------------
    CodeStats AS
    (
        SELECT 
              PE.Received_Code1
            , PE.Received_Code2
            , COUNT(*) AS TotalScans
            , COUNT(DISTINCT CONCAT(Latitude, '|', Longitude)) AS DistinctLocations
        FROM Pro_Enq PE WITH (NOLOCK)
        WHERE PE.Comp_Id = @Comp_Id
          AND EXISTS (SELECT 1 FROM PE_Recent R WHERE R.Received_Code1 = PE.Received_Code1 AND R.Received_Code2 = PE.Received_Code2)
        GROUP BY PE.Received_Code1, PE.Received_Code2
    )

    -------------------------------------------------
    -- 6. Final Output: Top 5 Valid records
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
        
        , CASE 
              WHEN PE.is_success = 1 THEN 'Authenticate'
              WHEN PE.is_success = 2 THEN 'Reauthenticate'
              ELSE 'Invalid'
          END AS Status,

          CASE WHEN PE.is_success = 1 THEN 'First' ELSE 'Repeat' END AS Use_Count_Indication

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

    FROM PE_Recent PE
    JOIN MC 
        ON PE.Received_Code1 = MC.Code1V
       AND PE.Received_Code2 = MC.Code2V

    LEFT JOIN Geo GEO
        ON GEO.Mobile10 = RIGHT(PE.MobileNo,10)
    
    LEFT JOIN CodeStats CS
        ON CS.Received_Code1 = PE.Received_Code1
       AND CS.Received_Code2 = PE.Received_Code2

    ORDER BY PE.Enq_Date DESC;
END 
GO
