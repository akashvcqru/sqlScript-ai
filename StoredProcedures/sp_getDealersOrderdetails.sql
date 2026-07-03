SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE OR ALTER PROCEDURE [dbo].[sp_getDealersOrderdetails]      
    @Start_Date DATETIME = NULL,                
    @End_Date DATETIME = NULL,  
    @compId VARCHAR(50) = NULL,
	@OrderStatus VARCHAR(50) = NULL,
    @UserName VARCHAR(100) = NULL
AS  
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #payTest;
    
     select iip.InvoiceID , sum(AmountPaid) AS AmountPaid into #payTest from InvoicePayments iip
     inner join Invoices iic on iic.InvoiceID = iip.InvoiceID
     inner join Orders iio on iio.OrderId = iic.OrderID where iio.Comp_Id = @compId group by iip.InvoiceID


    ;WITH InvoiceCTE AS (
        SELECT 
            InvoiceID,
            OrderID,
			TotalAmount,
			InvoiceNumber,
            ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY InvoiceID DESC) AS rn
        FROM Invoices
    )

    SELECT 
	   mc.ConsumerName AS [Dealer Name],
      mc.MobileNo,
        mc.M_Consumerid AS DealerId,
        o.OrderId AS OrderId,
        CASE 
            WHEN ISNULL(ipp.AmountPaid, 0) = 0 THEN 'Unpaid'
			WHEN ipp.AmountPaid >= ic.TotalAmount AND ISNULL(ic.TotalAmount, 0) > 0 THEN 'Paid'
            WHEN ipp.AmountPaid > 0 THEN 'Partial pay'
            ELSE 'Unpaid'
        END AS PayStatus,
		CASE 
			WHEN ic.InvoiceNumber IS NULL OR LTRIM(RTRIM(ic.InvoiceNumber)) = '' THEN ''
			ELSE  ic.InvoiceNumber 
		END as FilePath,
        o.TotalAmount,
		ipp.AmountPaid as PartialPaidAmount,
		ic.TotalAmount as InvoiceValue,
		o.OrderStatus,
		(o.TotalAmount - ISNULL(o.DiscountAmount, 0)) AS AmountAfterDiscount,
		CASE
			WHEN o.TotalAmount = 0 THEN '0%'
			ELSE 
				RTRIM(
					REPLACE(
						STR(
							ROUND((ISNULL(o.DiscountAmount,0)/NULLIF(o.TotalAmount,0))*100, 2), 
							10, 2
						), 
						'.00', ''
					)
				) + '%'
		END AS DiscountPercent,
        o.CreatedDate AS CreatedAt,
        ISNULL(ic.InvoiceID, 0) AS InvoiceID,
        a.AddressLine1 AS Address1,
        o.SpecialInstructions AS OrderNote,
        o.OrderStatus AS PermStatus
    FROM Orders o
    left JOIN User_Address a ON a.AddressId = o.AddressId
    left JOIN M_Consumer mc ON mc.M_Consumerid = o.UserId
    LEFT JOIN InvoiceCTE ic ON ic.OrderID = o.OrderId AND ic.rn = 1
	left join #payTest ipp on ipp.InvoiceID = ic.InvoiceID
    WHERE 
        (@compId IS NULL OR o.Comp_id = @compId)
        AND (@UserName IS NULL OR mc.ConsumerName LIKE '%' + @UserName + '%')
        AND (@Start_Date IS NULL OR LTRIM(RTRIM(@Start_Date)) = '' OR o.CreatedDate >= @Start_Date)
		AND (@OrderStatus IS NULL OR o.OrderStatus = @OrderStatus)
        AND (@End_Date IS NULL OR LTRIM(RTRIM(@End_Date)) = '' OR o.CreatedDate <= @End_Date)
		
	order by o.OrderId desc;
END
GO
