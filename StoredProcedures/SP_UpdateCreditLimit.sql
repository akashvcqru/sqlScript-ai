CREATE OR ALTER PROCEDURE [dbo].[SP_UpdateCreditLimit]     
    @orderId VARCHAR(50) = NULL,
    @OrderStatus VARCHAR(50) = NULL
AS  
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalAmount DECIMAL(18,2), @UserId INT, @Comp_id varchar(20);

    -- Get TotalAmount and UserId from Orders
    SELECT TOP 1  
        @TotalAmount = TotalAmount - DiscountAmount, 
        @UserId = UserId ,
        @Comp_id = Comp_id 
    FROM orders 
    WHERE OrderId = @orderId;

    -- Get the most recent credit limit record for this user
    SELECT TOP 1 * 
    INTO #tempCredit 
    FROM dealer_credit_limits 
    WHERE M_Consumerid = @UserId and Comp_id = @Comp_id
    ORDER BY last_updated_at DESC;

    -- CASE 1: Order REJECTED or CANCELLED → Restore full order amount
    IF (@OrderStatus = 'Rejected' OR @OrderStatus = 'Cancelled' OR @OrderStatus = 'Canceled' OR @OrderStatus = 'Cancel' OR @OrderStatus = 'cancle')
    BEGIN
        INSERT INTO dealer_credit_limits (
            M_Consumerid, 
            Comp_id, 
            total_credit_limit, 
            current_credit_limit, 
            last_updated_at, 
            remarks
        )
        SELECT 
            M_Consumerid, 
            Comp_id, 
            total_credit_limit, 
            current_credit_limit + @TotalAmount, 
            GETDATE(), 
            'Credit limit restored after order rejection/cancellation'
        FROM #tempCredit;

        RETURN;
    END

    -------------------------------------------------------------
    -- CASE 2: Order DELIVERED → Add 2%
    -------------------------------------------------------------
    IF (@OrderStatus = 'Delivered')
    BEGIN
        INSERT INTO dealer_credit_limits (
            M_Consumerid, 
            Comp_id, 
            total_credit_limit, 
            current_credit_limit, 
            last_updated_at, 
            remarks
        )
        SELECT 
            M_Consumerid, 
            Comp_id, 
            total_credit_limit + (@TotalAmount * 0.02),
            current_credit_limit + (@TotalAmount * 0.02), 
            GETDATE(), 
            'Credit limit updated by 2% of order amount'
        FROM #tempCredit;

        RETURN;
    END

END;
GO
