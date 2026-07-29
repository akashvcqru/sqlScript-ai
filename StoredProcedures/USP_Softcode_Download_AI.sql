IF OBJECT_ID('dbo.USP_Softcode_Download_AI', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.USP_Softcode_Download_AI;
END
GO

CREATE PROCEDURE [dbo].[USP_Softcode_Download_AI]
    @ProID VARCHAR(50),
    @CompID VARCHAR(50),
    @Qty INT,
    @Frequency VARCHAR(50),
    @PointsVal INT,
    @ChkDiffPoint INT,
    @PointsData NVARCHAR(MAX),
    @MfdDate VARCHAR(50),
    @Mrp DECIMAL(18,2),
    @IsDefault INT,
    @LabelCode VARCHAR(50),
    @TrackingNo VARCHAR(50),
    @ProductRange VARCHAR(100) = NULL,
    @ServiceID VARCHAR(50) = 'SRV1001',
    @ProductQTY INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @TableName VARCHAR(50) = CASE WHEN @CompID = 'Comp-1693' THEN 'M_Code_PFL' ELSE 'M_Code' END;
        
        -- 1. Find last assigned series limits for this product
        DECLARE @lastOrder INT = 0, @lastSerial INT = 0;
        DECLARE @ParmDefinition NVARCHAR(500) = N'@ProID VARCHAR(50), @lastOrder INT OUTPUT, @lastSerial INT OUTPUT';
        DECLARE @sql NVARCHAR(MAX);
        
        SET @sql = N'SELECT TOP 1 @lastOrder = Series_Order, @lastSerial = Series_Serial 
                     FROM ' + QUOTENAME(@TableName) + N' 
                     WHERE Pro_ID = @ProID AND Series_Order IS NOT NULL AND Series_Serial IS NOT NULL 
                     ORDER BY Series_Order DESC, Series_Serial DESC';
        EXEC sp_executesql @sql, @ParmDefinition, @ProID = @ProID, @lastOrder = @lastOrder OUTPUT, @lastSerial = @lastSerial OUTPUT;
        
        DECLARE @startOrder INT = 0, @startSerial INT = 0;
        IF @lastOrder IS NOT NULL OR @lastSerial IS NOT NULL
        BEGIN
            IF @lastSerial = 9999
            BEGIN
                SET @startOrder = @lastOrder + 1;
                SET @startSerial = 0;
            END
            ELSE
            BEGIN
                SET @startOrder = @lastOrder;
                SET @startSerial = @lastSerial + 1;
            END
        END
        DECLARE @startAbsoluteIndex INT = @startOrder * 10000 + @startSerial;
        
        -- 2. Select TOP Qty available code Row_IDs, Code1, and Code2
        CREATE TABLE #SelectedCodes (
            RowNumber INT IDENTITY(1,1),
            RowID BIGINT,
            Code1 VARCHAR(50),
            Code2 VARCHAR(50),
            SeriesOrder INT,
            SeriesSerial INT
        );
        
        SET @sql = N'INSERT INTO #SelectedCodes (RowID, Code1, Code2, SeriesOrder, SeriesSerial)
                     SELECT TOP (@Qty) Row_ID, Code1, Code2, 0, 0 
                     FROM ' + QUOTENAME(@TableName) + N' 
                     WHERE Pro_ID IS NULL 
                       AND (Print_Status IS NULL OR Print_Status = 0)
                       AND ISNULL([Use_Count],0) = 0 
                       AND DispatchFlag IS NULL 
                       AND ISNULL(ScrapeFlag,0) = 0
                     ORDER BY Row_ID ASC';
        EXEC sp_executesql @sql, N'@Qty INT', @Qty = @Qty;
        
        DECLARE @SelectedCount INT;
        SELECT @SelectedCount = COUNT(*) FROM #SelectedCodes;
        IF @SelectedCount < @Qty
        BEGIN
            RAISERROR('Not sufficient code to print LABELS. Kindly first generate the CODES and then proceed further.', 16, 1);
        END
        
        -- 3. Calculate sequence
        UPDATE #SelectedCodes
        SET SeriesOrder = (@startAbsoluteIndex + RowNumber - 1) / 10000,
            SeriesSerial = (@startAbsoluteIndex + RowNumber - 1) % 10000;
            
        DECLARE @startOrderVal INT, @startSeriesVal INT, @endOrderVal INT, @endSeriesVal INT;
        SELECT TOP 1 @startOrderVal = SeriesOrder, @startSeriesVal = SeriesSerial FROM #SelectedCodes ORDER BY RowNumber ASC;
        SELECT TOP 1 @endOrderVal = SeriesOrder, @endSeriesVal = SeriesSerial FROM #SelectedCodes ORDER BY RowNumber DESC;
        
        -- 4. Ensure M_ServiceSubscription and M_ServiceSubscriptiontrans record for this Product and range
        DECLARE @subExists INT = 0;
        DECLARE @currentSubId VARCHAR(50) = '';
        DECLARE @currentServiceId VARCHAR(50) = '';
        DECLARE @subDateFrom DATETIME = NULL;
        DECLARE @subDateTo DATETIME = NULL;

        SELECT TOP 1 @subExists = 1, @currentSubId = Subscribe_Id, @currentServiceId = Service_ID, @subDateFrom = DateFrom, @subDateTo = DateTo
        FROM M_ServiceSubscription
        WHERE Pro_ID = @ProID 
          AND Comp_ID = @CompID 
          AND Service_ID = @ServiceID
          AND start_order = @startOrderVal 
          AND start_series = @startSeriesVal 
          AND end_order = @endOrderVal 
          AND end_series = @endSeriesVal;

        IF @subExists = 0
        BEGIN
            -- Generate new subscription ID
            DECLARE @newSubId VARCHAR(50) = 'SUB10001';
            DECLARE @pfx VARCHAR(50) = 'SUB', @st BIGINT = 10001;
            SELECT TOP 1 @pfx = PrPrefix, @st = TRY_CAST(PrStart AS BIGINT) FROM Code_Gen WHERE Prfor = 'Subscription';
            SET @newSubId = @pfx + CAST(@st AS VARCHAR(50));

            -- Try to get template subscription row
            DECLARE @templateExists INT = 0;
            SELECT TOP 1 @templateExists = 1 FROM M_ServiceSubscription WHERE Pro_ID = @ProID AND Comp_ID = @CompID AND Service_ID = @ServiceID;
            
            IF @templateExists = 1
            BEGIN
                -- Insert by cloning the template row
                DECLARE @columnsList NVARCHAR(MAX) = '';
                DECLARE @selectList NVARCHAR(MAX) = '';
                
                SELECT 
                    @columnsList = @columnsList + '[' + COLUMN_NAME + '],',
                    @selectList = @selectList + 
                        CASE 
                            WHEN COLUMN_NAME = 'Subscribe_Id' THEN '''' + @newSubId + ''','
                            WHEN COLUMN_NAME = 'start_order' THEN CAST(@startOrderVal AS VARCHAR(50)) + ','
                            WHEN COLUMN_NAME = 'end_order' THEN CAST(@endOrderVal AS VARCHAR(50)) + ','
                            WHEN COLUMN_NAME = 'start_series' THEN CAST(@startSeriesVal AS VARCHAR(50)) + ','
                            WHEN COLUMN_NAME = 'end_series' THEN CAST(@endSeriesVal AS VARCHAR(50)) + ','
                            WHEN COLUMN_NAME = 'EntryDate' THEN 'GETDATE(),'
                            WHEN COLUMN_NAME = 'IsActive' THEN '1,'
                            WHEN COLUMN_NAME = 'IsAdminVerify' THEN '1,'
                            WHEN COLUMN_NAME = 'DateFrom' THEN 'ISNULL(DateFrom, ' + N'''' + @MfdDate + N'''' + '),'
                            WHEN COLUMN_NAME = 'DateTo' THEN 'ISNULL(DateTo, DATEADD(month, ISNULL(PlanMasterPeriod, 6), ' + N'''' + @MfdDate + N'''' + ')),'
                            ELSE '[' + COLUMN_NAME + '],'
                        END
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = 'M_ServiceSubscription' AND TABLE_SCHEMA = 'dbo';

                SET @columnsList = SUBSTRING(@columnsList, 1, LEN(@columnsList) - 1);
                SET @selectList = SUBSTRING(@selectList, 1, LEN(@selectList) - 1);

                SET @sql = N'INSERT INTO M_ServiceSubscription (' + @columnsList + N') 
                             SELECT TOP 1 ' + @selectList + N' FROM M_ServiceSubscription 
                             WHERE Pro_ID = @ProID AND Comp_ID = @CompID AND Service_ID = @ServiceID';
                EXEC sp_executesql @sql, N'@ProID VARCHAR(50), @CompID VARCHAR(50), @ServiceID VARCHAR(50)', @ProID = @ProID, @CompID = @CompID, @ServiceID = @ServiceID;
            END
            ELSE
            BEGIN
                SELECT TOP 1 @templateExists = 1 FROM M_ServiceSubscription WHERE Pro_ID = @ProID AND Comp_ID = @CompID;
                IF @templateExists = 1
                BEGIN
                    DECLARE @columnsList2 NVARCHAR(MAX) = '';
                    DECLARE @selectList2 NVARCHAR(MAX) = '';
                    
                    SELECT 
                        @columnsList2 = @columnsList2 + '[' + COLUMN_NAME + '],',
                        @selectList2 = @selectList2 + 
                            CASE 
                                WHEN COLUMN_NAME = 'Subscribe_Id' THEN '''' + @newSubId + ''','
                                WHEN COLUMN_NAME = 'Service_ID' THEN '''' + @ServiceID + ''','
                                WHEN COLUMN_NAME = 'start_order' THEN CAST(@startOrderVal AS VARCHAR(50)) + ','
                                WHEN COLUMN_NAME = 'end_order' THEN CAST(@endOrderVal AS VARCHAR(50)) + ','
                                WHEN COLUMN_NAME = 'start_series' THEN CAST(@startSeriesVal AS VARCHAR(50)) + ','
                                WHEN COLUMN_NAME = 'end_series' THEN CAST(@endSeriesVal AS VARCHAR(50)) + ','
                                WHEN COLUMN_NAME = 'EntryDate' THEN 'GETDATE(),'
                                WHEN COLUMN_NAME = 'IsActive' THEN '1,'
                                WHEN COLUMN_NAME = 'IsAdminVerify' THEN '1,'
                                WHEN COLUMN_NAME = 'DateFrom' THEN 'ISNULL(DateFrom, ' + N'''' + @MfdDate + N'''' + '),'
                                WHEN COLUMN_NAME = 'DateTo' THEN 'ISNULL(DateTo, DATEADD(month, ISNULL(PlanMasterPeriod, 6), ' + N'''' + @MfdDate + N'''' + ')),'
                                ELSE '[' + COLUMN_NAME + '],'
                            END
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = 'M_ServiceSubscription' AND TABLE_SCHEMA = 'dbo';

                    SET @columnsList2 = SUBSTRING(@columnsList2, 1, LEN(@columnsList2) - 1);
                    SET @selectList2 = SUBSTRING(@selectList2, 1, LEN(@selectList2) - 1);

                    SET @sql = N'INSERT INTO M_ServiceSubscription (' + @columnsList2 + N') 
                                 SELECT TOP 1 ' + @selectList2 + N' FROM M_ServiceSubscription 
                                 WHERE Pro_ID = @ProID AND Comp_ID = @CompID';
                    EXEC sp_executesql @sql, N'@ProID VARCHAR(50), @CompID VARCHAR(50)', @ProID = @ProID, @CompID = @CompID;
                END
                ELSE
                BEGIN
                    INSERT INTO M_ServiceSubscription 
                    (Subscribe_Id, Service_ID, Comp_ID, Pro_ID, Plan_ID, PlanName, PlanMasterPeriod, PlanSalePeriod, PlanMasterPrice, PlanSalePrice, start_order, start_series, end_order, end_series, DateFrom, DateTo, EntryDate, IsActive, IsDelete, IsAdminVerify, TransType)
                    VALUES 
                    (@newSubId, @ServiceID, @CompID, @ProID, 'PLN1002', 'SILVER PLAN', 6, 0, 0, 0, @startOrderVal, @startSeriesVal, @endOrderVal, @endSeriesVal, CAST(@MfdDate AS DATETIME), DATEADD(month, 6, CAST(@MfdDate AS DATETIME)), GETDATE(), 1, 0, 1, 'Service');
                END
            END

            -- Update Code_Gen for Subscription seed
            UPDATE Code_Gen SET PrStart = TRY_CAST(PrStart AS BIGINT) + 1 WHERE Prfor = 'Subscription';

            SET @currentSubId = @newSubId;
            SET @currentServiceId = @ServiceID;
            
            SELECT TOP 1 @subDateFrom = DateFrom, @subDateTo = DateTo 
            FROM M_ServiceSubscription 
            WHERE Subscribe_Id = @newSubId;
        END

        -- 5. Insert M_ServiceSubscriptionTrans record
        DECLARE @transDtFrom DATETIME = ISNULL(@subDateFrom, CAST(@MfdDate AS DATETIME));
        DECLARE @transDtTo DATETIME = ISNULL(@subDateTo, DATEADD(month, 6, @transDtFrom));
        
        INSERT INTO M_ServiceSubscriptionTrans 
        (Subscribe_Id, Points, Frequency, DateFrom, DateTo, Entry_Date, IsActive, IsDelete, IsCashConvert, IsCash, AmtType, Minval, Maxval, Comments)
        VALUES 
        (@currentSubId, @PointsVal, @Frequency, @transDtFrom, @transDtTo, GETDATE(), 1, 0, 0, 0, 'Fixed', 0, 0, '');

        -- 6. Insert into T_Pro
        DECLARE @seriesLimitStr VARCHAR(100) = 'From ' + RIGHT('0000' + CAST(@startOrderVal AS VARCHAR(4)), 4) + '-' + RIGHT('0000' + CAST(@startSeriesVal AS VARCHAR(4)), 4) + ' To ' + RIGHT('0000' + CAST(@endOrderVal AS VARCHAR(4)), 4) + '-' + RIGHT('0000' + CAST(@endSeriesVal AS VARCHAR(4)), 4);
        DECLARE @newTProRowId BIGINT = 0;
        
        INSERT INTO T_Pro (Pro_ID, Batch_No, MRP, Mfd_Date, Exp_Date, Comments, Entry_Date, Series_Limit)
        VALUES (@ProID, @TrackingNo, @Mrp, CAST(@MfdDate AS DATETIME), @transDtTo, 'Soft Code Batch', GETDATE(), @seriesLimitStr);
        
        SET @newTProRowId = SCOPE_IDENTITY();

        -- 7. Ensure M_Label_Request
        IF NOT EXISTS (SELECT 1 FROM M_Label_Request WHERE Tracking_No = @TrackingNo)
        BEGIN
            INSERT INTO M_Label_Request (Pro_ID, Qty, Label_Code, Entry_Date, Flag, Tracking_No, PrintType)
            VALUES (@ProID, @Qty, @LabelCode, GETDATE(), 1, @TrackingNo, '2');
        END

        -- 8. Update M_Code / M_Code_PFL
        DECLARE @batchNoValue VARCHAR(50) = CASE WHEN @newTProRowId > 0 THEN CAST(@newTProRowId AS VARCHAR(50)) ELSE @TrackingNo END;
        
        SET @sql = N'UPDATE t 
                     SET t.Pro_ID = @ProID,
                         t.Batch_No = @BatchNo,
                         t.Print_Status = 1,
                         t.Use_type = ''L'',
                         t.Print_Date = GETDATE(),
                         t.Allot_Date = GETDATE(),
                         t.LabelRequestId = @LabelRequestId,
                         t.Series_Order = s.SeriesOrder,
                         t.Series_Serial = s.SeriesSerial,
                         t.DispatchFlag = 1,
                         t.ReceiveFlag = 1
                     FROM ' + QUOTENAME(@TableName) + N' t 
                     INNER JOIN #SelectedCodes s ON t.Row_ID = s.RowID';
        EXEC sp_executesql @sql, N'@ProID VARCHAR(50), @BatchNo VARCHAR(50), @LabelRequestId VARCHAR(50)', @ProID = @ProID, @BatchNo = @batchNoValue, @LabelRequestId = @TrackingNo;

        -- 9. Call Stored Procedure InsertUserFrequency
        DECLARE @xmlData XML;
        SET @xmlData = (
            SELECT 
                s.SeriesOrder AS [@Series_Order],
                s.SeriesSerial AS [@Series_Serial],
                s.Code1 AS [@Code1],
                s.Code2 AS [@Code2],
                1 AS [@DispatchFlag],
                1 AS [@ReceiveFlag],
                s.RowNumber AS [@index],
                j.UserType AS [@UserTypeRole],
                j.Point AS [@AssignPoint],
                0 AS [@Use_count],
                @ProID AS [@Pro_id],
                @CompID AS [@Comp_id],
                @Frequency AS [@Frequency],
                @TrackingNo AS [@TrackingId]
            FROM #SelectedCodes s
            CROSS JOIN (
                SELECT UserType, Point
                FROM OPENJSON(@PointsData)
                WITH (
                    UserType VARCHAR(50) '$.UserType',
                    Point VARCHAR(50) '$.Point'
                )
            ) j
            FOR XML PATH('id'), ROOT('Tab')
        );
        
        DECLARE @xmlStr NVARCHAR(MAX) = CAST(@xmlData AS NVARCHAR(MAX));
        DECLARE @TempInserted TABLE (InsertedId INT);
        INSERT INTO @TempInserted (InsertedId)
        EXEC InsertUserFrequency @XmlData = @xmlStr;

        -- 10. Update tbl_SoftCodegenrate_Details
        IF @IsDefault = 1
        BEGIN
            UPDATE tbl_SoftCodegenrate_Details SET Isdefault = 0 WHERE Pro_id = @ProID AND Comp_id = @CompID;
        END

        INSERT INTO tbl_SoftCodegenrate_Details 
        (Pro_id, Comp_id, NOOfLabelRequest, Frequency, ProductRange, ProductQTY, Manufacture_date, TrackingId, chkdiffrentpoint, pointsdata, datefrom, dateto, MRP, Isdefault)
        VALUES 
        (@ProID, @CompID, @Qty, @Frequency, @ProductRange, ISNULL(@ProductQTY, @Qty), CAST(@MfdDate AS DATETIME), @TrackingNo, @ChkDiffPoint, @PointsData, @transDtFrom, @transDtTo, @Mrp, @IsDefault);

        -- 11. Update Code_Gen for LabelTracking seed
        UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'LabelTracking';

        COMMIT TRANSACTION;
        
        -- Return details to C#
        SELECT 
            @TrackingNo AS TrackingNo, 
            @batchNoValue AS BatchNo, 
            @startOrderVal AS StartOrder, 
            @startSeriesVal AS StartSeries, 
            @endOrderVal AS EndOrder, 
            @endSeriesVal AS EndSeries, 
            CONVERT(VARCHAR(50), @transDtFrom, 120) AS DateFrom, 
            CONVERT(VARCHAR(50), @transDtTo, 120) AS DateTo;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
