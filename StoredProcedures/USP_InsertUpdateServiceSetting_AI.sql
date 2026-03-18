CREATE PROCEDURE [dbo].[USP_InsertUpdateServiceSetting_AI]
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
            -- Logic to INSERT into M_ServiceSubscriptionTrans or related table
            -- Assuming the main table is M_ServiceSubscriptionTrans as seen in comments
            
            INSERT INTO M_ServiceSubscriptionTrans (
                Subscribe_Id, Comp_ID, Pro_ID, Service_ID,
                WarrantyPeriod, ReferralLimit, DateFrom, DateTo, DueDate,
                IsCashConvert, Frequency, Points, AmtType, TotalLoyalty,
                Multiple, Minval, Maxval, IsCash, Comments,
                ServiceType, Rules, MasterCodes, WinningCodes, WinCodes, Nth, RewardsDistribution,
                IsReferral, RefGiftReferral, RefGiftUsers, RefPointsReferral, RefPointsUsers,
                RefIsCashConvert, RefIsCashReferral, RefIsCashUsers,
                StartOrder, StartSeries, EndOrder, EndSeries,
                EntryDate
            )
            VALUES (
                @Subscribe_Id, @Comp_ID, @Pro_ID, @Service_ID,
                @WarrantyPeriod, @ReferralLimit, @DateFrom, @DateTo, @DueDate,
                @IsCashConvert, @Frequency, @Points, @AmtType, @TotalLoyalty,
                @Multiple, @Minval, @Maxval, @IsCash, @Comments,
                @ServiceType, @Rules, @MasterCodes, @WinningCodes, @WinCodes, @Nth, @RewardsDistribution,
                @IsReferral, @RefGiftReferral, @RefGiftUsers, @RefPointsReferral, @RefPointsUsers,
                @RefIsCashConvert, @RefIsCashReferral, @RefIsCashUsers,
                @StartOrder, @StartSeries, @EndOrder, @EndSeries,
                ISNULL(@EntryDate, GETDATE())
            );

            SET @NewSST_Id = SCOPE_IDENTITY();
            
            -- Parsing JSON for Gifts if provided
            IF @GiftListJson IS NOT NULL
            BEGIN
                -- Insert into Gift related table (e.g. M_ServiceSettingGifts)
                INSERT INTO M_ServiceSettingGifts (SST_Id, Gift_ID, GiftName, GiftCount)
                SELECT @NewSST_Id, Gift_ID, GiftName, GiftCount
                FROM OPENJSON(@GiftListJson)
                WITH (
                    Gift_ID VARCHAR(50) '$.Gift_ID',
                    GiftName NVARCHAR(255) '$.GiftName',
                    GiftCount INT '$.GiftCount'
                );
            END

            -- Parsing JSON for TrackTraceSettings if provided
            IF @TrackTraceJson IS NOT NULL
            BEGIN
                -- Insert into Track Trace related tables
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
            -- Update Logic (Simplified for demonstration as legacy relies on SST_Id or similar PK)
            -- This assumes we are updating based on Subscribe_Id/Comp_ID/Pro_ID/Service_ID
            -- A proper Update might need an explicit SST_Id.
            UPDATE M_ServiceSubscriptionTrans
            SET WarrantyPeriod = ISNULL(@WarrantyPeriod, WarrantyPeriod),
                ReferralLimit = ISNULL(@ReferralLimit, ReferralLimit),
                DateFrom = ISNULL(@DateFrom, DateFrom),
                DateTo = ISNULL(@DateTo, DateTo),
                DueDate = ISNULL(@DueDate, DueDate),
                IsCashConvert = ISNULL(@IsCashConvert, IsCashConvert),
                Frequency = ISNULL(@Frequency, Frequency),
                Points = ISNULL(@Points, Points),
                AmtType = ISNULL(@AmtType, AmtType),
                TotalLoyalty = ISNULL(@TotalLoyalty, TotalLoyalty),
                Multiple = ISNULL(@Multiple, Multiple),
                Minval = ISNULL(@Minval, Minval),
                Maxval = ISNULL(@Maxval, Maxval),
                IsCash = ISNULL(@IsCash, IsCash),
                Comments = ISNULL(@Comments, Comments),
                ServiceType = ISNULL(@ServiceType, ServiceType),
                Rules = ISNULL(@Rules, Rules),
                MasterCodes = ISNULL(@MasterCodes, MasterCodes),
                WinningCodes = ISNULL(@WinningCodes, WinningCodes),
                RewardsDistribution = ISNULL(@RewardsDistribution, RewardsDistribution),
                IsReferral = ISNULL(@IsReferral, IsReferral),
                StartOrder = ISNULL(@StartOrder, StartOrder),
                StartSeries = ISNULL(@StartSeries, StartSeries),
                EndOrder = ISNULL(@EndOrder, EndOrder),
                EndSeries = ISNULL(@EndSeries, EndSeries)
            WHERE Subscribe_Id = @Subscribe_Id AND Comp_ID = @Comp_ID;

            SELECT 1 AS success, 'Service Setting updated successfully.' AS message;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        SELECT 0 AS success, @ErrorMessage AS message;
    END CATCH
END
