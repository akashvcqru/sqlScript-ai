CREATE PROCEDURE [dbo].[PROC_DeleteFromCart_Multiple_AI]  
    @UserId INT,  
    @ProductIds VARCHAR(MAX),  
    @VarientId VARCHAR(MAX) = null,  
    @CartItemCount INT OUTPUT,  
    @CartTotalAmount DECIMAL(18, 2) OUTPUT  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    BEGIN TRY  
  
        -- Convert comma-separated product IDs  
        DECLARE @ProductIdTable TABLE (ProductId INT);  
  
        INSERT INTO @ProductIdTable (ProductId)  
        SELECT CAST(value AS INT)  
        FROM STRING_SPLIT(@ProductIds, ',')  
        WHERE ISNUMERIC(value) = 1;  
  
        -- If VariantId is provided → delete only that variant  
        IF (@VarientId IS NOT NULL AND LTRIM(RTRIM(@VarientId)) <> '')  
        BEGIN  
            DELETE FROM Cart  
            WHERE UserId = @UserId  
              AND ProductId IN (SELECT ProductId FROM @ProductIdTable)  
              AND VariantId = CAST(@VarientId AS INT);  
        END  
        ELSE  
        BEGIN  
            -- Delete all variants of product  
            DELETE FROM Cart  
            WHERE UserId = @UserId  
              AND ProductId IN (SELECT ProductId FROM @ProductIdTable);  
        END  
  
        -- Recalculate cart summary  
        SELECT   
            @CartItemCount = COUNT(*),  
            @CartTotalAmount = ISNULL(SUM(Quantity * UnitPrice), 0)  
        FROM Cart  
        WHERE UserId = @UserId;  
  
    END TRY  
    BEGIN CATCH  
        THROW;  
    END CATCH  
END
