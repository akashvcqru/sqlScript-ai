USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[PROC_GetOrders]    Script Date: 4/2/2026 8:12:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[PROC_GetOrders_AI]
    @UserId INT,
    @OrderStatus NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- ✅ Order Details
    SELECT 
        o.OrderId AS Id,
        o.OrderId AS OrderId,
        'ORD-' + RIGHT('000' + CAST(o.OrderId AS VARCHAR), 3) AS OrderNumber,
        o.OrderStatus AS OrderStatus,
        o.TotalAmount,
        COUNT(oi.OrderItemId) AS ItemCount,
        o.CreatedDate AS CreatedAt,
        ii.DueDate, 
        ISNULL(ii.InvoiceNumber, 'NA') AS InvoicePath,

        (
            SELECT
                a.AddressId,
                a.FullName AS [Name],
                a.MobileNumber AS [Phone],
                a.AddressLine1,
                a.AddressLine2,
                a.City,
                a.State,
                a.PostalCode,
                a.IsDefault,
                a.Country
            FROM User_Address a
            WHERE a.AddressId = o.AddressId
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS DeliveryAddress,

        (
            SELECT 
                oi.ProductId,
                oi.VariantId,
                pee.ProductName AS ProductName,
				REPLACE(pee.ImagePath, '~', 'https://vcqru.com') AS ProductImg,
                oi.Quantity,
                oi.UnitPrice ,ppp.Color,ppp.Size
            FROM Order_Items oi
			left join Products_catalog_Details pee on pee.Row_Id = oi.ProductId left join Product_Variants ppp on ppp.VariantId = oi.VariantId 
            WHERE oi.OrderId = o.OrderId
            FOR JSON PATH
        ) AS Products,
        o.TotalAmount - ISNULL(o.DiscountAmount, 0) AS AmountAfterDiscount, o.SpecialInstructions 

    FROM Orders o
    INNER JOIN Order_Items oi ON o.OrderId = oi.OrderId
    LEFT JOIN Invoices ii ON ii.OrderID = o.OrderId
    WHERE o.UserId = @UserId 
          AND (@OrderStatus IS NULL OR @OrderStatus = '' OR o.OrderStatus = @OrderStatus)
    GROUP BY 
        o.OrderId, o.OrderStatus, o.TotalAmount, o.CreatedDate, o.AddressId, ii.DueDate, ii.InvoiceNumber, DiscountAmount,SpecialInstructions;

    -- ✅ Status Summary: Always return all 4 statuses even if 0
    SELECT 
        s.Status AS OrderStatus,
        ISNULL(COUNT(o.OrderId), 0) AS StatusCount
    FROM 
        (SELECT 'Pending' AS Status
         UNION ALL SELECT 'Processing'
         UNION ALL SELECT 'Delivered'
         UNION ALL SELECT 'Rejected') s
    LEFT JOIN Orders o ON o.OrderStatus = s.Status AND o.UserId = @UserId
    GROUP BY s.Status;
END
GO
