CREATE OR ALTER PROCEDURE [dbo].[USP_GetMasterCodeReport_AI]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        MasterCode,
        Pro_ID,
        MRP,
        Mfd_Date,
        Exp_Date,
        Batch_No,
        SeriesStart,
        SeriesEnd,
        EntryDate,
        Dealer_Name,
        Dealer_Location,
        Contact_Information,
        Dispatch_Date,
        Invoice_Number
    FROM codeassign_tractrac
    ORDER BY EntryDate DESC;
END
GO
