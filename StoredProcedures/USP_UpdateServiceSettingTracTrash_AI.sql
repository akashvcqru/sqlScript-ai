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
    @Invoice_Number       NVARCHAR(50) = NULL,
    @BatchSize            INT = NULL,
    @MRP                  NUMERIC(18, 2) = NULL,
    @Mfd_Date             VARCHAR(50) = NULL,
    @Exp_Date             VARCHAR(50) = NULL,
    @DateFrom             VARCHAR(50) = NULL,
    @DateTo               VARCHAR(50) = NULL,
    @Comments             NVARCHAR(1000) = NULL
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
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                BatchSize = ISNULL(@BatchSize, BatchSize)
            WHERE ID = @TrackTrace_ID;
        END
        ELSE IF @SST_Id IS NOT NULL AND @SST_Id > 0
        BEGIN
            UPDATE codeassign_tractrac
            SET Batch_No = ISNULL(@Batch_No, Batch_No),
                Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                Contact_Information = ISNULL(@Contact_Information, Contact_Information),
                Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                BatchSize = ISNULL(@BatchSize, BatchSize),
                MRP = ISNULL(@MRP, MRP),
                Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date)
            WHERE SST_Id = @SST_Id;
        END
        
        -- Update Subscription Transaction Dates and Comments if SST_Id is available
        IF @SST_Id > 0
        BEGIN
            UPDATE M_ServiceSubscriptionTrans
            SET DateFrom = ISNULL(CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, DateFrom),
                DateTo = ISNULL(CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, DateTo),
                Comments = ISNULL(@Comments, Comments)
            WHERE SST_Id = @SST_Id;
        END

        -- Sync with T_Pro if Batch_No/Pro_ID is known for the assignment
        -- Note: This is more complex since one record in T_Pro might affect many assignments.
        -- But usually, people expect metadata updates to proparate if they changed the batch info.
        DECLARE @Actual_Pro_ID VARCHAR(50);
        DECLARE @Actual_Batch_No VARCHAR(100);
        SELECT @Actual_Pro_ID = Pro_ID, @Actual_Batch_No = Batch_No FROM codeassign_tractrac WHERE SST_Id = @SST_Id;

        IF @Actual_Pro_ID IS NOT NULL AND @Actual_Batch_No IS NOT NULL
        BEGIN
            UPDATE T_Pro
            SET MRP = ISNULL(@MRP, MRP),
                Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                Comments = ISNULL(@Comments, Comments)
            WHERE Pro_ID = @Actual_Pro_ID AND Batch_No = @Actual_Batch_No;
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
