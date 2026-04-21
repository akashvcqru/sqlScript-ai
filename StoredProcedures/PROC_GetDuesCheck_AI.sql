CREATE PROCEDURE [dbo].[PROC_GetDuesCheck_AI]  
    @UserId INT  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    -- Temp table to store total paid amount per invoice  
    DROP TABLE IF EXISTS #PaySummary;  
  
    SELECT   
        InvoiceID,  
        SUM(AmountPaid) AS AmountPaid  
    INTO #PaySummary  
    FROM InvoicePayments  
    GROUP BY InvoiceID;  
  
    -- Final dues with due calculation  
    SELECT   
        i.InvoiceID,  
        i.DealerID,  
        i.OrderID,  
        i.TotalAmount,  
        ISNULL(p.AmountPaid, 0) AS AmountPaid,  
        (i.TotalAmount - ISNULL(p.AmountPaid, 0)) AS DueAmount,  
        i.Status,  
        i.DueDate,  
        i.CreatedAt  
    FROM Invoices i  
    LEFT JOIN #PaySummary p ON p.InvoiceID = i.InvoiceID  
    WHERE i.DealerID = @UserId  
    ORDER BY i.CreatedAt DESC;  
  
END
