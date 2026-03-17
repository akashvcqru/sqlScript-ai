CREATE PROCEDURE [dbo].[USP_GetPrintLabelRequestList_AI]
    @Comp_ID NVARCHAR(50),
    @Tracking_No NVARCHAR(100) = NULL,
    @Pro_ID NVARCHAR(50) = NULL,
    @Status NVARCHAR(50) = NULL,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

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
            WHEN M_Label_Request.Flag = '-2' THEN 'Canceled' 
         END) AS RequestStatusFlag,
        M_Label_Request.Tracking_No,
        M_Label_Request.Flag 
    FROM M_Label_Request 
    INNER JOIN M_Label ON M_Label_Request.Label_Code = M_Label.Label_Code 
    INNER JOIN Pro_Reg ON M_Label_Request.Pro_ID = Pro_Reg.Pro_ID 
    WHERE Pro_Reg.Comp_ID = @Comp_ID 
      AND (@Tracking_No IS NULL OR M_Label_Request.Tracking_No LIKE '%' + @Tracking_No + '%')
      AND (@Pro_ID IS NULL OR @Pro_ID = '' OR Pro_Reg.Pro_ID = @Pro_ID)
      AND (@Status IS NULL OR @Status = '' OR 
           (CASE 
                WHEN M_Label_Request.Flag = '0' THEN 'Pending' 
                WHEN M_Label_Request.Flag = '-1' THEN 'Rejected' 
                WHEN M_Label_Request.Flag = '1' THEN 'Printed' 
                WHEN M_Label_Request.Flag = '-2' THEN 'Canceled' 
            END) = @Status)
      AND (@DateFrom IS NULL OR CONVERT(DATE, M_Label_Request.Entry_Date) >= CONVERT(DATE, @DateFrom))
      AND (@DateTo IS NULL OR CONVERT(DATE, M_Label_Request.Entry_Date) <= CONVERT(DATE, @DateTo))
    ORDER BY M_Label_Request.Entry_Date DESC;
END
GO
