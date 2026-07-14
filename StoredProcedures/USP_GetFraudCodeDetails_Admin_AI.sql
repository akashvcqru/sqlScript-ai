USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-07-14
-- Description: Retrieves detailed scan checks for a specific code1 and code2 with coordinates and service name (Admin view).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetFraudCodeDetails_Admin_AI]
(
    @Code1 VARCHAR(50),
    @Code2 VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT 
        (pe.Received_Code1 + pe.Received_Code2) AS CodeChecked,
        pe.MobileNo AS MobileNo,
        pe.Enq_Date AS EnqDate,
        ISNULL(pe.Latitude, ISNULL(g.Latitude, '')) AS Lat,
        ISNULL(pe.Longitude, ISNULL(g.Longitude, '')) AS [Long],
        ISNULL(ms.ServiceName, '') AS ServiceName
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_Code b WITH (NOLOCK)
        ON pe.Received_Code1 = CAST(b.code1 AS VARCHAR(50))
       AND pe.Received_Code2 = CAST(b.code2 AS VARCHAR(50))
    LEFT JOIN M_ServiceSubscription mss WITH (NOLOCK)
        ON b.Pro_ID = mss.Pro_ID AND pe.Comp_ID = mss.Comp_ID AND mss.IsDelete = 0 AND mss.IsActive = 1
    LEFT JOIN M_Service ms WITH (NOLOCK)
        ON mss.Service_ID = ms.Service_ID
    LEFT JOIN (
        SELECT 
            Code1, Code2, MobileNo, Latitude, Longitude, Comp_Id,
            ROW_NUMBER() OVER (PARTITION BY Code1, Code2, MobileNo, Comp_Id ORDER BY Enq_Date DESC) as rn
        FROM GeoLocationData WITH (NOLOCK)
    ) g ON g.Code1 = pe.Received_Code1 AND g.Code2 = pe.Received_Code2 AND RIGHT(g.MobileNo, 10) = RIGHT(pe.MobileNo, 10) AND g.Comp_Id = pe.Comp_ID AND g.rn = 1
    WHERE pe.Received_Code1 = @Code1
      AND pe.Received_Code2 = @Code2
    ORDER BY pe.Enq_Date DESC;
END
GO
