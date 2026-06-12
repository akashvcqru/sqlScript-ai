USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-06-04
-- Description: Retrieves products and code scan details for codes checked more than 10 times for a given company.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodesCheckedMoreThan10Times_AI]
(
    @Comp_Id VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    IF @Comp_Id = 'Comp-1693'
    BEGIN
        SELECT 
            (pe.Received_Code1 + pe.Received_Code2) AS UniqueCode,
            pr.Pro_Name AS ProductName,
            pr.Pro_ID AS ProductID,
            COUNT(pe.Enq_Date) AS CodeCheckCount,
            MAX(pe.Enq_Date) AS LastCodeCheckTime,
            pr.Pro_Entry_Date AS ProRegDate
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_Code_PFL mc WITH (NOLOCK) ON pe.Received_Code1 = mc.Code1 AND pe.Received_Code2 = mc.Code2
        INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
        WHERE pr.Comp_ID = @Comp_Id
          AND (pe.Comp_ID = @Comp_Id OR ISNULL(pe.Comp_ID, '') = '')
        GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, pe.Received_Code1, pe.Received_Code2
        HAVING COUNT(pe.Enq_Date) > 10
        ORDER BY LastCodeCheckTime DESC;
    END
    ELSE
    BEGIN
        SELECT 
            (pe.Received_Code1 + pe.Received_Code2) AS UniqueCode,
            pr.Pro_Name AS ProductName,
            pr.Pro_ID AS ProductID,
            COUNT(pe.Enq_Date) AS CodeCheckCount,
            MAX(pe.Enq_Date) AS LastCodeCheckTime,
            pr.Pro_Entry_Date AS ProRegDate
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_Code mc WITH (NOLOCK) ON pe.Received_Code1 = mc.Code1 AND pe.Received_Code2 = mc.Code2
        INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
        WHERE pr.Comp_ID = @Comp_Id
          AND (pe.Comp_ID = @Comp_Id OR ISNULL(pe.Comp_ID, '') = '')
        GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, pe.Received_Code1, pe.Received_Code2
        HAVING COUNT(pe.Enq_Date) > 10
        ORDER BY LastCodeCheckTime DESC;
    END
END
GO
