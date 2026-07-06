-- =============================================
-- Procedure: USP_InsertUpdateServiceSubscription_AI
-- Description: Insert or Update service subscription in M_ServiceSubscription
-- Created for: Fix "too many arguments" error
-- =============================================
IF OBJECT_ID('USP_InsertUpdateServiceSubscription_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_InsertUpdateServiceSubscription_AI
GO

CREATE OR ALTER PROCEDURE USP_InsertUpdateServiceSubscription_AI
    @Subscribe_Id      NVARCHAR(50),
    @Service_ID       NVARCHAR(50),
    @Comp_ID          NVARCHAR(50),
    @Pro_ID           NVARCHAR(50),
    @Plan_ID          NVARCHAR(50)   = NULL,
    @PlanName         NVARCHAR(200)  = NULL,
    @PlanMasterPeriod NUMERIC(18, 0) = NULL,
    @DateFrom         DATETIME       = NULL,
    @DateTo           DATETIME       = NULL,
    @EntryDate        DATETIME       = NULL,
    @PlanSalePeriod   NUMERIC(18, 0) = NULL,
    @StartOrder       INT            = NULL,
    @StartSeries      INT            = NULL,
    @EndOrder         INT            = NULL,
    @EndSeries        INT            = NULL,
    @BatchSize        INT            = NULL,
    @DML              NCHAR(1)       -- 'I' = Insert, 'U' = Update
AS
BEGIN
    SET NOCOUNT ON;

    -- Local variables for fixed/derived values
    DECLARE @PlanMasterPrice  NUMERIC(18, 0) = 0;
    DECLARE @PlanSalePrice    NUMERIC(18, 0) = 0;
    DECLARE @IsActive         INT = 0;
    DECLARE @IsDelete         INT = 0;
    DECLARE @IsAdminVerify    INT = 1;

    -- Automated Sequencing Logic
    IF (@DML = 'I' OR @DML = 'U') AND @StartOrder IS NULL AND @Pro_ID IS NOT NULL AND @BatchSize IS NOT NULL
    BEGIN
        DECLARE @LastEndOrder INT, @LastEndSerial INT;
        SELECT TOP 1 @LastEndOrder = end_order, @LastEndSerial = end_series
        FROM M_ServiceSubscription
        WHERE Pro_ID = @Pro_ID AND end_order IS NOT NULL
        ORDER BY EntryDate DESC, Subscribe_Id DESC;

        IF @LastEndOrder IS NULL
        BEGIN
            SELECT TOP 1 @StartOrder = Series_Order, @StartSeries = Series_Serial
            FROM M_Code WHERE Pro_ID = @Pro_ID ORDER BY Series_Order, Series_Serial;
        END
        ELSE
        BEGIN
            SELECT TOP 1 @StartOrder = Series_Order, @StartSeries = Series_Serial
            FROM M_Code 
            WHERE Pro_ID = @Pro_ID 
              AND (Series_Order > @LastEndOrder OR (Series_Order = @LastEndOrder AND Series_Serial > @LastEndSerial))
            ORDER BY Series_Order, Series_Serial;
        END

        IF @StartOrder IS NOT NULL
        BEGIN
            ;WITH NextBatch AS (
                SELECT TOP (@BatchSize) Series_Order, Series_Serial
                FROM M_Code
                WHERE Pro_ID = @Pro_ID
                  AND (Series_Order > @StartOrder OR (Series_Order = @StartOrder AND Series_Serial >= @StartSeries))
                ORDER BY Series_Order, Series_Serial
            )
            SELECT 
                @EndOrder = MAX(Series_Order),
                @EndSeries = MAX(Series_Serial)
            FROM (SELECT TOP (@BatchSize) * FROM NextBatch ORDER BY Series_Order DESC, Series_Serial DESC) AS LastCode;
            
            IF @EndSeries IS NULL SELECT @EndSeries = MAX(Series_Serial) FROM (SELECT TOP (@BatchSize) * FROM NextBatch) t WHERE Series_Order = @EndOrder;
        END
    END

    IF @DML = 'I'
    BEGIN
        INSERT INTO M_ServiceSubscription
        (
            Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, 
            PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice, 
            DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify,
            TransType, start_order, start_series, end_order, end_series
        )
        VALUES
        (
            @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, ISNULL(@Plan_ID, 'PLAN_DEFAULT'), ISNULL(@PlanName, 'Manual Subscription'), 
            ISNULL(@PlanMasterPeriod, 12), ISNULL(@PlanSalePeriod, 12), @PlanMasterPrice, @PlanSalePrice, 
            ISNULL(@DateFrom, GETDATE()), ISNULL(@DateTo, DATEADD(YEAR, 1, GETDATE())), ISNULL(@EntryDate, GETDATE()), @IsActive, @IsDelete, @IsAdminVerify,
            'Service', @StartOrder, @StartSeries, @EndOrder, @EndSeries
        );

        SELECT 1 AS success, 'Subscription added successfully.' AS message, @StartOrder AS StartOrder, @StartSeries AS StartSeries, @EndOrder AS EndOrder, @EndSeries AS EndSeries;
    END
    ELSE IF @DML = 'U'
    BEGIN
        UPDATE M_ServiceSubscription
        SET 
            Service_ID = ISNULL(@Service_ID, Service_ID),
            Comp_ID = ISNULL(@Comp_ID, Comp_ID),
            Pro_ID = ISNULL(@Pro_ID, Pro_ID),
            Plan_ID = ISNULL(@Plan_ID, Plan_ID),
            PlanName = ISNULL(@PlanName, PlanName),
            PlanMasterPeriod = ISNULL(@PlanMasterPeriod, PlanMasterPeriod),
            PlanSalePeriod = ISNULL(@PlanSalePeriod, PlanSalePeriod),
            PlanMasterPrice = ISNULL(@PlanMasterPrice, PlanMasterPrice),
            PlanSalePrice = ISNULL(@PlanSalePrice, PlanSalePrice),
            DateFrom = ISNULL(@DateFrom, DateFrom),
            DateTo = ISNULL(@DateTo, DateTo),
            EntryDate = ISNULL(@EntryDate, EntryDate),
            IsActive = ISNULL(@IsActive, IsActive),
            IsDelete = ISNULL(@IsDelete, IsDelete),
            IsAdminVerify = ISNULL(@IsAdminVerify, IsAdminVerify),
            start_order = ISNULL(@StartOrder, start_order),
            start_series = ISNULL(@StartSeries, start_series),
            end_order = ISNULL(@EndOrder, end_order),
            end_series = ISNULL(@EndSeries, end_series)
        WHERE Subscribe_Id = @Subscribe_Id;

        SELECT 1 AS success, 'Subscription updated successfully.' AS message;
    END
END
GO
