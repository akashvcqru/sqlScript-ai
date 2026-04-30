USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetLiveScanTracking_AI]    Script Date: 4/27/2026 4:25:16 PM ******/
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
ALTER   PROCEDURE [dbo].[USP_GetLiveScanTracking_AI]
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
    @KYCStatusFilter NVARCHAR(50) = NULL,
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
        IF @datePreset IS NULL OR @datePreset = '' SET @datePreset = 'week'
        
        DECLARE @today DATE = CAST(GETDATE() AS DATE)

        IF @MissingCols > 0
        BEGIN
            SET @finalFromDate = @today
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastday'
        BEGIN
            SET @finalFromDate = DATEADD(DAY, -1, @today)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(@today AS DATETIME))
        END
        ELSE IF @datePreset = 'week'
        BEGIN
            -- Start of current week (Monday)
            SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastweek'
        BEGIN
            -- Start of last week (Monday)
            DECLARE @thisMonday DATE = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalFromDate = DATEADD(DAY, -7, @thisMonday)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(@thisMonday AS DATETIME))
        END
        ELSE IF @datePreset = 'month'
        BEGIN
            SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastmonth'
        BEGIN
            DECLARE @firstOfThisMonth DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
            SET @finalFromDate = DATEADD(MONTH, -1, @firstOfThisMonth)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(@firstOfThisMonth AS DATETIME))
        END
        ELSE IF @datePreset = 'quarter'
        BEGIN
            SET @finalFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'year'
        BEGIN
            SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
            SET @finalToDate = GETDATE()
        END
        ELSE IF @datePreset = 'lastyear'
        BEGIN
            SET @finalFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1)
            SET @finalToDate = DATEADD(SECOND, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME))
        END
        ELSE
        BEGIN
            -- Default to week
            SET @finalFromDate = DATEADD(DAY, -(DATEDIFF(DAY, 0, GETDATE()) % 7), @today)
            SET @finalToDate = GETDATE()
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

    ;WITH ResultCTE AS (
        SELECT 
            pe.Enq_Date AS ScanTimestamp,
            pr.Pro_Name AS Product,
            pr.Pro_ID AS VariantSKU,
            mc.Batch_No AS BatchNo,
            ISNULL(pe.Received_Code1, '') + ISNULL(pe.Received_Code2, '') AS UniqueCode,
            CASE 
                WHEN mc.Code1 IS NULL THEN 'Invalid'
                WHEN pe.Is_Success = 2 THEN 'Duplicate'
                WHEN pe.Is_Success = 1 THEN 'Genuine'
                ELSE 'Invalid' 
            END AS ScanResult,
            CASE WHEN mc.Use_Count <= 1 THEN 'First' ELSE 'Repeat' END AS FirstOrRepeat,
            ISNULL(mc.Use_Count, 0) AS TotalScansForUID,
            ISNULL(pe.City, '') AS City,
            ISNULL(pe.state, '') AS State,
            ISNULL(pe.PinCode, '') AS PinCode,
            ISNULL(pe.Dial_Mode, 'Web') AS Channel,
            ISNULL(mcn.FirmName, mcn.SellerName) AS DistributorRetailer,
            NULL AS ManufacturingDate, -- To be updated if table found
            NULL AS ExpiryDate,        -- To be updated if table found
            CASE 
                WHEN mc.Use_Count > 10 THEN 'High Risk' 
                WHEN mc.Use_Count > 5 THEN 'Medium Risk' 
                ELSE 'Low Risk' 
            END AS RiskAbuseFlag,
            NULL AS ClaimID,           -- To be joined with Claim table if needed
            pe.MobileNo AS ConsumerMobile,
            pe.Latitude,
            pe.Longitude,
            ROW_NUMBER() OVER (PARTITION BY pe.Row_ID ORDER BY (SELECT NULL)) AS DupRank
        FROM Pro_Enq pe
        LEFT JOIN #tempM_Code mc ON mc.Code1 = pe.Received_Code1 AND mc.Code2 = pe.Received_Code2
        LEFT JOIN Pro_Reg pr ON pr.Pro_ID = mc.Pro_ID
        LEFT JOIN M_Consumer mcn ON mcn.MobileNo = pe.MobileNo
        WHERE pe.Comp_ID = @Comp_ID and mcn.IsDelete = 0
          AND (@finalFromDate IS NULL OR pe.Enq_Date >= @finalFromDate)
          AND (@finalToDate IS NULL OR pe.Enq_Date <= @finalToDate)
    )
    SELECT 
        ROW_NUMBER() OVER (ORDER BY ScanTimestamp DESC) AS SNo,
        ScanTimestamp,
        Product,
        VariantSKU,
        BatchNo,
        UniqueCode,
        ScanResult,
        FirstOrRepeat,
        TotalScansForUID,
        City,
        State,
        PinCode,
        Channel,
        DistributorRetailer,
        ManufacturingDate,
        ExpiryDate,
        RiskAbuseFlag,
        ClaimID,
        ConsumerMobile,
        Latitude,
        Longitude,
        COUNT(*) OVER() AS TotalRecords
    FROM ResultCTE
    WHERE DupRank = 1
    ORDER BY ScanTimestamp DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
    OPTION (RECOMPILE);
END
