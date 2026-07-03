CREATE OR ALTER PROCEDURE [dbo].[PROC_CreateReOrder_AI]
    @OldOrderId INT,
    @SpecialInstructions NVARCHAR(MAX),
    @NewOrderId INT OUTPUT,
    @NewOrderStatus NVARCHAR(50) OUTPUT,
    @NewTotalAmount DECIMAL(18,2) OUTPUT,
    @NewEstimatedDelivery DATE OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Declare variables to hold old order data
        DECLARE 
            @UserId INT,
            @AddressId INT,
            @PaymentMethod NVARCHAR(50),
            @ItemsXml XML,
            @Compid VARCHAR(20);

        -- Fetch order details
        SELECT 
            @UserId = o.UserId,
            @AddressId = o.AddressId,
            @PaymentMethod = o.PaymentMethod,
            @Compid = o.Comp_Id
        FROM Orders o
        WHERE o.OrderId = @OldOrderId;

        IF @UserId IS NULL
        BEGIN
            SET @NewOrderStatus = 'Failed: Old order not found';
            SET @NewOrderId = NULL;
            SET @NewTotalAmount = 0;
            SET @NewEstimatedDelivery = NULL;
            RETURN;
        END

        -- Check if any product is missing, inactive, deleted, or has insufficient stock
        DECLARE @FailedReason NVARCHAR(150) = NULL;

        -- 1. Check if any product in the old order is missing from Products_catalog_Details
        SELECT TOP 1 @FailedReason = 'Not found: Product ID ' + CAST(oi.ProductId AS NVARCHAR(15))
        FROM Order_Items oi
        LEFT JOIN Products_catalog_Details p ON oi.ProductId = p.Row_Id
        WHERE oi.OrderId = @OldOrderId AND p.Row_Id IS NULL;

        -- 2. Check if any product in the old order is inactive or deleted
        IF @FailedReason IS NULL
        BEGIN
            SELECT TOP 1 @FailedReason = 'Unavailable: ' + LEFT(LTRIM(RTRIM(p.ProductName)), 30)
            FROM Order_Items oi
            INNER JOIN Products_catalog_Details p ON oi.ProductId = p.Row_Id
            WHERE oi.OrderId = @OldOrderId
              AND (p.Isactive = 0 OR p.Isdelete = 1);
        END

        -- 3. Check if any product in the old order has insufficient stock
        IF @FailedReason IS NULL
        BEGIN
            SELECT TOP 1 @FailedReason = 'Low stock: ' + LEFT(LTRIM(RTRIM(p.ProductName)), 30)
            FROM Order_Items oi
            INNER JOIN Products_catalog_Details p ON oi.ProductId = p.Row_Id
            WHERE oi.OrderId = @OldOrderId
              AND oi.Quantity > TRY_CAST(ISNULL(NULLIF(p.StockQuantity, ''), '0') AS INT);
        END

        -- If any validation failed, return appropriate error message
        IF @FailedReason IS NOT NULL
        BEGIN
            SET @NewOrderStatus = 'Failed: ' + LEFT(@FailedReason, 42);
            SET @NewOrderId = NULL;
            SET @NewTotalAmount = 0;
            SET @NewEstimatedDelivery = NULL;
            RETURN;
        END

        -- Generate ItemsXml from existing Order_Items
        SET @ItemsXml = (
            SELECT
                ProductId,
                VariantId,
                Quantity,
                UnitPrice AS Price
            FROM Order_Items
            WHERE OrderId = @OldOrderId
            FOR XML PATH('Item'), ROOT('Items')
        );

        -- Call PROC_CreateOrder_AI
        EXEC [dbo].[PROC_CreateOrder_AI]
            @UserId = @UserId,
            @AddressId = @AddressId,
            @PaymentMethod = @PaymentMethod,
            @SpecialInstructions = @SpecialInstructions,
            @Comp_id = @Compid,
            @ItemsXml = @ItemsXml,
            @OrderId = @NewOrderId OUTPUT,
            @OrderStatus = @NewOrderStatus OUTPUT,
            @TotalAmount = @NewTotalAmount OUTPUT,
            @EstimatedDelivery = @NewEstimatedDelivery OUTPUT;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
