SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Apr-2026
-- Update date: 09-Oct-2026 (Fixed duplicates from multiple Pro_Enq checks, multi-subscriptions, and multiple consumer records)
-- Description: Get Warranty Report by Mobile Number with Pagination and TimeWindow
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWarrantyReportByMobile_AI] 
(
  @MobileNo varchar(50),
  @datePreset NVARCHAR(20) = NULL,
  @Page INT = 1,
  @Limit INT = 10,
  @Comp_Id VARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    ------------------------------------------------------
    -- Pagination Defaults
    ------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- Date Range Logic
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
        END
        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END
            
        IF @EndDate IS NULL SET @EndDate = GETDATE();
    END
    ELSE IF (@StartDate IS NULL AND @EndDate IS NULL)
    BEGIN
        -- Default to last 2 years if no time window is provided to help utilize indexes on Enq_Date
        SET @StartDate = DATEADD(YEAR, -2, GETDATE());
    END

    ------------------------------------------------------
    -- Pre-fetch Static Messages
    ------------------------------------------------------
    DECLARE @MsgInvalid NVARCHAR(MAX), @MsgPopInvalid NVARCHAR(MAX);
    DECLARE @MsgExpired NVARCHAR(MAX), @MsgPopExpired NVARCHAR(MAX);
    
    SELECT TOP 1 @MsgInvalid = [message], @MsgPopInvalid = [pop_message] FROM [transaction_message] WHERE [service_id] = 'INVALID';
    SELECT TOP 1 @MsgExpired = [message], @MsgPopExpired = [pop_message] FROM [transaction_message] WHERE [service_id] = 'Expired';

    ------------------------------------------------------
    -- Optimize Mobile Filtering
    ------------------------------------------------------
    DECLARE @Mobile10 VARCHAR(10) = RIGHT(@MobileNo, 10);
    DECLARE @MobileNo91 VARCHAR(50) = '91' + @Mobile10;
    DECLARE @MobileNoPlus91 VARCHAR(50) = '+91' + @Mobile10;

    -- Create temp table for warranty details (De-duplicated per code1, code2)
    CREATE TABLE #wrr (
        iswarrantyclaimed NVARCHAR(100),
        WarrantyPeriod NVARCHAR(100),
        PurchaseDate DATETIME,
        vendorclaimstatus NVARCHAR(100),
        ExpirationDate DATETIME,
        code1 INT,
        code2 INT,
        Comment NVARCHAR(MAX),
        vendorcomments NVARCHAR(MAX),
        imagepathbill NVARCHAR(MAX),
        billno NVARCHAR(MAX),
        id INT,
        vehicleNumber NVARCHAR(MAX),
        [State] NVARCHAR(MAX),
        imagepath NVARCHAR(MAX),
        serialno VARCHAR(100),
        oldserialno VARCHAR(100),
        email NVARCHAR(MAX),
        claimdate DATETIME,
        comp_id VARCHAR(50)
    );

    ;WITH CTE_Wrr AS (
        SELECT iswarrantyclaimed, WarrantyPeriod, [PurchaseDate], vendorclaimstatus, ExpirationDate, 
               TRY_CAST(SUBSTRING(code, 1, CHARINDEX('-', code + '-') - 1) AS INT) AS code1,
               TRY_CAST(SUBSTRING(code, CHARINDEX('-', code + '-') + 1, LEN(code)) AS INT) AS code2, 
               Comment, vendorcomments, imagepathbill, billno, id, 
               vehicleNumber, State, ImagePath, Serialno, OldSerialno, Email, claimdate, Comp_id,
               ROW_NUMBER() OVER (
                   PARTITION BY TRY_CAST(SUBSTRING(code, 1, CHARINDEX('-', code + '-') - 1) AS INT),
                                TRY_CAST(SUBSTRING(code, CHARINDEX('-', code + '-') + 1, LEN(code)) AS INT)
                   ORDER BY id DESC
               ) AS rn
        FROM [WarrentyDetails] WITH (NOLOCK)
        WHERE Mobile IN (@MobileNo, @Mobile10, @MobileNo91, @MobileNoPlus91)
    )
    INSERT INTO #wrr (iswarrantyclaimed, WarrantyPeriod, PurchaseDate, vendorclaimstatus, ExpirationDate, code1, code2, Comment, vendorcomments, imagepathbill, billno, id, vehicleNumber, [State], ImagePath, Serialno, OldSerialno, Email, claimdate, Comp_id)
    SELECT iswarrantyclaimed, WarrantyPeriod, PurchaseDate, vendorclaimstatus, ExpirationDate, code1, code2, Comment, vendorcomments, imagepathbill, billno, id, vehicleNumber, State, ImagePath, Serialno, OldSerialno, Email, claimdate, Comp_id 
    FROM CTE_Wrr
    WHERE rn = 1;

    CREATE INDEX IX_wrr_codes ON #wrr(code1, code2);

    ------------------------------------------------------
    -- Primary Filtered Data from Pro_Enq (De-duplicated per code)
    ------------------------------------------------------
    ;WITH CTE_Enq AS (
        SELECT TRY_CAST(pe.received_code1 AS INT) AS received_code1, 
               TRY_CAST(pe.received_code2 AS INT) AS received_code2, 
               pe.enq_date, 
               pe.is_success, 
               pe.MobileNo,
               ROW_NUMBER() OVER (
                   PARTITION BY TRY_CAST(pe.received_code1 AS INT), TRY_CAST(pe.received_code2 AS INT)
                   ORDER BY 
                       CASE WHEN pe.Mode_Detail = 'Warranty Registration' THEN 0 ELSE 1 END,
                       pe.enq_date DESC
               ) AS rn
        FROM Pro_Enq pe WITH (NOLOCK)
        WHERE pe.MobileNo IN (@MobileNo, @Mobile10, @MobileNo91, @MobileNoPlus91)
          AND pe.Received_Code1 <> 'None' AND pe.Received_Code2 <> 'None'
          AND (pe.is_success NOT IN ('2', 2) OR pe.is_success IS NULL)
          AND (@StartDate IS NULL OR pe.enq_date >= @StartDate)
          AND (@EndDate IS NULL OR pe.enq_date <= @EndDate)
    )
    SELECT received_code1, received_code2, enq_date, is_success, MobileNo
    INTO #EnqResults
    FROM CTE_Enq
    WHERE rn = 1;

    CREATE INDEX IX_EnqResults_Codes ON #EnqResults(received_code1, received_code2);

    ------------------------------------------------------
    -- Final selection with pagination
    ------------------------------------------------------
    ;WITH MainResult AS (
        SELECT 
            enq.[enq_date], 
            CASE 
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) < 0 THEN 'Warranty has been expired'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND (wr.vendorclaimstatus='Approved' OR wr.iswarrantyclaimed='1') AND sub.[service_id] = 'SRV1023' THEN 'Warranty claimed has been approved'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND (wr.vendorclaimstatus='Reject' OR wr.iswarrantyclaimed='2') AND sub.[service_id] = 'SRV1023' THEN 'Warranty claimed has been rejected'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND (wr.vendorclaimstatus='ReClaimed' OR wr.iswarrantyclaimed='3') AND sub.[service_id] = 'SRV1023' THEN 'Warranty Claimed has been reclaimed'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND (wr.vendorclaimstatus='Pending' OR wr.iswarrantyclaimed='0') AND sub.[service_id] = 'SRV1023' THEN 'Warranty Claimed is Pending for approval'
                WHEN enq.[is_success] = '0' THEN @MsgInvalid
                WHEN enq.[is_success] = '1' AND (enq.enq_date NOT BETWEEN sub.DateFrom AND sub.DateTo) THEN
                    CONCAT(sub.ServiceName, ' ', @MsgExpired)
                ELSE (SELECT TOP 1 [message] FROM [transaction_message] WITH (NOLOCK) WHERE [service_id] = sub.[service_id] AND scenario = enq.[is_success]) 
            END AS msg1,  
            cr.Comp_name,
            enq.received_code1 AS code1,
            enq.received_code2 AS code2,
            CONCAT(enq.received_code1, enq.received_code2) AS [Code],
            enq.MobileNo AS MobileNo, 
            enq.MobileNo AS [Mobile],
            product.[pro_name], 
            product.[pro_name] AS [Product_Name],
            (SELECT TOP 1 Logo_Path FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = cr.Comp_ID) AS [LogoPath],
            CASE 
                WHEN enq.[is_success] = '0' THEN 'invalid' 
                ELSE product.[pro_id] 
            END AS [Pro_id], 
            sub.[servicename],
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.[PurchaseDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(20), wr.[PurchaseDate], 120) END AS [PurchaseDate],
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.WarrantyPeriod IS NULL THEN '' ELSE wr.WarrantyPeriod END AS WarrantyPeriod,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.ExpirationDate IS NULL THEN '' ELSE CONVERT(VARCHAR(20), wr.ExpirationDate, 120) END AS ExpirationDate,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.ExpirationDate IS NULL THEN 0 ELSE DATEDIFF(day, GETDATE(), wr.ExpirationDate) END AS NumberOfDays,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.iswarrantyclaimed IS NULL THEN '' ELSE wr.iswarrantyclaimed END AS IsWarrantyClaimed,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.imagepath IS NULL THEN '' ELSE wr.imagepath END AS ImagePath,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.Comment IS NULL THEN '' ELSE wr.Comment END AS Comment,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.vendorcomments IS NULL THEN '' ELSE wr.vendorcomments END AS VendorComments,
            CASE 
                WHEN wr.iswarrantyclaimed = '0' THEN 'Pending' 
                WHEN wr.iswarrantyclaimed = '1' THEN 'Approved' 
                WHEN wr.iswarrantyclaimed = '2' THEN 'Reject' 
                WHEN wr.iswarrantyclaimed = '3' THEN 'ReClaimed' 
                ELSE ISNULL(wr.vendorclaimstatus, '') 
            END AS VendorClaimStatus,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.billno, '') END AS BillNo,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.serialno, '') END AS Serialno,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.oldserialno, '') END AS OldSerialno,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.email, '') END AS EmailID,
            CASE WHEN sub.[service_id]<>'SRV1023' OR wr.claimdate IS NULL THEN NULL ELSE wr.claimdate END AS ClaimDate,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.imagepathbill, '') END AS ImagePathBill,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.vehicleNumber, '') END AS vehicleno,  
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.vehicleNumber, '') END AS VehicleNumber,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE CAST(wr.id AS VARCHAR(50)) END AS warranty_id,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN NULL ELSE wr.id END AS id,
            CASE WHEN sub.[service_id]<>'SRV1023' THEN '' ELSE ISNULL(wr.[State], '') END AS [State],
            CASE WHEN sub.[service_id]<>'SRV1023' THEN cr.comp_id ELSE ISNULL(wr.comp_id, cr.comp_id) END AS Comp_id,
            ISNULL(c.ConsumerName, '') AS [UserName],
            CASE WHEN (wr.vendorclaimstatus = 'Approved' OR wr.iswarrantyclaimed = '1') AND (wr.oldserialno IS NULL OR wr.oldserialno = '') THEN 1 ELSE 0 END AS IsReplace,
            '' AS Remarks 
        FROM #EnqResults enq
        LEFT JOIN m_code code WITH (NOLOCK) ON code.code1 = enq.received_code1 AND code.code2 = enq.received_code2
        LEFT JOIN Pro_reg product WITH (NOLOCK) ON product.Pro_id = code.Pro_id
        LEFT JOIN comp_reg cr WITH (NOLOCK) ON cr.comp_id = product.Comp_id
        CROSS APPLY (
            SELECT TOP 1 s.Subscribe_Id, s.DateFrom, s.DateTo, srv.ServiceName, srv.service_id
            FROM M_ServiceSubscription s WITH (NOLOCK)
            JOIN m_service srv WITH (NOLOCK) ON srv.service_id = s.service_id
            WHERE s.Pro_id = code.Pro_id 
              AND s.comp_id = cr.comp_id 
              AND srv.service_id = 'SRV1023'
            ORDER BY s.IsActive DESC, s.Subscribe_Id DESC
        ) sub
        LEFT JOIN #wrr wr ON enq.received_code1 = wr.code1 AND enq.received_code2 = wr.code2
        OUTER APPLY (
            SELECT TOP 1 ConsumerName 
            FROM [dbo].[M_Consumer] WITH (NOLOCK) 
            WHERE RIGHT(MobileNo, 10) = RIGHT(enq.MobileNo, 10) AND IsDelete = 0
            ORDER BY M_Consumerid DESC
        ) c
        WHERE (@Comp_Id IS NULL OR @Comp_Id = '' OR cr.comp_id = @Comp_Id)
    )
    SELECT * FROM MainResult
    ORDER BY [enq_date] DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    -- Return Total Records for Pagination
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CAST(CEILING(COUNT(1) * 1.0 / @Limit) AS INT) AS TotalPages
    FROM #EnqResults enq
    LEFT JOIN m_code code WITH (NOLOCK) ON code.code1 = enq.received_code1 AND code.code2 = enq.received_code2
    LEFT JOIN Pro_reg product WITH (NOLOCK) ON product.Pro_id = code.Pro_id
    LEFT JOIN comp_reg cr WITH (NOLOCK) ON cr.comp_id = product.Comp_id
    CROSS APPLY (
        SELECT TOP 1 s.Subscribe_Id
        FROM M_ServiceSubscription s WITH (NOLOCK)
        WHERE s.Pro_id = code.Pro_id 
          AND s.comp_id = cr.comp_id 
          AND s.service_id = 'SRV1023'
    ) sub
    WHERE (@Comp_Id IS NULL OR @Comp_Id = '' OR cr.comp_id = @Comp_Id);

    DROP TABLE #wrr;
    DROP TABLE #EnqResults;
END
GO
