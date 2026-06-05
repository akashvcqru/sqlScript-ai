USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-06-04
-- Description: Retrieves products and scan details for codes checked more than 10 times across all companies (Admin view).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodesCheckedMoreThan10Times_Admin_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT 
        (pe.Received_Code1 + pe.Received_Code2) AS UniqueCode,
        pr.Pro_Name AS ProductName,
        pr.Pro_ID AS ProductID,
        pe.Comp_ID AS CompId,
        c.Comp_Name AS CompanyName,
        COUNT(pe.Enq_Date) AS CodeCheckCount,
        MAX(pe.Enq_Date) AS LastCodeCheckTime,
        pr.Pro_Entry_Date AS ProRegDate
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN Comp_Reg c WITH (NOLOCK) ON pe.Comp_ID = c.Comp_ID
    LEFT JOIN M_Code mc WITH (NOLOCK) ON pe.Received_Code1 = mc.Code1 AND pe.Received_Code2 = mc.Code2
    LEFT JOIN M_Code_PFL mcp WITH (NOLOCK) ON pe.Received_Code1 = mcp.Code1 AND pe.Received_Code2 = mcp.Code2
    LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = COALESCE(mc.Pro_ID, mcp.Pro_ID)
    GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, pe.Received_Code1, pe.Received_Code2, pe.Comp_ID, c.Comp_Name
    HAVING COUNT(pe.Enq_Date) > 10
    ORDER BY LastCodeCheckTime DESC;
END
GO
