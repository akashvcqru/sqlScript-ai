SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Modified:    2026-04-29
-- Description: Ultra-optimized Live scanning tracking report using per-company flat tables.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetLiveScanTracking_AI]
    @Comp_ID NVARCHAR(50),
    @datePreset NVARCHAR(20) = 'month',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ServiceID NVARCHAR(50) = NULL,
    @IsExport BIT = 0,
    @Search NVARCHAR(100) = NULL,
    @StateFilter NVARCHAR(100) = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,
    @DialModeFilter NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @PageNumber IS NULL OR @PageNumber <= 0 SET @PageNumber = 1;
    IF @PageSize IS NULL OR @PageSize <= 0 SET @PageSize = 10;
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' SET @StateFilter = NULL;

    -- 1. Construct Dynamic Table Name
    DECLARE @CleanCompID NVARCHAR(100) = REPLACE(REPLACE(@Comp_ID, ' ', '_'), '-', '_');
    DECLARE @TableName NVARCHAR(256) = N'[GetLiveScanTracking_optimizedata_' + @CleanCompID + N']';
    DECLARE @Sql NVARCHAR(MAX);

    -- 2. Schema Definition (Internal versioning to handle auto-migration)
    -- If you add columns here, the SP will automatically drop and recreate the table.
    DECLARE @RequiredColumns TABLE (ColName NVARCHAR(128), ColDef NVARCHAR(MAX));
    INSERT INTO @RequiredColumns (ColName, ColDef) VALUES 
    ('ScanTimestamp', 'DATETIME'), ('Product', 'NVARCHAR(250)'), ('VariantSKU', 'NVARCHAR(50)'),
    ('BatchNo', 'NVARCHAR(100)'), ('UniqueCode', 'NVARCHAR(100)'), ('ScanResult', 'NVARCHAR(50)'),
    ('FirstOrRepeat', 'NVARCHAR(20)'), ('TotalScansForUID', 'INT'), ('City', 'NVARCHAR(100)'),
    ('State', 'NVARCHAR(100)'), ('PinCode', 'NVARCHAR(20)'), ('Channel', 'NVARCHAR(50)'),
    ('DistributorRetailer', 'NVARCHAR(250)'), ('ManufacturingDate', 'DATETIME'), ('ExpiryDate', 'DATETIME'),
    ('RiskAbuseFlag', 'NVARCHAR(20)'), ('ClaimID', 'NVARCHAR(50)'), ('ConsumerMobile', 'NVARCHAR(20)'),
    ('Latitude', 'NVARCHAR(50)'), ('Longitude', 'NVARCHAR(50)'),
    ('Is_Success', 'INT'), ('Dial_Mode', 'NVARCHAR(50)');

    -- 3. Check for Schema Changes or Missing Table
    DECLARE @TableExists INT = 0;
    SET @Sql = N'IF OBJECT_ID(''' + @TableName + N''') IS NOT NULL SET @exists = 1 ELSE SET @exists = 0;';
    EXEC sp_executesql @Sql, N'@exists INT OUTPUT', @TableExists OUTPUT;

    IF @TableExists = 1
    BEGIN
        DECLARE @MissingCols INT = 0;
        SELECT @MissingCols = COUNT(*) 
        FROM @RequiredColumns rc
        LEFT JOIN sys.columns c ON c.object_id = OBJECT_ID(@TableName) AND c.name = rc.ColName
        WHERE c.name IS NULL;

        IF @MissingCols > 0
        BEGIN
            -- Schema Mismatch: Drop table to force full refresh
            SET @Sql = N'DROP TABLE ' + @TableName;
            EXEC(@Sql);
            SET @TableExists = 0;
        END
    END

    -- 4. Create Table if it doesn't exist
    IF @TableExists = 0
    BEGIN
        DECLARE @ColList NVARCHAR(MAX) = '';
        SELECT @ColList = @ColList + '[' + ColName + '] ' + ColDef + ', ' FROM @RequiredColumns;
        SET @ColList = LEFT(@ColList, LEN(@ColList) - 1);

        SET @Sql = N'CREATE TABLE ' + @TableName + N' (' + @ColList + N'); ' +
                   N'CREATE INDEX IX_ScanTime ON ' + @TableName + N'(ScanTimestamp DESC); ' +
                   N'CREATE INDEX IX_UniqueCode ON ' + @TableName + N'(UniqueCode);';
        EXEC(@Sql);
    END

    -- 5. Incremental Sync
    DECLARE @LastSync DATETIME;
    SET @Sql = N'SELECT @LastSync = MAX(ScanTimestamp) FROM ' + @TableName;
    EXEC sp_executesql @Sql, N'@LastSync DATETIME OUTPUT', @LastSync OUTPUT;
    
    -- If table was empty or dropped, sync from company start date
    IF @LastSync IS NULL
    BEGIN
        SELECT @LastSync = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @Comp_ID;
    END

    -- Prepare Insert Statement
    SET @Sql = N'
    INSERT INTO ' + @TableName + N' (ScanTimestamp, Product, VariantSKU, BatchNo, UniqueCode, ScanResult, FirstOrRepeat, TotalScansForUID, City, State, PinCode, Channel, DistributorRetailer, RiskAbuseFlag, ConsumerMobile, Latitude, Longitude, Is_Success, Dial_Mode)
    SELECT 
        pe.Enq_Date,
        pr.Pro_Name,
        pr.Pro_ID,
        mc.Batch_No,
        ISNULL(pe.Received_Code1, '''') + ISNULL(pe.Received_Code2, ''''),
        CASE WHEN pe.Is_Success = 1 THEN ''Genuine'' ELSE ''Duplicate/Invalid'' END,
        CASE WHEN mc.Use_Count <= 1 THEN ''First'' ELSE ''Repeat'' END,
        ISNULL(mc.Use_Count, 0),
        ISNULL(pe.City, ''''),
        ISNULL(pe.state, ''''),
        ISNULL(pe.PinCode, ''''),
        ISNULL(pe.Dial_Mode, ''Web''),
        ISNULL(mcn.FirmName, mcn.SellerName),
        CASE WHEN mc.Use_Count > 10 THEN ''High Risk'' WHEN mc.Use_Count > 5 THEN ''Medium Risk'' ELSE ''Low Risk'' END,
        pe.MobileNo,
        pe.Latitude,
        pe.Longitude,
        pe.Is_Success,
        pe.Dial_Mode
    FROM Pro_Enq pe
    LEFT JOIN M_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
    LEFT JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
    LEFT JOIN M_Consumer mcn ON mcn.MobileNo = pe.MobileNo
    WHERE pe.Comp_ID = @CompID AND pe.Enq_Date > @LastSync;';

    EXEC sp_executesql @Sql, N'@CompID NVARCHAR(50), @LastSync DATETIME', @Comp_ID, @LastSync;

    -- 6. Date Range Handling
    DECLARE @finalFromDate DATETIME, @finalToDate DATETIME
    IF (@datePreset IS NULL OR LTRIM(RTRIM(@datePreset)) = '' OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null')
        SET @datePreset = 'month'
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @today DATE = CAST(GETDATE() AS DATE); SET DATEFIRST 1;
    DECLARE @tomorrow DATE = DATEADD(DAY, 1, @today);

    IF @datePreset = 'ALL' BEGIN SET @finalFromDate = '2015-01-01'; SET @finalToDate = @tomorrow END
    ELSE IF @datePreset = 'CUSTOM' BEGIN SET @finalFromDate = @FromDate; SET @finalToDate = DATEADD(DAY, 1, @ToDate) END
    ELSE BEGIN
        IF @datePreset = 'TODAY' BEGIN SET @finalFromDate = @today; SET @finalToDate = @tomorrow END
        ELSE IF @datePreset = 'YESTERDAY' OR @datePreset = 'LASTDAY' BEGIN SET @finalFromDate = DATEADD(DAY,-1,@today); SET @finalToDate = @today END
        ELSE IF @datePreset = 'WEEK' BEGIN SET @finalFromDate = DATEADD(DAY,1-DATEPART(WEEKDAY,@today),@today); SET @finalToDate = @tomorrow END
        ELSE IF @datePreset = 'LASTWEEK' BEGIN DECLARE @thisMonday DATE = DATEADD(DAY,1-DATEPART(WEEKDAY,@today),@today); SET @finalFromDate = DATEADD(DAY,-7,@thisMonday); SET @finalToDate = @thisMonday END
        ELSE IF @datePreset = 'MONTH' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1); SET @finalToDate = @tomorrow END
        ELSE IF @datePreset = 'LASTMONTH' BEGIN SET @finalFromDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1) END
        ELSE IF @datePreset = 'QUARTER' BEGIN SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0); SET @finalToDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0) END
        ELSE IF @datePreset = 'YEAR' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1); SET @finalToDate = @tomorrow END
        ELSE IF @datePreset = 'LASTYEAR' BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE())-1, 1, 1); SET @finalToDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1) END
        ELSE BEGIN SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1); SET @finalToDate = @tomorrow END
    END

    -- 7. Final Optimized Select
    SET @Sql = N'
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ScanTimestamp DESC) AS SNo,
        *,
        COUNT(*) OVER() AS TotalRecords
    FROM ' + @TableName + N'
    WHERE (ScanTimestamp >= @fFrom AND ScanTimestamp < @fTo)
      AND (@StateFilter IS NULL OR [State] = @StateFilter)
      AND (@DialModeFilter IS NULL OR [Dial_Mode] = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL OR
          (@CodeStatusFilter = ''Verified'' AND Is_Success = 1) OR
          (@CodeStatusFilter = ''Already Scanned'' AND Is_Success = 2) OR
          (@CodeStatusFilter = ''Invalid'' AND Is_Success NOT IN (1, 2))
      )
      AND (@Search IS NULL 
           OR ConsumerMobile LIKE ''%''+@Search+''%'' 
           OR UniqueCode LIKE ''%''+@Search+''%'' 
           OR Product LIKE ''%''+@Search+''%'')
    ORDER BY ScanTimestamp DESC
    OFFSET (@PageNumber-1)*@PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport=1 THEN 1000000 ELSE @PageSize END) ROWS ONLY;';

    EXEC sp_executesql @Sql, 
        N'@fFrom DATETIME, @fTo DATETIME, @StateFilter NVARCHAR(100), @Search NVARCHAR(100), @PageNumber INT, @PageSize INT, @IsExport BIT, @DialModeFilter NVARCHAR(50), @CodeStatusFilter NVARCHAR(20)',
        @finalFromDate, @finalToDate, @StateFilter, @Search, @PageNumber, @PageSize, @IsExport, @DialModeFilter, @CodeStatusFilter;
END
GO
