SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Apr-2026
-- Update date: 24-Apr-2026 (Added pagination and timewindow)
-- Description: Get Warranty Report by Mobile Number with Pagination and TimeWindow
-- =============================================
ALTER PROCEDURE [dbo].[USP_GetWarrantyReportByMobile_AI] 
(
  @MobileNo varchar(50),
  @TimeWindow NVARCHAR(20) = NULL,
  @Page INT = 1,
  @Limit INT = 10
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

    IF (@TimeWindow IS NOT NULL AND @TimeWindow <> '' AND LOWER(@TimeWindow) <> 'null')
    BEGIN
        SET @TimeWindow = UPPER(LTRIM(RTRIM(@TimeWindow)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@TimeWindow = 'TODAY')
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@TimeWindow = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@TimeWindow = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
        ELSE IF (@TimeWindow = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
        END
        ELSE IF (@TimeWindow = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@TimeWindow = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
            
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

    -- Create temp table for warranty details
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
        vehicleno NVARCHAR(MAX),
        device NVARCHAR(MAX)
    );

    INSERT INTO #wrr (iswarrantyclaimed, WarrantyPeriod, PurchaseDate, vendorclaimstatus, ExpirationDate, code1, code2, Comment, vendorcomments, imagepathbill, billno, id, vehicleno, device)
    SELECT iswarrantyclaimed, WarrantyPeriod, [PurchaseDate], vendorclaimstatus, ExpirationDate, 
           TRY_CAST(SUBSTRING(code, 1, 5) AS INT), TRY_CAST(SUBSTRING(code, 7, 8) AS INT), 
           Comment, vendorcomments, imagepathbill, billno, id, 
           billno, State 
    FROM [WarrentyDetails] WITH (NOLOCK)
    WHERE Mobile IN (@MobileNo, @Mobile10, @MobileNo91, @MobileNoPlus91);

    CREATE INDEX IX_wrr_codes ON #wrr(code1, code2);

    -- Create temp table for service series checks
    CREATE TABLE #fillseries (
        Subscribe_Id nvarchar(100),
        Service_ID nvarchar(100),
        Comp_ID nvarchar(100), 
        Pro_ID nvarchar(100),
        IsActive int,
        start_order int,
        start_series int,
        end_order int,
        end_series int 
    );

    INSERT INTO #fillseries 
    SELECT Subscribe_Id, Service_ID, Comp_ID, Pro_ID, IsActive, start_order, start_series, end_order, end_series  
    FROM M_ServiceSubscription WITH (NOLOCK)
    WHERE IsActive = 1 AND start_order IS NOT NULL;

    CREATE INDEX IX_fillseries_Pro ON #fillseries(Pro_ID);

    ------------------------------------------------------
    -- Primary Filtered Data from Pro_Enq
    ------------------------------------------------------
    -- Filtering Pro_Enq once with index-friendly matches
    SELECT TRY_CAST(pe.received_code1 AS INT) AS received_code1, 
           TRY_CAST(pe.received_code2 AS INT) AS received_code2, 
           pe.enq_date, 
           pe.is_success, 
           pe.MobileNo
    INTO #EnqResults
    FROM Pro_Enq pe WITH (NOLOCK)
    WHERE pe.MobileNo IN (@MobileNo, @Mobile10, @MobileNo91, @MobileNoPlus91)
      AND pe.Received_Code1 <> 'None' AND pe.Received_Code2 <> 'None'
      AND (@StartDate IS NULL OR pe.enq_date >= @StartDate)
      AND (@EndDate IS NULL OR pe.enq_date <= @EndDate);

    CREATE INDEX IX_EnqResults_Codes ON #EnqResults(received_code1, received_code2);

    ------------------------------------------------------
    -- Final selection with pagination
    ------------------------------------------------------
    ;WITH MainResult AS (
        SELECT 
            enq.[enq_date], 
            CASE 
                WHEN enq.[is_success] = '1' AND (enq.enq_date BETWEEN sub.DateFrom AND sub.DateTo) AND wr.vendorclaimstatus='Pending' AND serv.[service_id] = 'SRV1023' THEN 'Gray'
                WHEN enq.[is_success] = '1' AND (enq.enq_date BETWEEN sub.DateFrom AND sub.DateTo) AND wr.vendorclaimstatus='Approved' AND serv.[service_id] = 'SRV1023' THEN 'Green' 
                WHEN enq.[is_success] = '1' AND (enq.enq_date BETWEEN sub.DateFrom AND sub.DateTo) AND (wr.vendorclaimstatus='' OR wr.vendorclaimstatus IS NULL) THEN 'Green' 
                ELSE 'Red' 
            END AS clr,
            CASE 
                WHEN enq.[is_success] = '1' AND (enq.enq_date BETWEEN sub.DateFrom AND sub.DateTo) THEN 'company_amount green' 
                ELSE 'company_amount' 
            END AS cls,  
            '' AS _sign,
            CASE 
                WHEN enq.[is_success] = '1' THEN 'Success' 
                ELSE 'Unsuccess' 
            END AS tr_status,
            CASE 
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) < 0 THEN 'Warranty has been expired'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND wr.vendorclaimstatus='Approved' AND serv.[service_id] = 'SRV1023' THEN 'Warranty claimed has been approved'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND wr.vendorclaimstatus='Reject' AND serv.[service_id] = 'SRV1023' THEN 'Warranty claimed has been rejected'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND wr.vendorclaimstatus='Pending' AND serv.[service_id] = 'SRV1023' THEN 'Warranty Claimed is Pending for approval'
                WHEN enq.[is_success] = '0' THEN @MsgInvalid
                WHEN enq.[is_success] = '1' AND (enq.enq_date NOT BETWEEN sub.DateFrom AND sub.DateTo) THEN
                    CONCAT(serv.ServiceName, ' ', @MsgExpired)
                ELSE (SELECT TOP 1 [message] FROM [transaction_message] WITH (NOLOCK) WHERE [service_id] = sub.[service_id] AND scenario = enq.[is_success]) 
            END AS msg1,  
            CASE 
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) < 0 THEN 'Warranty has been expired'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND wr.vendorclaimstatus='Approved' AND serv.[service_id] = 'SRV1023' THEN 'Warranty claimed has been approved'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND wr.vendorclaimstatus='Reject' AND serv.[service_id] = 'SRV1023' THEN 'Warranty claimed has been rejected'
                WHEN DATEDIFF(day, GETDATE(), wr.ExpirationDate) >= 0 AND wr.vendorclaimstatus='Pending' AND serv.[service_id] = 'SRV1023' THEN 'Warranty Claimed is Pending for approval'
                WHEN enq.[is_success] = '0' THEN @MsgPopInvalid
                WHEN enq.[is_success] = '1' AND (enq.enq_date NOT BETWEEN sub.DateFrom AND sub.DateTo) THEN
                    CONCAT(serv.ServiceName, ' ', @MsgPopExpired)
                ELSE REPLACE((SELECT TOP 1 [pop_message] FROM [transaction_message] WITH (NOLOCK) WHERE [service_id] = sub.[service_id] AND scenario = enq.[is_success]), '<warrantydate>', CONVERT(VARCHAR(11), wr.ExpirationDate, 106))
            END AS msg2,
            cr.Comp_name,
            FORMAT(enq.[enq_date], 'dd MMM') AS Updthalf, 
            FORMAT(enq.[enq_date], 'dd MMM yyyy HH:mm tt') AS Updtfull,
            CASE 
                WHEN enq.is_success = '1' THEN
                    ISNULL((SELECT TOP 1 '0' FROM M_ServiceSubscriptionTrans sst WITH (NOLOCK)
                            INNER JOIN #fillseries fs ON sst.Subscribe_Id = fs.Subscribe_Id
                            WHERE fs.Pro_ID = code.Pro_id 
                              AND (code.Series_Order > fs.start_order OR (code.Series_Order = fs.start_order AND code.Series_Serial >= fs.start_series))
                              AND (code.Series_Order < fs.end_order OR (code.Series_Order = fs.end_order AND code.Series_Serial <= fs.end_series))), 
                           serv_tran.IsCash)
                ELSE '0'
            END AS Loyalty,         
            enq.received_code1 AS code1,
            enq.received_code2 AS code2,
            '' AS giftname, 
            enq.MobileNo AS MobileNo, 
            '' AS trans_num, 
            product.[pro_name], 
            CASE 
                WHEN enq.[is_success] = '0' THEN 'invalid' 
                ELSE product.[pro_id] 
            END AS [Pro_id], 
            serv.[service_id], 
            serv.[servicename],
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.[PurchaseDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(20), wr.[PurchaseDate], 120) END AS [PurchaseDate],
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.WarrantyPeriod IS NULL THEN '' ELSE wr.WarrantyPeriod END AS WarrantyPeriod,
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.ExpirationDate IS NULL THEN '' ELSE CONVERT(VARCHAR(20), wr.ExpirationDate, 120) END AS ExpirationDate,
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.ExpirationDate IS NULL THEN '' ELSE CAST(DATEDIFF(day, GETDATE(), wr.ExpirationDate) AS VARCHAR(10)) END AS NumberofDays,
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.iswarrantyclaimed IS NULL THEN '' ELSE wr.iswarrantyclaimed END AS iswarrantyclaimed,
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.comment IS NULL THEN '' ELSE wr.comment END AS comment,
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.vendorcomments IS NULL THEN '' ELSE wr.vendorcomments END AS vendorcomments,
            CASE WHEN serv.[service_id]<>'SRV1023' OR wr.vendorclaimstatus IS NULL THEN '' ELSE wr.vendorclaimstatus END AS vendorclaimstatus,
            CASE WHEN serv.[service_id]<>'SRV1023' THEN '' ELSE wr.billno END AS billno,
            CASE WHEN serv.[service_id]<>'SRV1023' THEN '' ELSE wr.imagepathbill END AS imagepathbill,
            CASE WHEN serv.[service_id]<>'SRV1023' THEN '' ELSE wr.vehicleno END AS vehicleno,  
            CASE WHEN serv.[service_id]<>'SRV1023' THEN '' ELSE wr.device END AS device,
            CASE WHEN serv.[service_id]<>'SRV1023' THEN '' ELSE CAST(wr.id AS VARCHAR(50)) END AS warranty_id,
            '' AS Remarks 
        FROM #EnqResults enq
        LEFT JOIN m_code code WITH (NOLOCK) ON code.code1 = enq.received_code1 AND code.code2 = enq.received_code2
        LEFT JOIN Pro_reg product WITH (NOLOCK) ON product.Pro_id = code.Pro_id
        LEFT JOIN comp_reg cr WITH (NOLOCK) ON cr.comp_id = product.Comp_id
        LEFT JOIN M_ServiceSubscription sub WITH (NOLOCK) ON sub.Pro_id = code.Pro_id AND sub.comp_id = cr.comp_id
        LEFT JOIN m_service serv WITH (NOLOCK) ON serv.service_id = sub.service_id
        LEFT JOIN #wrr wr ON enq.received_code1 = wr.code1 AND enq.received_code2 = wr.code2
        LEFT JOIN VW_getservicesubscribe serv_tran WITH (NOLOCK) ON serv_tran.Subscribe_Id = sub.Subscribe_Id 
        WHERE serv.[Service_ID] = 'SRV1023'
    )
    SELECT * FROM MainResult
    ORDER BY [enq_date] DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    -- Return Total Records for Pagination
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM (
        SELECT enq.received_code1
        FROM #EnqResults enq
        LEFT JOIN m_code code WITH (NOLOCK) ON code.code1 = enq.received_code1 AND code.code2 = enq.received_code2
        LEFT JOIN M_ServiceSubscription sub WITH (NOLOCK) ON sub.Pro_id = code.Pro_id
        LEFT JOIN m_service serv WITH (NOLOCK) ON serv.service_id = sub.service_id
        WHERE serv.[Service_ID] = 'SRV1023'
    ) count_query;

    DROP TABLE #wrr;
    DROP TABLE #fillseries;
    DROP TABLE #EnqResults;
END
GO
