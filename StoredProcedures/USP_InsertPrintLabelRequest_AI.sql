CREATE PROCEDURE [dbo].[USP_InsertPrintLabelRequest_AI]
    @Pro_ID NVARCHAR(50),
    @Qty NUMERIC(18, 0),
    @Label_Code NVARCHAR(50),
    @Entry_Date DATETIME,
    @Flag INT = 0,
    @Tracking_No NVARCHAR(MAX),
    @Price NUMERIC(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [M_Label_Request]
        ([Pro_ID], [Qty], [Label_Code], [Entry_Date], [Flag], [Tracking_No], [Request_Price], [Price], ProductioUnit, Channels) 
    VALUES 
        (@Pro_ID, @Qty, @Label_Code, @Entry_Date, @Flag, @Tracking_No, @Price, @Price, NULL, NULL);
END
GO
