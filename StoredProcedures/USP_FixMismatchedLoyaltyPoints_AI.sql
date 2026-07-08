-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-08
-- Description: Identifies and fixes mismatched loyalty points and cash records in BLoyaltyPointsEarned
--              and ConsumerPointsCashDetails by transferring points/cash from duplicate scan records
--              to first-scan records.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_FixMismatchedLoyaltyPoints_AI]
    @CompId NVARCHAR(100) = NULL,
    @IsDryRun BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DROP TABLE IF EXISTS #MismatchesToFix;
        
        SELECT 
            e1.BLoyalty_PointEarnedID AS TargetEarnedID,
            e2.BLoyalty_PointEarnedID AS SourceEarnedID,
            e1.Points AS TargetPoints,
            e1.Cash AS TargetCash,
            e2.Points AS SourcePoints,
            e2.Cash AS SourceCash,
            mc.Compid AS CompanyID,
            mc.M_Consumer_MCodeid AS ConsumerMCodeID
        INTO #MismatchesToFix
        FROM dbo.BuiltLoyaltyMCodeCheck b1 WITH (NOLOCK)
        INNER JOIN dbo.BuiltLoyaltyMCodeCheck b2 WITH (NOLOCK)
            ON b1.M_Consumer_MCOdeid = b2.M_Consumer_MCOdeid 
            AND b1.Pkid < b2.Pkid
        INNER JOIN M_Consumer_M_Code mc WITH (NOLOCK)
            ON b1.M_Consumer_MCOdeid = mc.M_Consumer_MCodeid
        INNER JOIN dbo.BLoyaltyPointsEarned e1 WITH (NOLOCK)
            ON e1.BuildLoyaltyOrReferralMCodeCheckid = b1.Pkid
        INNER JOIN dbo.BLoyaltyPointsEarned e2 WITH (NOLOCK)
            ON e2.BuildLoyaltyOrReferralMCodeCheckid = b2.Pkid
        WHERE (@CompId IS NULL OR mc.Compid = @CompId)
          AND (((e1.Points IS NULL OR e1.Points = 0) AND (e2.Points > 0))
               OR ((e1.Cash IS NULL OR e1.Cash = 0) AND (e2.Cash > 0)));

        IF @IsDryRun = 1
        BEGIN
            SELECT 
                CompanyID,
                ConsumerMCodeID,
                TargetEarnedID,
                TargetPoints AS CurrentTargetPoints,
                TargetCash AS CurrentTargetCash,
                SourceEarnedID,
                SourcePoints AS CurrentSourcePoints,
                SourceCash AS CurrentSourceCash,
                SourcePoints AS NewTargetPoints,
                SourceCash AS NewTargetCash
            FROM #MismatchesToFix;

            DROP TABLE IF EXISTS #MismatchesToFix;
            RETURN;
        END

        BEGIN TRANSACTION;

        DECLARE @RestoredRows INT = 0;
        DECLARE @ClearedRows INT = 0;

        IF EXISTS (SELECT 1 FROM #MismatchesToFix)
        BEGIN
            -- 1. Move points/cash from duplicate scans to first scan records if target is null/0
            UPDATE e
            SET e.Points = CASE WHEN ISNULL(e.Points, 0) = 0 AND ISNULL(m.SourcePoints, 0) > 0 THEN m.SourcePoints ELSE e.Points END,
                e.Cash = CASE WHEN ISNULL(e.Cash, 0) = 0 AND ISNULL(m.SourceCash, 0) > 0 THEN m.SourceCash ELSE e.Cash END,
                e.UpdateDate = GETDATE()
            FROM dbo.BLoyaltyPointsEarned e
            INNER JOIN #MismatchesToFix m ON e.BLoyalty_PointEarnedID = m.TargetEarnedID;

            SET @RestoredRows = @@ROWCOUNT;

            -- Update corresponding ConsumerPointsCashDetails for target
            UPDATE c
            SET c.Points = e.Points,
                c.Cash = e.Cash
            FROM dbo.ConsumerPointsCashDetails c
            INNER JOIN dbo.BLoyaltyPointsEarned e ON c.PE_ID = e.BLoyalty_PointEarnedID
            INNER JOIN #MismatchesToFix m ON e.BLoyalty_PointEarnedID = m.TargetEarnedID;

            -- 2. Reset points/cash on duplicate scan records to 0
            UPDATE e
            SET e.Points = CASE WHEN ISNULL(m.TargetPoints, 0) = 0 AND ISNULL(e.Points, 0) > 0 THEN 0 ELSE e.Points END,
                e.Cash = CASE WHEN ISNULL(m.TargetCash, 0) = 0 AND ISNULL(e.Cash, 0) > 0 THEN 0 ELSE e.Cash END,
                e.UpdateDate = GETDATE()
            FROM dbo.BLoyaltyPointsEarned e
            INNER JOIN #MismatchesToFix m ON e.BLoyalty_PointEarnedID = m.SourceEarnedID;

            SET @ClearedRows = @@ROWCOUNT;

            -- Update corresponding ConsumerPointsCashDetails for source
            UPDATE c
            SET c.Points = e.Points,
                c.Cash = e.Cash
            FROM dbo.ConsumerPointsCashDetails c
            INNER JOIN dbo.BLoyaltyPointsEarned e ON c.PE_ID = e.BLoyalty_PointEarnedID
            INNER JOIN #MismatchesToFix m ON e.BLoyalty_PointEarnedID = m.SourceEarnedID;
        END

        COMMIT TRANSACTION;

        SELECT 
            @RestoredRows AS RestoredFirstScanRecordsCount,
            @ClearedRows AS ClearedDuplicateScanRecordsCount,
            'Success' AS ExecutionStatus;

        DROP TABLE IF EXISTS #MismatchesToFix;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DROP TABLE IF EXISTS #MismatchesToFix;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END
GO
