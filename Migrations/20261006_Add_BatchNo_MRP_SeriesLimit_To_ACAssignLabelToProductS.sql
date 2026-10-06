-- =============================================
-- Migration: Add Batch_No, MRP, and Series_Limit to PROC_ACAssignLabelToProductS
-- Date: 2026-10-06
-- Description: Returns the latest Batch_No, MRP, and Series_Limit from T_Pro for each product.
-- =============================================

CREATE OR ALTER PROCEDURE [dbo].[PROC_ACAssignLabelToProductS]
    @Comp_ID    NVARCHAR(50),
    @Service_ID NVARCHAR(50) = 'SRV1018'
AS
BEGIN
    SET NOCOUNT ON;

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        SELECT 
            Pro_Reg.Comp_ID, 
            Pro_Reg.Pro_ID, 
            Pro_Reg.Pro_Name,
            Pro_Reg.BatchSize,
            (SELECT TOP 1 PlanMasterPeriod 
             FROM M_ServiceSubscription WITH (NOLOCK)
             WHERE Pro_ID = Pro_Reg.Pro_ID 
               AND (Service_ID = @Service_ID OR @Service_ID IS NULL)
               AND (IsDelete = 0 OR IsDelete IS NULL)
             ORDER BY EntryDate DESC) AS PlanMasterPeriod,
            (SELECT TOP 1 tp.Batch_No 
             FROM T_Pro tp WITH (NOLOCK) 
             WHERE tp.Pro_ID = Pro_Reg.Pro_ID 
             ORDER BY tp.Entry_Date DESC, tp.Row_ID DESC) AS Batch_No,
            (SELECT TOP 1 tp.MRP 
             FROM T_Pro tp WITH (NOLOCK) 
             WHERE tp.Pro_ID = Pro_Reg.Pro_ID 
             ORDER BY tp.Entry_Date DESC, tp.Row_ID DESC) AS MRP,
            (SELECT TOP 1 tp.Series_Limit 
             FROM T_Pro tp WITH (NOLOCK) 
             WHERE tp.Pro_ID = Pro_Reg.Pro_ID 
             ORDER BY tp.Entry_Date DESC, tp.Row_ID DESC) AS Series_Limit
        FROM Comp_Reg WITH (NOLOCK)
        INNER JOIN Pro_Reg WITH (NOLOCK) ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID 
        WHERE (Pro_Reg.Comp_ID = @Comp_ID) 
          AND EXISTS (
              SELECT 1 
              FROM M_ServiceSubscription ms WITH (NOLOCK)
              WHERE ms.Pro_ID = Pro_Reg.Pro_ID 
                AND (ms.Service_ID = @Service_ID OR @Service_ID IS NULL)
                AND (ms.IsDelete = 0 OR ms.IsDelete IS NULL)
          )
          AND (CONVERT(INT, (
              SELECT COUNT(Pro_ID) AS Expr1
              FROM M_Code_PFL M_Code WITH (NOLOCK)
              WHERE (Pro_ID = Pro_Reg.Pro_ID) 
                AND (Print_Status = 1) 
                AND (M_Code.Batch_No IS NULL OR M_Code.Batch_No = '')
                AND (ISNULL(M_Code.ScrapeFlag, 0) = 0) 
                AND (DispatchFlag = 1) 
                AND (ReceiveFlag = 1)
          )) > 0)
        GROUP BY Pro_Reg.Comp_ID, Pro_Reg.Pro_ID, Pro_Reg.Pro_Name, Pro_Reg.BatchSize, Comp_Reg.Comp_Name
    END
    ELSE
    BEGIN
        SELECT 
            Pro_Reg.Comp_ID, 
            Pro_Reg.Pro_ID, 
            Pro_Reg.Pro_Name,
            Pro_Reg.BatchSize,
            (SELECT TOP 1 PlanMasterPeriod 
             FROM M_ServiceSubscription WITH (NOLOCK)
             WHERE Pro_ID = Pro_Reg.Pro_ID 
               AND (Service_ID = @Service_ID OR @Service_ID IS NULL)
               AND (IsDelete = 0 OR IsDelete IS NULL)
             ORDER BY EntryDate DESC) AS PlanMasterPeriod,
            (SELECT TOP 1 tp.Batch_No 
             FROM T_Pro tp WITH (NOLOCK) 
             WHERE tp.Pro_ID = Pro_Reg.Pro_ID 
             ORDER BY tp.Entry_Date DESC, tp.Row_ID DESC) AS Batch_No,
            (SELECT TOP 1 tp.MRP 
             FROM T_Pro tp WITH (NOLOCK) 
             WHERE tp.Pro_ID = Pro_Reg.Pro_ID 
             ORDER BY tp.Entry_Date DESC, tp.Row_ID DESC) AS MRP,
            (SELECT TOP 1 tp.Series_Limit 
             FROM T_Pro tp WITH (NOLOCK) 
             WHERE tp.Pro_ID = Pro_Reg.Pro_ID 
             ORDER BY tp.Entry_Date DESC, tp.Row_ID DESC) AS Series_Limit
        FROM Comp_Reg WITH (NOLOCK)
        INNER JOIN Pro_Reg WITH (NOLOCK) ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID 
        WHERE (Pro_Reg.Comp_ID = @Comp_ID) 
          AND EXISTS (
              SELECT 1 
              FROM M_ServiceSubscription ms WITH (NOLOCK)
              WHERE ms.Pro_ID = Pro_Reg.Pro_ID 
                AND (ms.Service_ID = @Service_ID OR @Service_ID IS NULL)
                AND (ms.IsDelete = 0 OR ms.IsDelete IS NULL)
          )
          AND (CONVERT(INT, (
              SELECT COUNT(Pro_ID) AS Expr1
              FROM M_Code M_Code WITH (NOLOCK)
              WHERE (Pro_ID = Pro_Reg.Pro_ID) 
                AND (Print_Status = 1) 
                AND (M_Code.Batch_No IS NULL OR M_Code.Batch_No = '')
                AND (ISNULL(M_Code.ScrapeFlag, 0) = 0) 
                AND (DispatchFlag = 1) 
                AND (ReceiveFlag = 1)
          )) > 0)
        GROUP BY Pro_Reg.Comp_ID, Pro_Reg.Pro_ID, Pro_Reg.Pro_Name, Pro_Reg.BatchSize, Comp_Reg.Comp_Name
    END
END
GO
