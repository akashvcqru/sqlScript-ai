CREATE OR ALTER PROCEDURE [dbo].[USP_GetLabelReceiveList_AI]
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  
        CDM.Courier_Disp_ID,
        CDM.Courier_ID,
        CM.Courier_Name,
        CM.Courier_Mobile,
        CDM.Tracking_No,
        CDM.Dispatch_Date,
        CDM.Expected_Date,
        CDM.Dispatch_Location,
        
        ISNULL(CDM.Received_Flag, 0) AS Flag,

        CASE 
            WHEN ISNULL(CDM.Received_Flag, 0) = 0 THEN '----'
            WHEN CDM.Received_Flag = 1 THEN 'Received'
            WHEN CDM.Received_Flag = 2 THEN 'Received with scrap'
            ELSE 'Not Received'
        END AS Status,

        CDM.Entry_Date,

        SUM(ISNULL(CDP.Qty, 0)) AS Qty

    FROM Courier_Dispatch_Master CDM

    LEFT JOIN Courier_Master CM 
        ON CM.Courier_ID = CDM.Courier_ID

    LEFT JOIN Courier_Disp_ProInfo CDP 
        ON CDP.Courier_Disp_ID = CDM.Courier_Disp_ID

    WHERE 
        (@Comp_ID = '' OR CDM.Comp_ID = @Comp_ID)

    GROUP BY
        CDM.Courier_Disp_ID,
        CDM.Courier_ID,
        CM.Courier_Name,
        CM.Courier_Mobile,
        CDM.Tracking_No,
        CDM.Dispatch_Date,
        CDM.Expected_Date,
        CDM.Dispatch_Location,
        CDM.Received_Flag,
        CDM.Entry_Date

    ORDER BY CDM.Entry_Date DESC;
END
GO
