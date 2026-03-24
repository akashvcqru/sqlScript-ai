-- =============================================
-- Procedure: USP_UpdateServiceSettingTracTrash_AI
-- Description: Update Track & Trace related fields in codeassign_tractrac
-- =============================================
IF OBJECT_ID('USP_UpdateServiceSettingTracTrash_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_UpdateServiceSettingTracTrash_AI
GO

CREATE PROCEDURE USP_UpdateServiceSettingTracTrash_AI
    @SST_Id               BIGINT,
    @TrackTrace_ID        BIGINT = NULL,
    @Batch_No             VARCHAR(100) = NULL,
    @Dealer_Name          NVARCHAR(150) = NULL,
    @Dealer_Location      NVARCHAR(150) = NULL,
    @Contact_Information  NVARCHAR(150) = NULL,
    @Invoice_Number       NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Update based on TrackTrace_ID if provided, otherwise fall back to SST_Id
        IF @TrackTrace_ID IS NOT NULL AND @TrackTrace_ID > 0
        BEGIN
            UPDATE codeassign_tractrac
            SET Batch_No = ISNULL(@Batch_No, Batch_No),
                Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                Contact_Information = ISNULL(@Contact_Information, Contact_Information),
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number)
            WHERE ID = @TrackTrace_ID;
        END
        ELSE IF @SST_Id IS NOT NULL AND @SST_Id > 0
        BEGIN
            UPDATE codeassign_tractrac
            SET Batch_No = ISNULL(@Batch_No, Batch_No),
                Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                Contact_Information = ISNULL(@Contact_Information, Contact_Information),
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number)
            WHERE SST_Id = @SST_Id;
        END
        ELSE
        BEGIN
             SELECT 0 AS success, 'No valid identifier (SST_Id or TrackTrace_ID) provided.' AS message;
             RETURN;
        END

        IF @@ROWCOUNT > 0
        BEGIN
            SELECT 1 AS success, 'Track & Trace settings updated successfully.' AS message;
        END
        ELSE
        BEGIN
            SELECT 0 AS success, 'No record found to update.' AS message;
        END
    END TRY
    BEGIN CATCH
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
