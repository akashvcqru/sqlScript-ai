USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-06-04
-- Description: Retrieves detailed scan checks for a specific code1 and code2 under any company (Admin view).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeCheckDetailsByCode_Admin_AI]
(
    @Code1 VARCHAR(50),
    @Code2 VARCHAR(50),
    @Comp_Id VARCHAR(50) = NULL
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
        ISNULL(g.City, '') AS City,
        pe.Comp_ID AS CompId,
        cr.Comp_Name AS CompanyName
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN Comp_Reg cr WITH (NOLOCK) ON pe.Comp_ID = cr.Comp_ID
    LEFT JOIN M_Consumer c WITH (NOLOCK) ON RIGHT(c.MobileNo, 10) = RIGHT(pe.MobileNo, 10) AND c.IsDelete = 0
    LEFT JOIN (
        SELECT 
            Code1, Code2, MobileNo, State, City, Postcode, Comp_Id,
            ROW_NUMBER() OVER (PARTITION BY Code1, Code2, MobileNo, Comp_Id ORDER BY Enq_Date DESC) as rn
        FROM GeoLocationData WITH (NOLOCK)
    ) g ON g.Code1 = pe.Received_Code1 AND g.Code2 = pe.Received_Code2 AND RIGHT(g.MobileNo, 10) = RIGHT(pe.MobileNo, 10) AND g.Comp_Id = pe.Comp_ID AND g.rn = 1
    WHERE pe.Received_Code1 = @Code1
      AND pe.Received_Code2 = @Code2
      AND (@Comp_Id IS NULL OR pe.Comp_ID = @Comp_Id)
    ORDER BY pe.Enq_Date DESC;
END
GO
