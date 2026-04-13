USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-10
-- Description: Get Courier Dispatch List with pagination and search
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCourierDispatchList_AI]
    @Comp_ID NVARCHAR(50),
    @CourierName NVARCHAR(100),
    @Offset INT,
    @Limit INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Courier_Disp_ID, Courier_ID,
        (SELECT Courier_Name FROM Courier_Master WHERE Courier_ID = Courier_Dispatch_Master.Courier_ID) as Courier_Name,
        (SELECT Courier_Mobile FROM Courier_Master WHERE Courier_ID = Courier_Dispatch_Master.Courier_ID) as Courier_Mobile, 
        Comp_ID,
        (SELECT Comp_Name FROM Comp_Reg WHERE Comp_ID = Courier_Dispatch_Master.Comp_ID) as Comp_Name, 
        Tracking_No, Dispatch_Date, Expected_Date, Dispatch_Location,
        ISNULL(Received_Flag, 0) AS Flag,
        (CASE 
            WHEN ISNULL(Received_Flag, 0) = 0 THEN 'Pending' 
            WHEN Received_Flag = 1 THEN 'Received' 
            WHEN Received_Flag = 2 THEN 'Received with scrap' 
            ELSE 'Not Received' 
        END) AS Status, 
        Entry_Date,
        (SELECT SUM(Qty) FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = Courier_Dispatch_Master.Courier_Disp_ID) as Qty,
        (SELECT TOP 1 Pro_ID FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = Courier_Dispatch_Master.Courier_Disp_ID) as Pro_ID,
        (SELECT TOP 1 Series_From FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = Courier_Dispatch_Master.Courier_Disp_ID) as Series_From,
        (SELECT TOP 1 Series_To FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = Courier_Dispatch_Master.Courier_Disp_ID) as Series_To,
        (SELECT TOP 1 Label_Code FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = Courier_Dispatch_Master.Courier_Disp_ID) as Label_Code,
        (SELECT TOP 1 Label_Name FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = Courier_Dispatch_Master.Courier_Disp_ID) as Label_Name,
        COUNT(*) OVER() AS TotalRecords
    FROM Courier_Dispatch_Master 
    WHERE Comp_ID = @Comp_ID 
    AND (
        @CourierName IS NULL OR @CourierName = '' OR 
        (SELECT Courier_Name FROM Courier_Master WHERE Courier_ID = Courier_Dispatch_Master.Courier_ID) LIKE @CourierName
    )
    ORDER BY Entry_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
