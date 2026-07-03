
-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-01
-- Description: Updates records in BLoyaltyPointsEarned (and related tables) that have invalid/orphaned
--              SST_id mappings (values not present in M_ServiceSubscriptionTrans) company-wise.
--              Dynamically resolves the correct active SST_Id and corrects the Company ID
--              using code series/order validation and product registration data.
-- =========================================================================================================
CREATE   PROCEDURE [dbo].[USP_UpdateInvalidSSTIdByCompany_AI]
    @CompId NVARCHAR(100),
    @IsDryRun BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validate parameter
    IF @CompId IS NULL OR LTRIM(RTRIM(@CompId)) = ''
    BEGIN
        RAISERROR('Company ID cannot be null or empty.', 16, 1);
        RETURN;
    END

    -- 2. Populate temporary tables of targets to update (fast indexed filtering)
    CREATE TABLE #TargetLoyalty (
        BLoyalty_PointEarnedID INT PRIMARY KEY,
        BuildLoyaltyOrReferralMCodeCheckid INT,
        Code1 VARCHAR(50),
        Code2 VARCHAR(50),
        SST_id VARCHAR(50),
        compid VARCHAR(50),
        CreatedBy VARCHAR(100),
        UpdateDate DATETIME
    );

    INSERT INTO #TargetLoyalty
    SELECT b.BLoyalty_PointEarnedID, b.BuildLoyaltyOrReferralMCodeCheckid, b.Code1, b.Code2, b.SST_id, b.compid, b.CreatedBy, b.UpdateDate
    FROM dbo.BLoyaltyPointsEarned b WITH (NOLOCK)
    WHERE b.compid = @CompId
      AND b.SST_id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) WHERE sst.SST_Id = b.SST_id
      );

    CREATE TABLE #TargetDetails (
        PE_ID INT PRIMARY KEY,
        Code1 VARCHAR(50),
        Code2 VARCHAR(50),
        SST_Id VARCHAR(50),
        Comp_id VARCHAR(50)
    );

    INSERT INTO #TargetDetails
    SELECT c.PE_ID, c.Code1, c.Code2, c.SST_Id, c.Comp_id
    FROM dbo.ConsumerPointsCashDetails c WITH (NOLOCK)
    WHERE c.Comp_id = @CompId
      AND c.SST_Id IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) WHERE sst.SST_Id = c.SST_Id
      );

    CREATE TABLE #TargetEnq (
        Row_ID BIGINT PRIMARY KEY,
        Received_Code1 VARCHAR(50),
        Received_Code2 VARCHAR(50),
        SST_ID VARCHAR(50),
        Comp_ID VARCHAR(50)
    );

    INSERT INTO #TargetEnq
    SELECT pe.Row_ID, pe.Received_Code1, pe.Received_Code2, pe.SST_ID, pe.Comp_ID
    FROM dbo.Pro_Enq pe WITH (NOLOCK)
    WHERE pe.Comp_ID = @CompId
      AND pe.SST_ID IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) WHERE sst.SST_Id = pe.SST_ID
      );

    -- 3. Dry run preview or real update execution
    IF @IsDryRun = 1
    BEGIN
        PRINT '--- DRY RUN PREVIEW: Invalid SST_id Mappings in BLoyaltyPointsEarned for ' + @CompId + ' ---';

        SELECT 
            t.BLoyalty_PointEarnedID,
            t.compid AS Current_compid,
            CorrectSST.Comp_ID AS Correct_compid,
            t.Code1,
            t.Code2,
            t.SST_id AS Current_Invalid_SST_id,
            t.CreatedBy AS Current_CreatedBy,
            t.SST_id AS New_CreatedBy_Value,
            mc.Pro_ID,
            mc.Series_Order,
            mc.Series_Serial,
            CorrectSST.SST_Id AS Correct_SST_Id,
            CorrectSST.Subscribe_Id,
            t.UpdateDate
        FROM #TargetLoyalty t
        INNER JOIN dbo.M_Code mc WITH (NOLOCK) ON mc.Code1 = TRY_CAST(t.Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(t.Code2 AS NUMERIC(18,0))
        OUTER APPLY (
            SELECT TOP 1 sst.SST_Id, sst.Subscribe_Id, pr.Comp_ID
            FROM dbo.M_ServiceSubscription ss WITH (NOLOCK)
            INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
            INNER JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = ss.Pro_ID
            WHERE ss.Pro_ID = mc.Pro_ID
              AND ss.IsActive = 1 AND ISNULL(ss.IsDelete, 0) = 0
              AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
              AND (
                  ss.start_order IS NULL 
                  OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (ss.start_order * 10000 + ss.start_series) AND (ss.end_order * 10000 + ss.end_series)
              )
            ORDER BY sst.Entry_Date DESC
        ) CorrectSST;
          
        DROP TABLE IF EXISTS #TargetLoyalty, #TargetDetails, #TargetEnq;
        RETURN;
    END

    -- Real Update Execution
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @LoyaltyUpdated INT = 0;
        DECLARE @CodeCheckUpdated INT = 0;
        DECLARE @DetailsUpdated INT = 0;
        DECLARE @EnqUpdated INT = 0;

        -- 1. Update BuiltLoyaltyMCodeCheck (linked via BuildLoyaltyOrReferralMCodeCheckid)
        UPDATE mcc
        SET mcc.sst_id = CorrectSST.SST_Id
        FROM dbo.BuiltLoyaltyMCodeCheck mcc
        INNER JOIN #TargetLoyalty t ON mcc.Pkid = t.BuildLoyaltyOrReferralMCodeCheckid
        INNER JOIN dbo.M_Code mc ON mc.Code1 = TRY_CAST(t.Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(t.Code2 AS NUMERIC(18,0))
        CROSS APPLY (
            SELECT TOP 1 sst.SST_Id
            FROM dbo.M_ServiceSubscription ss WITH (NOLOCK)
            INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
            WHERE ss.Pro_ID = mc.Pro_ID
              AND ss.IsActive = 1 AND ISNULL(ss.IsDelete, 0) = 0
              AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
              AND (
                  ss.start_order IS NULL 
                  OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (ss.start_order * 10000 + ss.start_series) AND (ss.end_order * 10000 + ss.end_series)
              )
            ORDER BY sst.Entry_Date DESC
        ) CorrectSST;

        SET @CodeCheckUpdated = @@ROWCOUNT;

        -- 2. Update BLoyaltyPointsEarned (correct SST_id, compid, and CreatedBy auditing column)
        UPDATE b
        SET b.CreatedBy = b.SST_id, -- copy old sst_id to CreatedBy for future check
            b.SST_id = CorrectSST.SST_Id,
            b.compid = CorrectSST.Comp_ID
        FROM dbo.BLoyaltyPointsEarned b
        INNER JOIN #TargetLoyalty t ON b.BLoyalty_PointEarnedID = t.BLoyalty_PointEarnedID
        INNER JOIN dbo.M_Code mc ON mc.Code1 = TRY_CAST(t.Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(t.Code2 AS NUMERIC(18,0))
        CROSS APPLY (
            SELECT TOP 1 sst.SST_Id, pr.Comp_ID
            FROM dbo.M_ServiceSubscription ss WITH (NOLOCK)
            INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
            INNER JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = ss.Pro_ID
            WHERE ss.Pro_ID = mc.Pro_ID
              AND ss.IsActive = 1 AND ISNULL(ss.IsDelete, 0) = 0
              AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
              AND (
                  ss.start_order IS NULL 
                  OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (ss.start_order * 10000 + ss.start_series) AND (ss.end_order * 10000 + ss.end_series)
              )
            ORDER BY sst.Entry_Date DESC
        ) CorrectSST;

        SET @LoyaltyUpdated = @@ROWCOUNT;

        -- 3. Update ConsumerPointsCashDetails (correct SST_Id and Comp_id)
        UPDATE c
        SET c.SST_Id = CorrectSST.SST_Id,
            c.Comp_id = CorrectSST.Comp_ID
        FROM dbo.ConsumerPointsCashDetails c
        INNER JOIN #TargetDetails t ON c.PE_ID = t.PE_ID
        INNER JOIN dbo.M_Code mc ON mc.Code1 = TRY_CAST(t.Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(t.Code2 AS NUMERIC(18,0))
        CROSS APPLY (
            SELECT TOP 1 sst.SST_Id, pr.Comp_ID
            FROM dbo.M_ServiceSubscription ss WITH (NOLOCK)
            INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
            INNER JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = ss.Pro_ID
            WHERE ss.Pro_ID = mc.Pro_ID
              AND ss.IsActive = 1 AND ISNULL(ss.IsDelete, 0) = 0
              AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
              AND (
                  ss.start_order IS NULL 
                  OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (ss.start_order * 10000 + ss.start_series) AND (ss.end_order * 10000 + ss.end_series)
              )
            ORDER BY sst.Entry_Date DESC
        ) CorrectSST;

        SET @DetailsUpdated = @@ROWCOUNT;

        -- 4. Update Pro_Enq (Inquiry history - correct SST_ID and Comp_ID)
        UPDATE pe
        SET pe.SST_ID = CorrectSST.SST_Id,
            pe.Comp_ID = CorrectSST.Comp_ID
        FROM dbo.Pro_Enq pe
        INNER JOIN #TargetEnq t ON pe.Row_ID = t.Row_ID
        INNER JOIN dbo.M_Code mc ON mc.Code1 = TRY_CAST(t.Received_Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(t.Received_Code2 AS NUMERIC(18,0))
        CROSS APPLY (
            SELECT TOP 1 sst.SST_Id, pr.Comp_ID
            FROM dbo.M_ServiceSubscription ss WITH (NOLOCK)
            INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id
            INNER JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = ss.Pro_ID
            WHERE ss.Pro_ID = mc.Pro_ID
              AND ss.IsActive = 1 AND ISNULL(ss.IsDelete, 0) = 0
              AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
              AND (
                  ss.start_order IS NULL 
                  OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (ss.start_order * 10000 + ss.start_series) AND (ss.end_order * 10000 + ss.end_series)
              )
            ORDER BY sst.Entry_Date DESC
        ) CorrectSST;

        SET @EnqUpdated = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return execution summary report
        SELECT 
            @LoyaltyUpdated AS BLoyaltyPointsEarned_Rows_Updated,
            @CodeCheckUpdated AS BuiltLoyaltyMCodeCheck_Rows_Updated,
            @DetailsUpdated AS ConsumerPointsCashDetails_Rows_Updated,
            @EnqUpdated AS Pro_Enq_Rows_Updated,
            'Success' AS Execution_Status;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

    DROP TABLE IF EXISTS #TargetLoyalty, #TargetDetails, #TargetEnq;
END
