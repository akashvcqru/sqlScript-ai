CREATE OR ALTER PROCEDURE [dbo].[USP_GetPrintLabelRequestList_AI]
    @Comp_ID NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    SELECT 
        M_Label_Request.Row_ID, 
        CONVERT(NVARCHAR, M_Label_Request.Entry_Date, 107) AS RequestDate,  
        Pro_Reg.Pro_Name, 
        M_Label.Label_Name AS LabelType, 
        M_Label.Label_Size, 
        M_Label.Label_Prise,
        M_Label_Request.Qty AS RequestedLabels,
        (CASE 
            WHEN M_Label_Request.Flag = '0' THEN 'Pending' 
            WHEN M_Label_Request.Flag = '-1' THEN 'Rejected' 
            WHEN M_Label_Request.Flag = '1' THEN 'Printed' 
            WHEN M_Label_Request.Flag = '2' THEN 'Canceled' 
         END) AS RequestStatusFlag,
        M_Label_Request.Tracking_No,
        M_Label_Request.Flag,
        M_Label_Request.Pro_ID,
        Pro_Reg.Comp_ID,
        (SELECT Comp_Name FROM Comp_Reg WHERE Comp_ID = Pro_Reg.Comp_ID) AS Comp_Name,
        COUNT(*) OVER() AS TotalRecords
    FROM M_Label_Request 
    LEFT JOIN M_Label ON M_Label_Request.Label_Code = M_Label.Label_Code 
    LEFT JOIN Pro_Reg ON M_Label_Request.Pro_ID = Pro_Reg.Pro_ID 
    WHERE LTRIM(RTRIM(Pro_Reg.Comp_ID)) = LTRIM(RTRIM(@Comp_ID))
      AND Pro_Reg.Comp_ID IS NOT NULL
    ORDER BY M_Label_Request.Entry_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
