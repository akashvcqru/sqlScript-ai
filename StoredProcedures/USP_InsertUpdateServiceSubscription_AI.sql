-- =============================================
-- Procedure: USP_InsertUpdateServiceSubscription_AI
-- Description: Insert or Update service subscription in M_ServiceSubscription
-- Created for: Fix "too many arguments" error
-- =============================================
IF OBJECT_ID('USP_InsertUpdateServiceSubscription_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_InsertUpdateServiceSubscription_AI
GO

CREATE PROCEDURE USP_InsertUpdateServiceSubscription_AI
    @Subscribe_Id      NVARCHAR(50),
    @Service_ID       NVARCHAR(50),
    @Comp_ID          NVARCHAR(50),
    @Pro_ID           NVARCHAR(50),
    @Plan_ID          NVARCHAR(50),
    @PlanName         NVARCHAR(200),
    @PlanMasterPeriod NUMERIC(18, 0),
    @DateFrom         DATETIME,
    @DateTo           DATETIME,
    @EntryDate        DATETIME,
    @PlanSalePeriod   NUMERIC(18, 0),
    @DML              NCHAR(1) -- 'I' = Insert, 'U' = Update
AS
BEGIN
    SET NOCOUNT ON;

    -- Local variables for fixed/derived values
    DECLARE @PlanMasterPrice  NUMERIC(18, 0) = 0;
    DECLARE @PlanSalePrice    NUMERIC(18, 0) = 0;
    DECLARE @IsActive         INT = 0;
    DECLARE @IsDelete         INT = 0;
    DECLARE @IsAdminVerify    INT = 1;

    IF @DML = 'I'
    BEGIN
        INSERT INTO M_ServiceSubscription
        (
            Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, 
            PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice, 
            DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify,
            TransType
        )
        VALUES
        (
            @Subscribe_Id, @Service_ID, @Comp_ID, @Pro_ID, @Plan_ID, @PlanName, 
            @PlanMasterPeriod, @PlanSalePeriod, @PlanMasterPrice, @PlanSalePrice, 
            @DateFrom, @DateTo, @EntryDate, @IsActive, @IsDelete, @IsAdminVerify,
            'Service'
        );

        SELECT 1 AS success, 'Subscription added successfully.' AS message;
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
            IsAdminVerify = ISNULL(@IsAdminVerify, IsAdminVerify)
        WHERE Subscribe_Id = @Subscribe_Id;

        SELECT 1 AS success, 'Subscription updated successfully.' AS message;
    END
    ELSE
    BEGIN
        SELECT 0 AS success, 'Invalid DML operation.' AS message;
    END
END
GO
