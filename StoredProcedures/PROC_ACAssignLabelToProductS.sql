-- =============================================
-- Author:      AI
-- Create date: 2026-06-25
-- Description: Get products details for ACAssignLabelToProductS API (based on PROC_SelectProductDetailsNoofCodes_ddl)
-- =============================================
CREATE PROCEDURE [dbo].[PROC_ACAssignLabelToProductS]
    @Comp_ID nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        SELECT 
            Pro_Reg.Comp_ID, 
            Pro_Reg.Pro_ID, 
            Pro_Reg.Pro_Name
        FROM Comp_Reg 
        INNER JOIN Pro_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID 
        WHERE (Pro_Reg.Comp_ID = @Comp_ID) 
          AND (CONVERT(INT, (
              SELECT COUNT(Pro_ID) AS Expr1
              FROM M_Code_PFL M_Code
              WHERE (Pro_ID = Pro_Reg.Pro_ID) 
                AND (Print_Status = 1) 
                AND (M_Code.Batch_No IS NULL) 
                AND (isnull(M_Code.ScrapeFlag, 0) = 0) 
                AND (DispatchFlag = 1) 
                AND (ReceiveFlag = 1)
          )) > 0)
        GROUP BY Pro_Reg.Comp_ID, Pro_Reg.Pro_ID, Pro_Reg.Pro_Name, Comp_Reg.Comp_Name
    END
    ELSE
    BEGIN
        SELECT 
            Pro_Reg.Comp_ID, 
            Pro_Reg.Pro_ID, 
            Pro_Reg.Pro_Name
        FROM Comp_Reg 
        INNER JOIN Pro_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID 
        WHERE (Pro_Reg.Comp_ID = @Comp_ID) 
          AND (CONVERT(INT, (
              SELECT COUNT(Pro_ID) AS Expr1
              FROM M_Code M_Code
              WHERE (Pro_ID = Pro_Reg.Pro_ID) 
                AND (Print_Status = 1) 
                AND (M_Code.Batch_No IS NULL) 
                AND (isnull(M_Code.ScrapeFlag, 0) = 0) 
                AND (DispatchFlag = 1) 
                AND (ReceiveFlag = 1)
          )) > 0)
        GROUP BY Pro_Reg.Comp_ID, Pro_Reg.Pro_ID, Pro_Reg.Pro_Name, Comp_Reg.Comp_Name
    END
END
GO
