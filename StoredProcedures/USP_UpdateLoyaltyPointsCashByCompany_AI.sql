-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-02
-- Description: Completes incomplete code check journeys for successful scans in Pro_Enq and corrects
--              missing (NULL or 0) points or cash values in BLoyaltyPointsEarned and ConsumerPointsCashDetails
--              company-wise, dynamically resolving the correct active SST_Id and company ID.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateLoyaltyPointsCashByCompany_AI]
    @CompId NVARCHAR(100),
    @IsDryRun BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Parameter Validation
    IF @CompId IS NULL OR LTRIM(RTRIM(@CompId)) = ''
    BEGIN
        RAISERROR('Company ID cannot be null or empty.', 16, 1);
        RETURN;
    END

    -- 2. Phase 1: Identify Incomplete Journeys (Successful scans in Pro_Enq missing BLoyaltyPointsEarned)
    DROP TABLE IF EXISTS #SuccessfulScans;
    CREATE TABLE #SuccessfulScans (
        RowID BIGINT PRIMARY KEY,
        Received_Code1 VARCHAR(50),
        Received_Code2 VARCHAR(50),
        MobileNo VARCHAR(50),
        Enq_Date DATETIME,
        Latitude NVARCHAR(50),
        Longitude NVARCHAR(50),
        Dial_Mode VARCHAR(60),
        SST_ID BIGINT
    );

    INSERT INTO #SuccessfulScans
    SELECT 
        pe.Row_ID,
        pe.Received_Code1,
        pe.Received_Code2,
        pe.MobileNo,
        pe.Enq_Date,
        pe.Latitude,
        pe.Longitude,
        pe.Dial_Mode,
        pe.SST_ID
    FROM dbo.Pro_Enq pe WITH (NOLOCK)
    WHERE pe.Comp_ID = @CompId
      AND pe.Is_Success = 1
      AND ISNUMERIC(pe.Received_Code1) = 1
      AND ISNUMERIC(pe.Received_Code2) = 1;

    DROP TABLE IF EXISTS #IncompleteScans;
    CREATE TABLE #IncompleteScans (
        RowID BIGINT PRIMARY KEY,
        Received_Code1 VARCHAR(50),
        Received_Code2 VARCHAR(50),
        MobileNo VARCHAR(50),
        Enq_Date DATETIME,
        Latitude NVARCHAR(50),
        Longitude NVARCHAR(50),
        Dial_Mode VARCHAR(60),
        SST_ID BIGINT,
        Pro_ID VARCHAR(50),
        M_Consumerid BIGINT,
        M_Codeid BIGINT
    );

    INSERT INTO #IncompleteScans
    SELECT 
        pe.RowID,
        pe.Received_Code1,
        pe.Received_Code2,
        pe.MobileNo,
        pe.Enq_Date,
        pe.Latitude,
        pe.Longitude,
        pe.Dial_Mode,
        pe.SST_ID,
        mc.Pro_ID,
        mcc.M_Consumerid,
        mc.Row_ID
    FROM #SuccessfulScans pe
    INNER JOIN dbo.M_Code mc WITH (NOLOCK) ON mc.Code1 = CAST(pe.Received_Code1 AS NUMERIC(18,0)) AND mc.Code2 = CAST(pe.Received_Code2 AS NUMERIC(18,0))
    INNER JOIN dbo.M_Consumer mcc WITH (NOLOCK) ON mcc.MobileLast10 = RIGHT(pe.MobileNo, 10) AND mcc.IsDelete = 0
    WHERE NOT EXISTS (
          SELECT 1 FROM dbo.BLoyaltyPointsEarned b WITH (NOLOCK)
          WHERE b.Code1 = pe.Received_Code1 AND b.Code2 = pe.Received_Code2
      );

    -- 3. Dry Run Preview of Journeys to Complete
    IF @IsDryRun = 1
    BEGIN
        PRINT '--- DRY RUN PREVIEW: Incomplete Journeys to Complete for ' + @CompId + ' ---';
        SELECT 
            RowID AS Pro_Enq_RowID,
            Received_Code1 AS Code1,
            Received_Code2 AS Code2,
            MobileNo,
            Enq_Date,
            Pro_ID,
            M_Consumerid
        FROM #IncompleteScans;
    END

    -- If not dry run, perform the inserts to complete the journeys (Phase 1 execution)
    IF @IsDryRun = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            DECLARE @RowID BIGINT, @Received_Code1 VARCHAR(50), @Received_Code2 VARCHAR(50), @MobileNo VARCHAR(50), @Enq_Date DATETIME;
            DECLARE @Latitude NVARCHAR(50), @Longitude NVARCHAR(50), @Dial_Mode VARCHAR(60), @SST_ID BIGINT, @Pro_ID VARCHAR(50);
            DECLARE @M_Consumerid BIGINT, @M_Codeid BIGINT;
            DECLARE @M_Consumer_MCodeid BIGINT, @Pkid BIGINT;

            DECLARE db_cursor CURSOR LOCAL FOR 
            SELECT RowID, Received_Code1, Received_Code2, MobileNo, Enq_Date, Latitude, Longitude, Dial_Mode, SST_ID, Pro_ID, M_Consumerid, M_Codeid
            FROM #IncompleteScans;

            OPEN db_cursor;
            FETCH NEXT FROM db_cursor INTO @RowID, @Received_Code1, @Received_Code2, @MobileNo, @Enq_Date, @Latitude, @Longitude, @Dial_Mode, @SST_ID, @Pro_ID, @M_Consumerid, @M_Codeid;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- 1. Ensure M_Consumer_M_Code row exists
                SET @M_Consumer_MCodeid = NULL;
                SELECT TOP 1 @M_Consumer_MCodeid = M_Consumer_MCodeid 
                FROM dbo.M_Consumer_M_Code 
                WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid;

                IF @M_Consumer_MCodeid IS NULL
                BEGIN
                    INSERT INTO dbo.M_Consumer_M_Code (M_Consumerid, M_Codeid, Pro_id, CreatedDate, Compid)
                    VALUES (@M_Consumerid, @M_Codeid, @Pro_ID, @Enq_Date, @CompId);
                    SET @M_Consumer_MCodeid = SCOPE_IDENTITY();
                END

                -- 2. Ensure BuiltLoyaltyMCodeCheck row exists
                SET @Pkid = NULL;
                SELECT TOP 1 @Pkid = Pkid 
                FROM dbo.BuiltLoyaltyMCodeCheck 
                WHERE M_Consumer_MCOdeid = @M_Consumer_MCodeid;

                IF @Pkid IS NULL
                BEGIN
                    INSERT INTO dbo.BuiltLoyaltyMCodeCheck (sst_id, M_Consumer_MCOdeid, M_Cunsumerid, Createdate, IsPointsAssigned)
                    VALUES (@SST_ID, @M_Consumer_MCodeid, @M_Consumerid, @Enq_Date, 1);
                    SET @Pkid = SCOPE_IDENTITY();
                END

                -- 3. Ensure BLoyaltyPointsEarned row exists (points/cash resolved in Phase 2)
                DECLARE @PE_ID INT = NULL;
                INSERT INTO dbo.BLoyaltyPointsEarned (BuildLoyaltyOrReferralMCodeCheckid, SST_id, M_Consumerid, UpdateDate, Code1, Code2, compid, ServiceName, Service_ID)
                VALUES (@Pkid, @SST_ID, @M_Consumerid, @Enq_Date, @Received_Code1, @Received_Code2, @CompId, 'buildloyalty', (
                    SELECT TOP 1 ss.Service_ID 
                    FROM dbo.M_ServiceSubscription ss WITH (NOLOCK) 
                    INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id 
                    WHERE sst.SST_Id = @SST_ID
                ));
                SET @PE_ID = SCOPE_IDENTITY();

                -- 4. Ensure ConsumerPointsCashDetails row exists
                IF NOT EXISTS (SELECT 1 FROM dbo.ConsumerPointsCashDetails WHERE Code1 = @Received_Code1 AND Code2 = @Received_Code2)
                BEGIN
                    DECLARE @ProName NVARCHAR(200) = (SELECT TOP 1 Pro_Name FROM dbo.Pro_Reg WITH (NOLOCK) WHERE Pro_ID = @Pro_ID);
                    DECLARE @ServiceID NVARCHAR(50) = (
                        SELECT TOP 1 ss.Service_ID 
                        FROM dbo.M_ServiceSubscription ss WITH (NOLOCK) 
                        INNER JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id 
                        WHERE sst.SST_Id = @SST_ID
                    );

                    INSERT INTO dbo.ConsumerPointsCashDetails (MobileNo, Code1, Code2, Enq_Date, SST_Id, Points, Cash, Pro_id, Comp_id, M_ConsumerId, Is_Success, Pro_Name, Service_ID, Latitude, Longitude, PE_ID, Dial_Mode)
                    VALUES (@MobileNo, @Received_Code1, @Received_Code2, @Enq_Date, @SST_ID, 0, 0, @Pro_ID, @CompId, @M_Consumerid, '1', @ProName, @ServiceID, @Latitude, @Longitude, @PE_ID, @Dial_Mode);
                END

                FETCH NEXT FROM db_cursor INTO @RowID, @Received_Code1, @Received_Code2, @MobileNo, @Enq_Date, @Latitude, @Longitude, @Dial_Mode, @SST_ID, @Pro_ID, @M_Consumerid, @M_Codeid;
            END;

            CLOSE db_cursor;
            DEALLOCATE db_cursor;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            IF CURSOR_STATUS('local', 'db_cursor') >= 0
            BEGIN
                CLOSE db_cursor;
                DEALLOCATE db_cursor;
            END
            DECLARE @ErrMsg1 NVARCHAR(4000) = ERROR_MESSAGE();
            RAISERROR(@ErrMsg1, 16, 1);
            DROP TABLE IF EXISTS #IncompleteScans;
            RETURN;
        END CATCH
    END

    -- 4. Phase 2: Identify and Resolve Correct Points/Cash for targets
    DROP TABLE IF EXISTS #TargetsToUpdate;
    CREATE TABLE #TargetsToUpdate (
        BLoyalty_PointEarnedID INT PRIMARY KEY,
        BuildLoyaltyOrReferralMCodeCheckid INT,
        Code1 VARCHAR(50),
        Code2 VARCHAR(50),
        SST_id VARCHAR(50),
        compid VARCHAR(50),
        CurrentPoints INT,
        CurrentCash INT,
        Service_ID VARCHAR(50),
        Resolved_SST_Id BIGINT,
        Resolved_Points INT,
        Resolved_Cash DECIMAL(18,2),
        Resolved_Comp_ID NVARCHAR(100),
        Resolved_Service_ID VARCHAR(50)
    );

    INSERT INTO #TargetsToUpdate
    SELECT 
        b.BLoyalty_PointEarnedID,
        b.BuildLoyaltyOrReferralMCodeCheckid,
        b.Code1,
        b.Code2,
        b.SST_id,
        b.compid,
        b.Points,
        b.Cash,
        ISNULL(b.Service_ID, CorrectSST.Resolved_Service_ID) AS Service_ID,
        CorrectSST.SST_Id AS Resolved_SST_Id,
        CorrectSST.CorrectPoints AS Resolved_Points,
        CorrectSST.CorrectCash AS Resolved_Cash,
        CorrectSST.Comp_ID AS Resolved_Comp_ID,
        CorrectSST.Resolved_Service_ID
    FROM dbo.BLoyaltyPointsEarned b WITH (NOLOCK)
    INNER JOIN dbo.M_Code mc WITH (NOLOCK) ON mc.Code1 = TRY_CAST(b.Code1 AS NUMERIC(18,0)) AND mc.Code2 = TRY_CAST(b.Code2 AS NUMERIC(18,0))
    OUTER APPLY (
        SELECT TOP 1 sst.SST_Id, sst.Subscribe_Id, pr.Comp_ID, sst.Points AS CorrectPoints, sst.IsCash AS CorrectCash, ss2.Service_ID AS Resolved_Service_ID
        FROM dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK)
        INNER JOIN dbo.M_ServiceSubscription ss2 WITH (NOLOCK) ON sst.Subscribe_Id = ss2.Subscribe_Id
        INNER JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = ss2.Pro_ID
        WHERE ss2.Pro_ID = mc.Pro_ID
          AND (b.Service_ID IS NULL OR ss2.Service_ID = b.Service_ID)
          AND ss2.IsActive = 1 AND ISNULL(ss2.IsDelete, 0) = 0
          AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
          AND (
              sst.SST_Id = b.SST_id
              OR 
              (
                  (b.SST_id IS NULL OR NOT EXISTS (
                      SELECT 1 FROM dbo.M_ServiceSubscriptionTrans sst3 WITH (NOLOCK) WHERE sst3.SST_Id = b.SST_id
                  ))
                  AND (
                      ss2.start_order IS NULL 
                      OR (mc.Series_Order * 10000 + mc.Series_Serial) BETWEEN (ss2.start_order * 10000 + ss2.start_series) AND (ss2.end_order * 10000 + ss2.end_series)
                  )
              )
          )
        ORDER BY CASE WHEN sst.SST_Id = b.SST_id THEN 0 ELSE 1 END, sst.Entry_Date DESC
    ) CorrectSST
    WHERE b.compid = @CompId
      AND (
          b.Service_ID IS NULL 
          OR b.Service_ID IN ('SRV1001', 'SRV1029', 'SRV1005')
      )
      AND (
          -- If points-based, points is null or 0
          (ISNULL(b.Service_ID, CorrectSST.Resolved_Service_ID) IN ('SRV1001', 'SRV1029') AND (b.Points IS NULL OR b.Points = 0))
          OR
          -- If cash-based, cash is null or 0
          (ISNULL(b.Service_ID, CorrectSST.Resolved_Service_ID) = 'SRV1005' AND (b.Cash IS NULL OR b.Cash = 0))
      );

    -- 5. Dry Run Preview of Updates
    IF @IsDryRun = 1
    BEGIN
        PRINT '--- DRY RUN PREVIEW: Null/Zero Points/Cash Updates for ' + @CompId + ' ---';
        SELECT 
            BLoyalty_PointEarnedID,
            Code1,
            Code2,
            Service_ID,
            CurrentPoints,
            CurrentCash,
            Resolved_SST_Id,
            Resolved_Points AS NewPointsValue,
            Resolved_Cash AS NewCashValue,
            compid AS CurrentCompid,
            Resolved_Comp_ID AS NewCompid
        FROM #TargetsToUpdate;
        
        DROP TABLE IF EXISTS #IncompleteScans, #TargetsToUpdate;
        RETURN;
    END

    -- 6. Real Update Execution (Phase 2 execution)
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @LoyaltyUpdated INT = 0;
        DECLARE @DetailsUpdated INT = 0;
        DECLARE @CodeCheckUpdated INT = 0;
        DECLARE @EnqUpdated INT = 0;

        -- 1. Update BLoyaltyPointsEarned
        UPDATE b
        SET b.Points = CASE WHEN t.Resolved_Service_ID IN ('SRV1001', 'SRV1029') THEN t.Resolved_Points ELSE 0 END,
            b.Cash = CASE 
                WHEN t.Resolved_Service_ID = 'SRV1005' THEN CASE WHEN ISNULL(t.Resolved_Cash, 0) = 0 THEN t.Resolved_Points ELSE t.Resolved_Cash END
                WHEN t.Resolved_Service_ID = 'SRV1029' THEN t.Resolved_Points 
                ELSE 0 
            END,
            b.SST_id = t.Resolved_SST_Id,
            b.Service_ID = t.Resolved_Service_ID,
            b.compid = t.Resolved_Comp_ID,
            b.UpdateDate = GETDATE()
        FROM dbo.BLoyaltyPointsEarned b
        INNER JOIN #TargetsToUpdate t ON b.BLoyalty_PointEarnedID = t.BLoyalty_PointEarnedID;

        SET @LoyaltyUpdated = @@ROWCOUNT;

        -- 2. Update ConsumerPointsCashDetails
        UPDATE c
        SET c.Points = CASE WHEN t.Resolved_Service_ID IN ('SRV1001', 'SRV1029') THEN t.Resolved_Points ELSE 0 END,
            c.Cash = CASE 
                WHEN t.Resolved_Service_ID = 'SRV1005' THEN CASE WHEN ISNULL(t.Resolved_Cash, 0) = 0 THEN t.Resolved_Points ELSE t.Resolved_Cash END
                WHEN t.Resolved_Service_ID = 'SRV1029' THEN t.Resolved_Points 
                ELSE 0 
            END,
            c.SST_Id = t.Resolved_SST_Id,
            c.Comp_id = t.Resolved_Comp_ID
        FROM dbo.ConsumerPointsCashDetails c
        INNER JOIN #TargetsToUpdate t ON c.PE_ID = t.BLoyalty_PointEarnedID;

        SET @DetailsUpdated = @@ROWCOUNT;

        -- 3. Update BuiltLoyaltyMCodeCheck
        UPDATE mcc
        SET mcc.sst_id = t.Resolved_SST_Id,
            mcc.IsPointsAssigned = 1
        FROM dbo.BuiltLoyaltyMCodeCheck mcc
        INNER JOIN #TargetsToUpdate t ON mcc.Pkid = t.BuildLoyaltyOrReferralMCodeCheckid;

        SET @CodeCheckUpdated = @@ROWCOUNT;

        -- 4. Update Pro_Enq (Inquiry history)
        UPDATE pe
        SET pe.SST_ID = t.Resolved_SST_Id,
            pe.Comp_ID = t.Resolved_Comp_ID
        FROM dbo.Pro_Enq pe
        INNER JOIN #TargetsToUpdate t ON pe.Received_Code1 = t.Code1 AND pe.Received_Code2 = t.Code2;

        SET @EnqUpdated = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return execution summary report
        SELECT 
            @LoyaltyUpdated AS BLoyaltyPointsEarned_Rows_Updated,
            @DetailsUpdated AS ConsumerPointsCashDetails_Rows_Updated,
            @CodeCheckUpdated AS BuiltLoyaltyMCodeCheck_Rows_Updated,
            @EnqUpdated AS Pro_Enq_Rows_Updated,
            'Success' AS Execution_Status;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

    DROP TABLE IF EXISTS #IncompleteScans, #TargetsToUpdate;
END
