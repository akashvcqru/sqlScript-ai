CREATE OR ALTER PROCEDURE [dbo].[USP_GetMasterCodeReport_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        mastercode,
        Pro_ID,
        MRP,
        Mfd_Date,
        Exp_Date,
        Batch_No,
        SeriesStart,
        SeriesEnd,
        entry_date,
        Dealer_Name,
        Dealer_Location,
        Contact_Information,
        Dispatch_Date,
        Invoice_Number
    FROM codeassign_tractrac
    ORDER BY entry_date DESC;
END
GO
