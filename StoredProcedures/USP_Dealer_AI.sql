CREATE PROCEDURE [dbo].[USP_Dealer_AI]
    @Mode NVARCHAR(20),
    @ID INT = NULL,
    @Dealer_Name NVARCHAR(200) = NULL,
    @Dealer_Location NVARCHAR(500) = NULL,
    @Contact_Information NVARCHAR(200) = NULL,
    @Invoice_Number NVARCHAR(100) = NULL,
    @Latitude NVARCHAR(50) = NULL,
    @Longitude NVARCHAR(50) = NULL,
    @Comp_ID NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Mode = 'INSERT'
    BEGIN
        INSERT INTO [M_Dealer_AI] (
            [Dealer_Name], 
            [Dealer_Location], 
            [Contact_Information], 
            [Invoice_Number], 
            [Latitude], 
            [Longitude], 
            [Comp_ID]
        )
        VALUES (
            @Dealer_Name, 
            @Dealer_Location, 
            @Contact_Information, 
            @Invoice_Number, 
            @Latitude, 
            @Longitude, 
            @Comp_ID
        );
        
        SELECT SCOPE_IDENTITY() AS NewID;
    END
    ELSE IF @Mode = 'UPDATE'
    BEGIN
        UPDATE [M_Dealer_AI]
        SET [Dealer_Name] = ISNULL(@Dealer_Name, [Dealer_Name]),
            [Dealer_Location] = ISNULL(@Dealer_Location, [Dealer_Location]),
            [Contact_Information] = ISNULL(@Contact_Information, [Contact_Information]),
            [Invoice_Number] = ISNULL(@Invoice_Number, [Invoice_Number]),
            [Latitude] = ISNULL(@Latitude, [Latitude]),
            [Longitude] = ISNULL(@Longitude, [Longitude])
        WHERE [ID] = @ID AND [Comp_ID] = @Comp_ID;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    ELSE IF @Mode = 'DELETE'
    BEGIN
        UPDATE [M_Dealer_AI]
        SET [isdelete] = 1
        WHERE [ID] = @ID AND [Comp_ID] = @Comp_ID;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    ELSE IF @Mode = 'SELECT'
    BEGIN
        SELECT 
            [ID],
            [Dealer_Name],
            [Dealer_Location],
            [Contact_Information],
            [Invoice_Number],
            [Latitude],
            [Longitude],
            [Comp_ID],
            [entry_date]
        FROM [M_Dealer_AI]
        WHERE [Comp_ID] = @Comp_ID AND [isdelete] = 0
        ORDER BY [entry_date] DESC;
    END
END
GO
