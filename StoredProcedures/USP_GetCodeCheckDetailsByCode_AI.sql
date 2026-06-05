USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-06-04
-- Description: Retrieves detailed scan checks for a specific code1 and code2 under a company.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeCheckDetailsByCode_AI]
(
    @Comp_Id VARCHAR(50),
    @Code1 VARCHAR(50),
    @Code2 VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT 
        ISNULL(c.ConsumerName, '') AS UserName,
        pe.MobileNo AS UserNumber,
        (pe.Received_Code1 + pe.Received_Code2) AS Code,
        pe.Enq_Date AS CodeCheckTime,
        ISNULL(pe.Latitude, '') AS Latitude,
        ISNULL(pe.Longitude, '') AS Longitude,
        ISNULL(g.Postcode, '') AS PinCode,
        ISNULL(g.State, '') AS State,
        ISNULL(g.City, '') AS City
    FROM Pro_Enq pe WITH (NOLOCK)
    LEFT JOIN M_Consumer c WITH (NOLOCK) ON RIGHT(c.MobileNo, 10) = RIGHT(pe.MobileNo, 10) AND c.IsDelete = 0
    LEFT JOIN (
        SELECT 
            Code1, Code2, MobileNo, State, City, Postcode,
            ROW_NUMBER() OVER (PARTITION BY Code1, Code2, MobileNo ORDER BY Enq_Date DESC) as rn
        FROM GeoLocationData WITH (NOLOCK)
        WHERE Comp_Id = @Comp_Id
    ) g ON g.Code1 = pe.Received_Code1 AND g.Code2 = pe.Received_Code2 AND RIGHT(g.MobileNo, 10) = RIGHT(pe.MobileNo, 10) AND g.rn = 1
    WHERE pe.Comp_ID = @Comp_Id
      AND pe.Received_Code1 = @Code1
      AND pe.Received_Code2 = @Code2
    ORDER BY pe.Enq_Date DESC;
END
GO
