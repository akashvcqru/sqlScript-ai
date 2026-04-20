CREATE OR ALTER PROCEDURE [dbo].[USP_GetConsumerDetailsByMobile_AI]
    @MobileNo NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 
        ConsumerName,
        City,
        state AS State,
        PinCode
    FROM M_Consumer 
    WHERE right(MobileNo, 10) = right(@MobileNo, 10)
    AND IsDelete = 0
    ORDER BY Entry_Date DESC;
END
GO
