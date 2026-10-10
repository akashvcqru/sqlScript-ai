-- =========================================================================
-- Migration: 20261011_Create_TrackTraceScan_And_ActivityReport_AI.sql
-- Description:
--   1. Create Stored Procedure USP_TrackTraceScan_AI:
--      - Validates 13-digit code & SRV1021 (Track & Trace) subscription.
--      - Retrieves dispatch info from codeassign_tractrac.
--      - Inserts scan checkpoint into CodeLocation & Pro_Enq.
--      - Checks potential territory diversion.
--   2. Create Stored Procedure USP_GetTrackTraceActivityReport_AI:
--      - Fetches paginated activity reports (code1, code2, mobile, location, scan date).
--      - Supports company-level filtering (vendor) or code/mobile filtering (app).
-- =========================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================
-- 1. Stored Procedure: USP_TrackTraceScan_AI
-- =========================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_TrackTraceScan_AI]
    @Code1           NVARCHAR(10),
    @Code2           NVARCHAR(15),
    @MobileNo        NVARCHAR(20) = NULL,
    @Latitude        NVARCHAR(50) = NULL,
    @Longitude       NVARCHAR(50) = NULL,
    @City            NVARCHAR(50) = NULL,
    @State           NVARCHAR(50) = NULL,
    @PinCode         NVARCHAR(10) = NULL,
    @Address         NVARCHAR(MAX) = NULL,
    @ScannerType     NVARCHAR(50) = 'App',  -- 'App' or 'Web'
    @Mode            NVARCHAR(50) = 'TrackTraceApp'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResultCode INT = 1;
    DECLARE @Message NVARCHAR(MAX) = '';
    DECLARE @RowID NUMERIC(12, 0) = NULL;
    DECLARE @UseCount NUMERIC(5, 0) = 0;
    DECLARE @ProID VARCHAR(50) = NULL;
    DECLARE @Batch_No NVARCHAR(100) = NULL;
    DECLARE @CurrentCompID NVARCHAR(50) = NULL;
    DECLARE @ProName NVARCHAR(200) = NULL;

    -- Normalize Mobile (add 91 if 10 digits)
    IF @MobileNo IS NOT NULL AND LEN(@MobileNo) = 10
    BEGIN
        SET @MobileNo = '91' + @MobileNo;
    END

    -- 1. Validate Code in M_Code
    SELECT TOP 1 
        @RowID = mc.Row_ID, 
        @UseCount = ISNULL(mc.Use_Count, 0), 
        @ProID = mc.Pro_ID,
        @Batch_No = mc.Batch_No,
        @CurrentCompID = pr.Comp_ID,
        @ProName = pr.Pro_Name
    FROM M_Code mc WITH (NOLOCK)
    INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
    WHERE mc.Code1 = CAST(@Code1 AS NUMERIC(5,0)) 
      AND mc.Code2 = CAST(@Code2 AS NUMERIC(8,0))
      AND (mc.ScrapeFlag IS NULL OR mc.ScrapeFlag = 0);

    -- Fallback to M_Code_PFL
    IF @RowID IS NULL
    BEGIN
        SELECT TOP 1 
            @RowID = mc.Row_ID, 
            @UseCount = ISNULL(mc.Use_Count, 0), 
            @ProID = mc.Pro_ID,
            @Batch_No = mc.Batch_No,
            @CurrentCompID = pr.Comp_ID,
            @ProName = pr.Pro_Name
        FROM M_Code_PFL mc WITH (NOLOCK)
        INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
        WHERE mc.Code1 = CAST(@Code1 AS NUMERIC(5,0)) 
          AND mc.Code2 = CAST(@Code2 AS NUMERIC(8,0))
          AND (mc.ScrapeFlag IS NULL OR mc.ScrapeFlag = 0);
    END

    -- If code not found: log invalid attempt
    IF @RowID IS NULL
    BEGIN
        INSERT INTO Pro_Enq (
            Dial_Mode, Enq_Date, Mode_Detail, MobileNo, Received_Code1, Received_Code2, 
            Is_Success, Comp_ID, Latitude, Longitude, City, state, PinCode,
            IsActive, IsDelete, Created_Date
        )
        VALUES (
            @Mode, GETDATE(), 'Invalid Track & Trace Scan', @MobileNo, @Code1, @Code2, 
            '0', 'DEFAULT', @Latitude, @Longitude, @City, @State, @PinCode,
            1, 0, GETDATE()
        );

        SELECT 
            0 AS ResultCode, 
            'Invalid Code. Please check the 13-digit code and try again.' AS [Message],
            NULL AS Comp_ID,
            @Code1 AS Code1,
            @Code2 AS Code2,
            NULL AS ProductName,
            NULL AS BatchNo,
            NULL AS MRP,
            NULL AS MfdDate,
            NULL AS ExpDate,
            NULL AS DispatchedDealer,
            NULL AS DispatchedLocation,
            NULL AS DispatchDate,
            NULL AS InvoiceNumber,
            @City AS ScannedCity,
            @State AS ScannedState,
            GETDATE() AS ScanDate,
            CAST(0 AS BIT) AS IsPotentialDiversion;
        RETURN;
    END

    -- 2. Validate Service Subscription for SRV1021 (Track & Trace)
    IF NOT EXISTS (
        SELECT 1 
        FROM M_ServiceSubscription ms WITH (NOLOCK)
        INNER JOIN M_ServiceSubscriptionTrans mst WITH (NOLOCK) ON ms.Subscribe_Id = mst.Subscribe_Id
        WHERE ms.Pro_ID = @ProID 
          AND ms.Service_ID = 'SRV1021'
          AND ms.IsActive = 1 
          AND mst.IsActive = 1
          AND ms.IsDelete = 0 
          AND mst.IsDelete = 0
    )
    BEGIN
        INSERT INTO Pro_Enq (
            Dial_Mode, Enq_Date, Mode_Detail, MobileNo, Received_Code1, Received_Code2, 
            Is_Success, Comp_ID, Latitude, Longitude, City, state, PinCode,
            IsActive, IsDelete, Created_Date
        )
        VALUES (
            @Mode, GETDATE(), 'Track & Trace (SRV1021) Not Active', @MobileNo, @Code1, @Code2, 
            '0', @CurrentCompID, @Latitude, @Longitude, @City, @State, @PinCode,
            1, 0, GETDATE()
        );

        SELECT 
            0 AS ResultCode, 
            'Track & Trace service (SRV1021) is not configured or active for this product code.' AS [Message],
            @CurrentCompID AS Comp_ID,
            @Code1 AS Code1,
            @Code2 AS Code2,
            @ProName AS ProductName,
            @Batch_No AS BatchNo,
            NULL AS MRP,
            NULL AS MfdDate,
            NULL AS ExpDate,
            NULL AS DispatchedDealer,
            NULL AS DispatchedLocation,
            NULL AS DispatchDate,
            NULL AS InvoiceNumber,
            @City AS ScannedCity,
            @State AS ScannedState,
            GETDATE() AS ScanDate,
            CAST(0 AS BIT) AS IsPotentialDiversion;
        RETURN;
    END

    -- 3. Retrieve Dispatch and Dealer Details from codeassign_tractrac
    DECLARE @DealerName NVARCHAR(150) = NULL;
    DECLARE @DealerLocation NVARCHAR(150) = NULL;
    DECLARE @DispatchDate DATETIME = NULL;
    DECLARE @InvoiceNumber NVARCHAR(50) = NULL;
    DECLARE @MRP NUMERIC(18, 2) = NULL;
    DECLARE @MfdDate DATETIME = NULL;
    DECLARE @ExpDate DATETIME = NULL;

    SELECT TOP 1
        @DealerName = ct.Dealer_Name,
        @DealerLocation = ct.Dealer_Location,
        @DispatchDate = ct.Dispatch_Date,
        @InvoiceNumber = ct.Invoice_Number,
        @MRP = ct.MRP,
        @MfdDate = ct.Mfd_Date,
        @ExpDate = ct.Exp_Date
    FROM codeassign_tractrac ct WITH (NOLOCK)
    WHERE ct.Pro_ID = @ProID 
      AND (ct.Batch_No = @Batch_No OR ct.Batch_No IS NULL)
      AND ct.isdelete = 0
    ORDER BY ct.ID DESC;

    -- 4. Check Potential Territory Diversion
    DECLARE @IsPotentialDiversion BIT = 0;
    IF @DealerLocation IS NOT NULL AND LTRIM(RTRIM(@DealerLocation)) <> ''
    BEGIN
        IF (@City IS NOT NULL AND LTRIM(RTRIM(@City)) <> '') OR (@State IS NOT NULL AND LTRIM(RTRIM(@State)) <> '')
        BEGIN
            IF (@City IS NOT NULL AND CHARINDEX(LOWER(LTRIM(RTRIM(@City))), LOWER(@DealerLocation)) = 0)
               AND (@State IS NOT NULL AND CHARINDEX(LOWER(LTRIM(RTRIM(@State))), LOWER(@DealerLocation)) = 0)
            BEGIN
                SET @IsPotentialDiversion = 1;
            END
        END
    END

    -- 5. Record Location Checkpoint in CodeLocation
    INSERT INTO CodeLocation (
        code1, code2, mobilno, latitude, longitude, city, state, country, address, entrydate, PostalCode
    )
    VALUES (
        CAST(@Code1 AS NUMERIC(5, 0)),
        CAST(@Code2 AS NUMERIC(8, 0)),
        @MobileNo,
        @Latitude,
        @Longitude,
        @City,
        @State,
        'India',
        @Address,
        GETDATE(),
        @PinCode
    );

    -- 6. Log Scan Inquiry in Pro_Enq
    INSERT INTO Pro_Enq (
        Dial_Mode, Enq_Date, Mode_Detail, MobileNo, Received_Code1, Received_Code2, 
        Is_Success, Comp_ID, Latitude, Longitude, City, state, PinCode,
        IsActive, IsDelete, Created_Date
    )
    VALUES (
        @Mode, GETDATE(), 'Track & Trace Scan', @MobileNo, @Code1, @Code2, 
        '1', @CurrentCompID, @Latitude, @Longitude, @City, @State, @PinCode,
        1, 0, GETDATE()
    );

    -- 7. Increment Code Scan Use_Count
    UPDATE M_Code 
    SET Use_Count = @UseCount + 1, Allot_Date = GETDATE() 
    WHERE Row_ID = @RowID;

    UPDATE M_Code_PFL 
    SET Use_Count = @UseCount + 1, Allot_Date = GETDATE() 
    WHERE Row_ID = @RowID;

    SET @Message = 'Product scan verified and location recorded successfully.';

    -- 8. Return Detailed Verification & Location Result
    SELECT 
        1 AS ResultCode, 
        @Message AS [Message],
        @CurrentCompID AS Comp_ID,
        @Code1 AS Code1,
        @Code2 AS Code2,
        @ProName AS ProductName,
        @Batch_No AS BatchNo,
        @MRP AS MRP,
        CONVERT(VARCHAR(10), @MfdDate, 120) AS MfdDate,
        CONVERT(VARCHAR(10), @ExpDate, 120) AS ExpDate,
        @DealerName AS DispatchedDealer,
        @DealerLocation AS DispatchedLocation,
        @DispatchDate AS DispatchDate,
        @InvoiceNumber AS InvoiceNumber,
        @City AS ScannedCity,
        @State AS ScannedState,
        GETDATE() AS ScanDate,
        @IsPotentialDiversion AS IsPotentialDiversion;
