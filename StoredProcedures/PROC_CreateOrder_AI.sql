CREATE OR ALTER PROCEDURE [dbo].[PROC_CreateOrder_AI]
    @UserId INT,
    @AddressId INT,
    @PaymentMethod NVARCHAR(50),
    @Comp_id NVARCHAR(50),
    @SpecialInstructions NVARCHAR(MAX),
    @ItemsXml XML,
    @OrderId INT OUTPUT,
    @OrderStatus NVARCHAR(50) OUTPUT,
    @TotalAmount DECIMAL(18, 2) OUTPUT,
    @EstimatedDelivery DATE OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Total DECIMAL(18, 2) = 0;
        DECLARE @CreditLimit DECIMAL(18, 2) = 0;
        DECLARE @CurrentLimit DECIMAL(18, 2) = 0;
        DECLARE @ConsumerId INT;
        DECLARE @DiscountAmount DECIMAL(18, 2) = 0;
        DECLARE @DiscountPercent DECIMAL(5,2) = 0;

        -- Get M_consumerId from UserId
        SELECT TOP 1 @ConsumerId = M_Consumerid 
        FROM M_Consumer 
        WHERE User_ID = (SELECT User_ID FROM M_Consumer WHERE M_Consumerid = @UserId);

        -- Get current credit limit
        SELECT TOP 1 
            @CreditLimit = total_credit_limit,
            @CurrentLimit = current_credit_limit
        FROM dealer_credit_limits
        WHERE M_consumerId = @UserId AND Comp_id = @Comp_id
        ORDER BY last_updated_at DESC;

        -- Calculate total amount from XML
        SELECT @Total = SUM(
            x.Item.value('(Price)[1]', 'DECIMAL(18,2)') * 
            x.Item.value('(Quantity)[1]', 'INT')
        )
        FROM @ItemsXml.nodes('/Items/Item') AS x(Item);

        -- Get applicable discount slab based on total
        SELECT TOP 1 @DiscountPercent = DiscountPercent
        FROM Company_DiscountSlabs
        WHERE Comp_Id = @Comp_id AND OnTotalAmount <= @Total
        ORDER BY OnTotalAmount DESC;

        -- Calculate discount amount
        SET @DiscountAmount = (@Total * @DiscountPercent) / 100.0;

        -- Validate credit limit (before discount is applied)
        IF @CurrentLimit < @Total
        BEGIN
            SET @OrderStatus = 'Failed: Insufficient Credit Limit';
            SET @TotalAmount = @Total;
            SET @EstimatedDelivery = NULL;
            RETURN;
        END

        -- Insert into Orders table
        INSERT INTO Orders (
            UserId, AddressId, TotalAmount, PaymentMethod,
            SpecialInstructions, OrderStatus, CreatedDate, Comp_Id, DiscountAmount
        )
        VALUES (
            @UserId, @AddressId, 0, @PaymentMethod,
            @SpecialInstructions, 'Pending', GETDATE(), @Comp_id, @DiscountAmount
        );

        SET @OrderId = SCOPE_IDENTITY();

        -- Insert into Order_Items
        INSERT INTO Order_Items (OrderId, ProductId, VariantId, Quantity, UnitPrice)
        SELECT
            @OrderId,
            x.Item.value('(ProductId)[1]', 'INT'),
            x.Item.value('(VariantId)[1]', 'INT'),
            x.Item.value('(Quantity)[1]', 'INT'),
            x.Item.value('(Price)[1]', 'DECIMAL(18,2)')
        FROM @ItemsXml.nodes('/Items/Item') AS x(Item);

        -- Reduce stock quantity for the products
        ;WITH OrderItemsCTE AS (
            SELECT 
                x.Item.value('(ProductId)[1]', 'INT') AS ProductId,
                x.Item.value('(Quantity)[1]', 'INT') AS Quantity
            FROM @ItemsXml.nodes('/Items/Item') AS x(Item)
        )
        UPDATE p
        SET p.StockQuantity = CAST(CAST(ISNULL(NULLIF(p.StockQuantity, ''), '0') AS INT) - oi.Quantity AS NVARCHAR(50))
        FROM Products_catalog_Details p
        INNER JOIN (
            SELECT ProductId, SUM(Quantity) AS Quantity
            FROM OrderItemsCTE
            GROUP BY ProductId
        ) oi ON p.Row_Id = oi.ProductId;

        -- Recalculate total from Order_Items
        SELECT @Total = SUM(UnitPrice * Quantity)
        FROM Order_Items
        WHERE OrderId = @OrderId;

        -- Recalculate discount again just to ensure consistency (optional)
        SET @DiscountAmount = (@Total * @DiscountPercent) / 100.0;

        -- Update Orders table with final total and discount
        UPDATE Orders
        SET 
            TotalAmount = @Total,
            DiscountAmount = @DiscountAmount
        WHERE OrderId = @OrderId;

        -- Update credit limit (without discount, based on full order amount)
        DECLARE @NewCurrentLimit DECIMAL(18, 2) = @CurrentLimit - @Total + @DiscountAmount;

        INSERT INTO dealer_credit_limits (
            M_consumerId,
            Comp_id,
            total_credit_limit,
            current_credit_limit,
            last_updated_at,
            remarks
        )
        VALUES (
            @UserId,
            @Comp_id,
            @CreditLimit,
            @NewCurrentLimit,
            GETDATE(),
            'Order Placed'
        );

        -- Final output
        SET @OrderStatus = 'Pending';
        SET @TotalAmount = @Total;
        SET @EstimatedDelivery = DATEADD(DAY, 5, GETDATE());

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
