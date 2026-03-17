CREATE PROCEDURE [dbo].[USP_GetLabelReceiveList_AI]
    @Row_ID INT,
    @Page INT = 1,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @Limit;
    DECLARE @Tracking_No NVARCHAR(100);

    -- 1. Find the Tracking_No for the given Row_ID
    SELECT @Tracking_No = Tracking_No 
    FROM M_Label_Request 
    WHERE Row_ID = @Row_ID;

    -- 2. Fetch dispatch details linked to this Tracking_No
    SELECT 
        cdpi.Courier_Disp_ID, 
        pr.Pro_Name, 
        cdpi.Label_Code, 
        cdpi.Label_Name, 
        cdpi.Series_From, 
        cdpi.Series_To, 
        cdpi.Qty,
        COUNT(*) OVER() AS TotalRecords
    FROM Courier_Dispatch_Master cdm
    INNER JOIN Courier_Disp_ProInfo cdpi ON cdm.Courier_Disp_ID = cdpi.Courier_Disp_ID
    INNER JOIN Pro_Reg pr ON cdpi.Pro_ID = pr.Pro_ID
    WHERE cdm.Tracking_No = @Tracking_No
    ORDER BY cdm.Entry_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO
