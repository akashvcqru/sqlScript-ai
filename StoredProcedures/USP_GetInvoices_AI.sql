CREATE PROCEDURE [dbo].[USP_GetInvoices_AI]      
    @UserId VARCHAR(20)   
AS      
BEGIN      
    select InvoiceID, InvoiceNumber AS [fileName], DealerID, TotalAmount, [Status], DueDate, CreatedAt, OrderID, nvoiceDate from Invoices where DealerID = @UserId  
END
