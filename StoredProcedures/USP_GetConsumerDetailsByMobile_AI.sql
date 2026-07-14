CREATE OR ALTER PROCEDURE [dbo].[USP_GetConsumerDetailsByMobile_AI]
    @MobileNo NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 
        ConsumerName,
        Email,
        City,
        state           AS State,
        PinCode,
        Address,
        SellerName,
        Vrkabel_User_Type,
        designation,
        shop_name
    FROM M_Consumer 
    WHERE right(MobileNo, 10) = right(@MobileNo, 10)
    AND IsDelete = 0
    ORDER BY Entry_Date DESC;
END
GO
