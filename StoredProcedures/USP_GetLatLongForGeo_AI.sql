USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[USP_GetLatLongForGeo_AI] 'Comp-1693'
CREATE OR ALTER PROCEDURE [dbo].[USP_GetLatLongForGeo_AI]  
(  
    @CompId     VARCHAR(50)
)  
AS  
BEGIN  
    SET NOCOUNT ON;  

    IF (@CompId = 'Comp-1693') -- patanjali
    BEGIN
        DROP TABLE IF EXISTS #TPro_id;
        DROP TABLE IF EXISTS #TM_Code;
        DROP TABLE IF EXISTS #tPro_Enq;

        SELECT Pro_ID INTO #TPro_id FROM Pro_reg WITH (NOLOCK) WHERE Comp_id = @CompId;
        SELECT * INTO #TM_Code FROM M_Code_PFL WITH (NOLOCK) WHERE Pro_id IN (SELECT * FROM #TPro_id WITH (NOLOCK)) AND Use_Count IS NOT NULL;

        SELECT pe.* 
        INTO #tPro_Enq FROM Pro_enq pe WITH (NOLOCK)
        INNER JOIN #TM_Code mc WITH (NOLOCK)
           ON pe.received_code1 = CAST(mc.code1 AS NVARCHAR(50))
           AND pe.received_code2 = CAST(mc.code2 AS NVARCHAR(50));

        WITH FilteredProEnq AS
        (
            SELECT 
                p.MobileNo,
                p.Latitude,
                p.Longitude,
                @CompId AS Comp_Id,
                p.Received_Code1,
                p.Received_Code2,
                p.Enq_Date
            FROM #tPro_Enq p WITH (NOLOCK)
            WHERE p.Latitude IS NOT NULL 
              AND p.Latitude <> ''
        )
        SELECT F.*
        FROM FilteredProEnq F
        OUTER APPLY
        (
            SELECT TOP 1 1 AS Found
            FROM GeoLocationData G WITH (NOLOCK)
            WHERE G.Comp_Id  = F.Comp_Id
              AND G.MobileNo = F.MobileNo
              AND G.Code1 = F.Received_Code1
              AND G.Code2 = F.Received_Code2
        ) AS GCheck
        WHERE GCheck.Found IS NULL
        ORDER BY F.Enq_Date DESC;
    END
    ELSE
    BEGIN
        WITH FilteredProEnq AS
        (
            SELECT 
                p.MobileNo,
                p.Latitude,
                p.Longitude,
                p.Comp_Id,
                p.Received_Code1,
                p.Received_Code2,
                p.Enq_Date
            FROM Pro_Enq p WITH (NOLOCK)
            WHERE p.Comp_Id = @CompId
              AND p.Latitude IS NOT NULL 
              AND p.Latitude <> ''
        )
        SELECT F.*
        FROM FilteredProEnq F
        OUTER APPLY
        (
            SELECT TOP 1 1 AS Found
            FROM GeoLocationData G WITH (NOLOCK)
            WHERE G.Comp_Id  = F.Comp_Id
              AND G.MobileNo = F.MobileNo
              AND G.Code1 = F.Received_Code1
              AND G.Code2 = F.Received_Code2
        ) AS GCheck
        WHERE GCheck.Found IS NULL
        ORDER BY F.Enq_Date DESC;
    END
END
GO