END
GO

-- =========================================================================
-- 2. Stored Procedure: USP_GetTrackTraceActivityReport_AI
-- =========================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetTrackTraceActivityReport_AI]
    @Comp_ID     NVARCHAR(50) = NULL,
    @Code1       NVARCHAR(10) = NULL,
    @Code2       NVARCHAR(15) = NULL,
    @MobileNo    NVARCHAR(20) = NULL,
    @Search      NVARCHAR(100) = NULL,
    @FromDate    DATETIME = NULL,
    @ToDate      DATETIME = NULL,
    @Page        INT = 1,
    @Limit       INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 10;
    IF @Limit > 500 SET @Limit = 500;

    -- Clean parameters
    SET @Comp_ID = NULLIF(LTRIM(RTRIM(@Comp_ID)), '');
    SET @Code1 = NULLIF(LTRIM(RTRIM(@Code1)), '');
    SET @Code2 = NULLIF(LTRIM(RTRIM(@Code2)), '');
    SET @MobileNo = NULLIF(LTRIM(RTRIM(@MobileNo)), '');
    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');

    IF @ToDate IS NOT NULL
        SET @ToDate = DATEADD(DAY, 1, @ToDate); -- include full to-date

    -- Total Count
    SELECT COUNT(1) AS TotalRecords
    FROM CodeLocation cl WITH (NOLOCK)
    LEFT JOIN M_Code mc WITH (NOLOCK) 
        ON mc.Code1 = cl.code1 AND mc.Code2 = cl.code2
    LEFT JOIN Pro_Reg pr WITH (NOLOCK) 
        ON mc.Pro_ID = pr.Pro_ID
    WHERE (@Comp_ID IS NULL OR pr.Comp_ID = @Comp_ID)
      AND (@Code1 IS NULL OR cl.code1 = CAST(@Code1 AS NUMERIC(5,0)))
      AND (@Code2 IS NULL OR cl.code2 = CAST(@Code2 AS NUMERIC(8,0)))
      AND (@MobileNo IS NULL OR cl.mobilno LIKE '%' + @MobileNo + '%')
      AND (@FromDate IS NULL OR cl.entrydate >= @FromDate)
      AND (@ToDate IS NULL OR cl.entrydate < @ToDate)
      AND (@Search IS NULL OR (
          cl.city LIKE '%' + @Search + '%' 
          OR cl.state LIKE '%' + @Search + '%' 
          OR cl.mobilno LIKE '%' + @Search + '%' 
          OR pr.Pro_Name LIKE '%' + @Search + '%'
      ));

    -- Paged Data
    SELECT 
        cl.id AS Id,
        RIGHT('00000' + CAST(cl.code1 AS VARCHAR(10)), 5) AS Code1,
        RIGHT('00000000' + CAST(cl.code2 AS VARCHAR(15)), 8) AS Code2,
        cl.mobilno AS MobileNumber,
        cl.latitude AS Latitude,
        cl.longitude AS Longitude,
        cl.city AS City,
        cl.state AS State,
        cl.PostalCode AS PostalCode,
        cl.address AS Address,
        cl.entrydate AS ScanDate,
        pr.Pro_Name AS ProductName,
        mc.Batch_No AS BatchNo,
        ct.Dealer_Name AS DispatchedDealer,
        ct.Dealer_Location AS DispatchedLocation,
        ct.Invoice_Number AS InvoiceNumber
    FROM CodeLocation cl WITH (NOLOCK)
    LEFT JOIN M_Code mc WITH (NOLOCK) 
        ON mc.Code1 = cl.code1 AND mc.Code2 = cl.code2
    LEFT JOIN Pro_Reg pr WITH (NOLOCK) 
        ON mc.Pro_ID = pr.Pro_ID
    LEFT JOIN codeassign_tractrac ct WITH (NOLOCK) 
        ON ct.Pro_ID = pr.Pro_ID AND (ct.Batch_No = mc.Batch_No OR ct.Batch_No IS NULL) AND ct.isdelete = 0
    WHERE (@Comp_ID IS NULL OR pr.Comp_ID = @Comp_ID)
      AND (@Code1 IS NULL OR cl.code1 = CAST(@Code1 AS NUMERIC(5,0)))
      AND (@Code2 IS NULL OR cl.code2 = CAST(@Code2 AS NUMERIC(8,0)))
      AND (@MobileNo IS NULL OR cl.mobilno LIKE '%' + @MobileNo + '%')
      AND (@FromDate IS NULL OR cl.entrydate >= @FromDate)
      AND (@ToDate IS NULL OR cl.entrydate < @ToDate)
      AND (@Search IS NULL OR (
          cl.city LIKE '%' + @Search + '%' 
          OR cl.state LIKE '%' + @Search + '%' 
          OR cl.mobilno LIKE '%' + @Search + '%' 
          OR pr.Pro_Name LIKE '%' + @Search + '%'
      ))
    ORDER BY cl.id DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END
GO
