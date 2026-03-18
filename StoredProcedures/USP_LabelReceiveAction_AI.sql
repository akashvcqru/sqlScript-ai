CREATE OR ALTER PROCEDURE [dbo].[USP_LabelReceiveAction_AI]
    @Courier_Disp_ID NVARCHAR(50),
    @Flag INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. If Flag is 1 (Receive), 2 (Receive with scrap), or -1 (Reject), update M_code flags
        IF @Flag IN (1, 2, -1)
        BEGIN
            -- This procedure updates M_code ReceiveFlag based on the dispatch ID
            EXEC dbo.UpdateM_code_ReceiveFlag @Courier_Disp_ID;
        END

        -- 2. Update Courier_Dispatch_Master
        UPDATE [Courier_Dispatch_Master]
        SET [Received_Date] = GETDATE(),
            [Received_Flag] = @Flag,
            [Man_Reason] = NULL
        WHERE [Courier_Disp_ID] = @Courier_Disp_ID;

        -- 3. If Flag is 2 (Receive with scrap), return Series info for redirection
        IF @Flag = 2
        BEGIN
            SELECT TOP 1 
                Series_From, 
                (SELECT TOP 1 Series_To FROM Courier_Disp_ProInfo WHERE Courier_Disp_ID = @Courier_Disp_ID ORDER BY Row_ID DESC) AS Series_To,
                Pro_ID 
            FROM Courier_Disp_ProInfo 
            WHERE Courier_Disp_ID = @Courier_Disp_ID 
            ORDER BY Row_ID ASC;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO
