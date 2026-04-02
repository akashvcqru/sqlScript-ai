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
    @Mobile               NVARCHAR(150) = NULL, -- Replaced @Contact_Information
    @Email                NVARCHAR(150) = NULL, -- Added @Email
    @Invoice_Number       NVARCHAR(50) = NULL,
    @BatchSize            INT = NULL,
    @MRP                  NUMERIC(18, 2) = NULL,
    @Mfd_Date             VARCHAR(50) = NULL,
    @Exp_Date             VARCHAR(50) = NULL,
    @DateFrom             VARCHAR(50) = NULL,
    @DateTo               VARCHAR(50) = NULL,
    @Comments             NVARCHAR(1000) = NULL,
    @Latitude             NVARCHAR(50) = NULL,
    @Longitude            NVARCHAR(50) = NULL,
    @SeriesStart          VARCHAR(100) = NULL,
    @SeriesEnd            VARCHAR(100) = NULL,
    @MasterCode           VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Update based on TrackTrace_ID if provided, otherwise fall back to SST_Id
        IF @TrackTrace_ID IS NOT NULL AND @TrackTrace_ID > 0
        BEGIN
            IF EXISTS (SELECT 1 FROM codeassign_tractrac WHERE ID = @TrackTrace_ID)
            BEGIN
                UPDATE codeassign_tractrac
                SET Batch_No = ISNULL(@Batch_No, Batch_No),
                    Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                    Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                    Mobile = ISNULL(@Mobile, Mobile),
                    Email = ISNULL(@Email, Email),
                    Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                    BatchSize = ISNULL(@BatchSize, BatchSize),
                    MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                    Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                    Latitude = ISNULL(@Latitude, Latitude),
                    Longitude = ISNULL(@Longitude, Longitude),
                    SeriesStart = ISNULL(@SeriesStart, SeriesStart),
                    SeriesEnd = ISNULL(@SeriesEnd, SeriesEnd),
                    mastercode = ISNULL(@MasterCode, mastercode)
                WHERE ID = @TrackTrace_ID;
            END
            ELSE
            BEGIN
                UPDATE M_ServiceSubscriptionTracTrace_MasterCodeLess
                SET Batch_No = ISNULL(@Batch_No, Batch_No),
                    Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                    Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                    Mobile = ISNULL(@Mobile, Mobile),
                    Email = ISNULL(@Email, Email),
                    Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                    BatchSize = ISNULL(@BatchSize, BatchSize),
                    MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                    Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                    Latitude = ISNULL(@Latitude, Latitude),
                    Longitude = ISNULL(@Longitude, Longitude),
                    SeriesStart = ISNULL(@SeriesStart, SeriesStart),
                    SeriesEnd = ISNULL(@SeriesEnd, SeriesEnd)
                WHERE ID = @TrackTrace_ID;
            END
        END
        ELSE IF @SST_Id IS NOT NULL AND @SST_Id > 0
        BEGIN
            IF EXISTS (SELECT 1 FROM codeassign_tractrac WHERE SST_Id = @SST_Id)
            BEGIN
                UPDATE codeassign_tractrac
                SET Batch_No = ISNULL(@Batch_No, Batch_No),
                    Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                    Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                    Mobile = ISNULL(@Mobile, Mobile),
                    Email = ISNULL(@Email, Email),
                    Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                    BatchSize = ISNULL(@BatchSize, BatchSize),
                    MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                    Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                    Latitude = ISNULL(@Latitude, Latitude),
                    Longitude = ISNULL(@Longitude, Longitude),
                    SeriesStart = ISNULL(@SeriesStart, SeriesStart),
                    SeriesEnd = ISNULL(@SeriesEnd, SeriesEnd),
                    mastercode = ISNULL(@MasterCode, mastercode)
                WHERE SST_Id = @SST_Id;
            END
            ELSE
            BEGIN
                UPDATE M_ServiceSubscriptionTracTrace_MasterCodeLess
                SET Batch_No = ISNULL(@Batch_No, Batch_No),
                    Dealer_Name = ISNULL(@Dealer_Name, Dealer_Name),
                    Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                    Mobile = ISNULL(@Mobile, Mobile),
                    Email = ISNULL(@Email, Email),
                    Invoice_Number = ISNULL(@Invoice_Number, Invoice_Number),
                    BatchSize = ISNULL(@BatchSize, BatchSize),
                    MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                    Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                    Latitude = ISNULL(@Latitude, Latitude),
                    Longitude = ISNULL(@Longitude, Longitude),
                    SeriesStart = ISNULL(@SeriesStart, SeriesStart),
                    SeriesEnd = ISNULL(@SeriesEnd, SeriesEnd)
                WHERE SST_Id = @SST_Id;
            END
        END
        
        -- Update Subscription Transaction Dates and Comments if SST_Id is available
        IF @SST_Id > 0
        BEGIN
            UPDATE M_ServiceSubscriptionTrans
            SET DateFrom = ISNULL(CASE WHEN ISDATE(@DateFrom)=1 THEN CAST(@DateFrom AS DATETIME) ELSE NULL END, DateFrom),
                DateTo = ISNULL(CASE WHEN ISDATE(@DateTo)=1 THEN CAST(@DateTo AS DATETIME) ELSE NULL END, DateTo),
                Comments = ISNULL(@Comments, Comments)
            WHERE SST_Id = @SST_Id;

            DECLARE @Actual_Pro_ID VARCHAR(50);
            DECLARE @Actual_Batch_No VARCHAR(100);
            
            SELECT @Actual_Pro_ID = Pro_ID, @Actual_Batch_No = Batch_No FROM codeassign_tractrac WHERE SST_Id = @SST_Id;
            
            IF @Actual_Pro_ID IS NULL -- Try the other table
            BEGIN
                SELECT @Actual_Pro_ID = Pro_ID, @Actual_Batch_No = Batch_No FROM M_ServiceSubscriptionTracTrace_MasterCodeLess WHERE SST_Id = @SST_Id;
            END

            IF @Actual_Pro_ID IS NOT NULL AND @Actual_Batch_No IS NOT NULL
            BEGIN
                UPDATE T_Pro
                SET MRP = ISNULL(@MRP, MRP),
                    Mfd_Date = ISNULL(CASE WHEN ISDATE(@Mfd_Date)=1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END, Mfd_Date),
                    Exp_Date = ISNULL(CASE WHEN ISDATE(@Exp_Date)=1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END, Exp_Date),
                    Comments = ISNULL(@Comments, Comments)
                WHERE Pro_ID = @Actual_Pro_ID AND Batch_No = @Actual_Batch_No;
            END
        END
        ELSE
        BEGIN
             SELECT 0 AS success, 'No valid identifier (SST_Id or TrackTrace_ID) provided.' AS message;
             RETURN;
        END

        SELECT 1 AS success, 'Track & Trace settings updated successfully.' AS message;
    END TRY
    BEGIN CATCH
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
