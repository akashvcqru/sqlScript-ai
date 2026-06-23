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
    -- 2. Build Optimized Temp Tables
    -------------------------------------------------
    IF OBJECT_ID('tempdb..#tempM_Code') IS NOT NULL DROP TABLE #tempM_Code;
    CREATE TABLE #tempM_Code (
        Code1 VARCHAR(100),
        Code2 VARCHAR(100),
        Pro_ID VARCHAR(50),
        Batch_No VARCHAR(100),
        Use_Count INT,
        VCode1 VARCHAR(50),
        VCode2 VARCHAR(50),
        Pro_Name VARCHAR(200)
    );

    IF @Comp_Id = 'Comp-1693'
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, a.Code2, a.Pro_ID, a.Batch_No, a.Use_Count, b.Pro_Name,
                CAST(a.Code1 AS VARCHAR(50)) AS VCode1, CAST(a.Code2 AS VARCHAR(50)) AS VCode2,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code_PFL a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_Id AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, Batch_No, Use_Count, VCode1, VCode2, Pro_Name)
        SELECT Code1, Code2, Pro_ID, Batch_No, Use_Count, VCode1, VCode2, Pro_Name FROM DistinctCodes WHERE rn = 1;
    END
    ELSE
    BEGIN
        ;WITH DistinctCodes AS (
            SELECT 
                a.Code1, a.Code2, a.Pro_ID, a.Batch_No, a.Use_Count, b.Pro_Name,
                CAST(a.Code1 AS VARCHAR(50)) AS VCode1, CAST(a.Code2 AS VARCHAR(50)) AS VCode2,
                ROW_NUMBER() OVER (PARTITION BY a.Code1, a.Code2 ORDER BY a.Use_Count DESC) AS rn
            FROM M_Code a WITH (NOLOCK)
            INNER JOIN Pro_Reg b WITH (NOLOCK) ON a.Pro_ID = b.Pro_ID 
            WHERE b.Comp_ID = @Comp_Id AND a.Use_Count > 0
        )
        INSERT INTO #tempM_Code (Code1, Code2, Pro_ID, Batch_No, Use_Count, VCode1, VCode2, Pro_Name)
        SELECT Code1, Code2, Pro_ID, Batch_No, Use_Count, VCode1, VCode2, Pro_Name FROM DistinctCodes WHERE rn = 1;
    END

    CREATE INDEX IX_tempM_Code_12 ON #tempM_Code(VCode1, VCode2);

    -------------------------------------------------
    -- 3. Get Recent Scans (Top 5 Valid)
    -------------------------------------------------
    IF OBJECT_ID('tempdb..#PE_Recent') IS NOT NULL DROP TABLE #PE_Recent;
    SELECT TOP 5 
          pe.Received_Code1
        , pe.Received_Code2
        , pe.MobileNo
        , pe.Enq_Date
        , pe.Dial_Mode
        , pe.is_success
        , LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50)))) AS VCode1
        , LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50)))) AS VCode2
    INTO #PE_Recent
    FROM Pro_Enq pe WITH (NOLOCK)
    WHERE pe.Enq_Date >= @CompanyStartDate
      AND (pe.Comp_Id = @Comp_Id OR (ISNULL(pe.Comp_Id, '') = '' AND EXISTS (
          SELECT 1 FROM #tempM_Code mc 
          WHERE mc.VCode1 = LTRIM(RTRIM(CAST(pe.Received_Code1 AS VARCHAR(50))))
            AND mc.VCode2 = LTRIM(RTRIM(CAST(pe.Received_Code2 AS VARCHAR(50))))
      )))
    ORDER BY pe.Enq_Date DESC;

    -------------------------------------------------
    -- 4. Latest Geo only for the mobiles in the candidates
    -------------------------------------------------
    ;WITH Geo AS
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
              AND EXISTS (SELECT 1 FROM #PE_Recent PE WHERE RIGHT(PE.MobileNo,10) = RIGHT(G.MobileNo,10))
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
            , COUNT(DISTINCT CONCAT(pe_all.Latitude, '|', pe_all.Longitude)) AS DistinctLocations
        FROM #PE_Recent PE
        LEFT JOIN Pro_Enq pe_all WITH (NOLOCK) 
            ON pe_all.Received_Code1 = PE.Received_Code1 
           AND pe_all.Received_Code2 = PE.Received_Code2
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
        , ISNULL(MC.VCode1, PE.Received_Code1) AS Code1V
        , ISNULL(MC.VCode2, PE.Received_Code2) AS Code2V
        , ISNULL((MC.VCode1 + MC.VCode2), ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '')) AS UniqueCode
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

        , ISNULL(MC.Use_Count, 0) AS Use_Count
        , GEO.State
        , GEO.City
        , GEO.Postcode AS PinCode
        , GEO.Latitude
        , GEO.Longitude

    FROM #PE_Recent PE
    LEFT JOIN #tempM_Code MC 
        ON PE.VCode1 = MC.VCode1
       AND PE.VCode2 = MC.VCode2

    LEFT JOIN Geo GEO
        ON GEO.Mobile10 = RIGHT(PE.MobileNo,10)
    
    LEFT JOIN CodeStats CS
        ON CS.Received_Code1 = PE.Received_Code1
       AND CS.Received_Code2 = PE.Received_Code2

    ORDER BY PE.Enq_Date DESC;
END 
GO
