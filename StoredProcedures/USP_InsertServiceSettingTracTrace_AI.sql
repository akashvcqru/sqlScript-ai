-- ============================================================
-- Stored Procedure: USP_InsertServiceSettingTracTrace_AI
-- Purpose        : Insert Track & Trace service setting.
--                  Parses TrackTraceJson array and inserts each
--                  channel row into M_ServiceSettingTrackTrace.
-- JSON format    : [{"Typeid":"1","TypeName":"Production Unit",
--                    "Typevalue":"0","Orderno":1,"Index":0}]
-- ============================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertServiceSettingTracTrace_AI]
    @Comp_ID        VARCHAR(50),
    @Pro_ID         VARCHAR(50),
    @Service_ID     VARCHAR(50),
    @Subscribe_Id   VARCHAR(50)    = NULL,

    @DateFrom       DATETIME       = NULL,
    @DateTo         DATETIME       = NULL,

    -- JSON array of track-trace channel rows
    @TrackTraceJson NVARCHAR(MAX)  = NULL,

    @Comments       NVARCHAR(1000) = NULL,
    @EntryDate      DATETIME       = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Resolve Subscribe_Id
        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT TOP 1 @Subscribe_Id = Subscribe_Id
            FROM M_ServiceSubscription
            WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID AND Service_ID = @Service_ID;
        END

        IF ISNULL(@Subscribe_Id, '') = ''
        BEGIN
            SELECT 0 AS success, 'No active subscription found for the given Comp/Product/Service.' AS message;
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert header row
        INSERT INTO M_ServiceSubscriptionTrans
        (
            Subscribe_Id, Comp_ID, Pro_ID, Service_ID,
            DateFrom, DateTo,
            Comments, EntryDate
        )
        VALUES
        (
            @Subscribe_Id, @Comp_ID, @Pro_ID, @Service_ID,
            @DateFrom, @DateTo,
            @Comments, ISNULL(@EntryDate, GETDATE())
        );

        DECLARE @NewSST_Id BIGINT = SCOPE_IDENTITY();

        -- Insert Track & Trace channel rows
        IF @TrackTraceJson IS NOT NULL AND LEN(@TrackTraceJson) > 2
        BEGIN
            INSERT INTO M_ServiceSettingTrackTrace
                (SST_Id, Typeid, TypeName, Typevalue, Orderno, [Index])
            SELECT
                @NewSST_Id, Typeid, TypeName, Typevalue, Orderno, [Index]
            FROM OPENJSON(@TrackTraceJson)
            WITH (
                Typeid    VARCHAR(50)   '$.Typeid',
                TypeName  NVARCHAR(255) '$.TypeName',
                Typevalue VARCHAR(255)  '$.Typevalue',
                Orderno   INT           '$.Orderno',
                [Index]   INT           '$.Index'
            );
        END

        COMMIT TRANSACTION;
        SELECT 1 AS success, 'Track & Trace service setting added successfully.' AS message, @NewSST_Id AS NewSST_Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
