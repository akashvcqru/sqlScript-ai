-- ============================================================
-- Stored Procedure: USP_InsertUpdateServiceSetting_AI
-- Purpose        : Insert or update generic service setting.
--                  Prevents duplicate settings and overlapping series ranges.
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertUpdateServiceSetting_AI]
    @Comp_ID VARCHAR(50),
    @Pro_ID VARCHAR(50),
    @Service_ID VARCHAR(50),
    @Subscribe_Id VARCHAR(50) = NULL,
    
    @WarrantyPeriod INT = NULL,
    @ReferralLimit INT = NULL,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @DueDate DATETIME = NULL,
    
    @IsCashConvert INT = NULL,
    @Frequency INT = NULL,
    @Points DECIMAL(18,2) = NULL,
    @AmtType VARCHAR(50) = NULL,
    @TotalLoyalty BIGINT = NULL,
    @Multiple INT = NULL,
    @Minval INT = NULL,
    @Maxval INT = NULL,
    @IsCash DECIMAL(18,2) = NULL,
    @Comments NVARCHAR(1000) = NULL,
    
    @ServiceType VARCHAR(50) = NULL,
    @Rules VARCHAR(100) = NULL,
    @MasterCodes BIGINT = NULL,
    @WinningCodes BIGINT = NULL,
    @WinCodes BIGINT = NULL,
    @Nth INT = NULL,
    @RewardsDistribution VARCHAR(50) = NULL,
    
    -- Referrals
    @IsReferral INT = NULL,
    @RefGiftReferral VARCHAR(50) = NULL,
    @RefGiftUsers VARCHAR(50) = NULL,
    @RefPointsReferral BIGINT = NULL,
    @RefPointsUsers BIGINT = NULL,
    @RefIsCashConvert INT = NULL,
    @RefIsCashReferral BIGINT = NULL,
    @RefIsCashUsers BIGINT = NULL,

    -- JSON Lists
    @GiftListJson NVARCHAR(MAX) = NULL,
    @TrackTraceJson NVARCHAR(MAX) = NULL,
    
    @StartOrder INT = NULL,
    @StartSeries INT = NULL,
    @EndOrder INT = NULL,
    @EndSeries INT = NULL,

    @EntryDate DATETIME = NULL,
    @DML CHAR(1) = 'I'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @NewSST_Id BIGINT;

        -- Ensure Subscribe_Id exists or retrieve it
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id 
            FROM M_ServiceSubscription 
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID;
        END

        IF @DML = 'I'
        BEGIN
            -- Check for duplicate/overlapping service settings on this product for the SAME Service_ID
            DECLARE @ConflictingSubId VARCHAR(50) = NULL;
            DECLARE @ConflictStart VARCHAR(50) = NULL, @ConflictEnd VARCHAR(50) = NULL;

            IF @StartOrder IS NOT NULL AND @StartSeries IS NOT NULL AND @EndOrder IS NOT NULL AND @EndSeries IS NOT NULL
            BEGIN
                SELECT TOP 1 
                    @ConflictingSubId = Subscribe_Id,
                    @ConflictStart = CONCAT(FORMAT(ISNULL(start_order, 0), '0000'), '-', FORMAT(ISNULL(start_series, 0), '0000')),
                    @ConflictEnd = CONCAT(FORMAT(ISNULL(end_order, 0), '0000'), '-', FORMAT(ISNULL(end_series, 0), '0000'))
                FROM M_ServiceSubscription WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID
                  AND Service_ID = @Service_ID
                  AND (Comp_ID = @Comp_ID OR @Comp_ID IS NULL)
                  AND Subscribe_Id <> ISNULL(@Subscribe_Id, '')
                  AND (
                      (
                          start_order IS NOT NULL AND start_series IS NOT NULL 
                          AND end_order IS NOT NULL AND end_series IS NOT NULL
                          AND (@StartOrder < end_order OR (@StartOrder = end_order AND @StartSeries <= end_series))
                          AND (start_order < @EndOrder OR (start_order = @EndOrder AND start_series <= @EndSeries))
                      )
                      OR
                      (
                          start_order IS NULL
                          AND EXISTS (
                              SELECT 1 FROM M_ServiceSubscriptionTrans sst WITH (NOLOCK) 
                              WHERE sst.Subscribe_Id = M_ServiceSubscription.Subscribe_Id
                          )
                      )
                  );

                IF @ConflictingSubId IS NOT NULL
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 0 AS success, 
                           CONCAT('Service setting already done for service ', @Service_ID, ' on product ', @Pro_ID, 
                                  CASE WHEN @ConflictStart IS NOT NULL AND @ConflictStart <> '0000-0000' 
                                       THEN CONCAT(' (overlaps with series ', @ConflictStart, ' to ', @ConflictEnd, ')') 
                                       ELSE '' END, '.') AS message;
                    RETURN;
                END
            END

            -- Logic to INSERT into M_ServiceSubscriptionTrans
            INSERT INTO M_ServiceSubscriptionTrans (
                Subscribe_Id,
                WarrantyPeriod, DateFrom, DateTo,
                IsCashConvert, Frequency, Points, AmtType, totalamont,
                Minval, Maxval, IsCash, Comments,
                IsReferral,
                Entry_Date, IsActive, IsDelete
            )
            VALUES (
                @Subscribe_Id,
                @WarrantyPeriod, @DateFrom, @DateTo,
                @IsCashConvert, @Frequency, @Points, @AmtType, @TotalLoyalty,
                @Minval, @Maxval, @IsCash, @Comments,
                @IsReferral,
                ISNULL(@EntryDate, GETDATE()), 1, 0
            );

            SET @NewSST_Id = SCOPE_IDENTITY();
            
            IF @GiftListJson IS NOT NULL
            BEGIN
                INSERT INTO M_ServiceSettingGifts (SST_Id, Gift_ID, GiftName, GiftCount)
                SELECT @NewSST_Id, Gift_ID, GiftName, GiftCount
                FROM OPENJSON(@GiftListJson)
                WITH (
                    Gift_ID VARCHAR(50) '$.Gift_ID',
                    GiftName NVARCHAR(255) '$.GiftName',
                    GiftCount INT '$.GiftCount'
                );
            END

            IF @TrackTraceJson IS NOT NULL
            BEGIN
                INSERT INTO M_ServiceSettingTrackTrace (SST_Id, Typeid, TypeName, Typevalue, Orderno, [Index])
                SELECT @NewSST_Id, Typeid, TypeName, Typevalue, Orderno, [Index]
                FROM OPENJSON(@TrackTraceJson)
                WITH (
                    Typeid VARCHAR(50) '$.Typeid',
                    TypeName NVARCHAR(255) '$.TypeName',
                    Typevalue VARCHAR(255) '$.Typevalue',
                    Orderno INT '$.Orderno',
                    [Index] INT '$.Index'
                );
            END

            SELECT 1 AS success, 'Service Setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
        END
        ELSE IF @DML = 'U'
        BEGIN
            UPDATE M_ServiceSubscriptionTrans
            SET WarrantyPeriod = ISNULL(@WarrantyPeriod, WarrantyPeriod),
                DateFrom = ISNULL(@DateFrom, DateFrom),
                DateTo = ISNULL(@DateTo, DateTo),
                IsCashConvert = ISNULL(@IsCashConvert, IsCashConvert),
                Frequency = ISNULL(@Frequency, Frequency),
                Points = ISNULL(@Points, Points),
                AmtType = ISNULL(@AmtType, AmtType),
                totalamont = ISNULL(@TotalLoyalty, totalamont),
                Minval = ISNULL(@Minval, Minval),
                Maxval = ISNULL(@Maxval, Maxval),
                IsCash = ISNULL(@IsCash, IsCash),
                Comments = ISNULL(@Comments, Comments),
                IsReferral = ISNULL(@IsReferral, IsReferral)
            WHERE Subscribe_Id = @Subscribe_Id;

            SELECT 1 AS success, 'Service Setting updated successfully.' AS message;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
