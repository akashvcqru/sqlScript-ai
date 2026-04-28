/****** Object:  StoredProcedure [dbo].[SP_BL_GetPaymentClaimReport]    Script Date: 3/2/2026 12:27:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[
    
]
(
    @Comp_Id        VARCHAR(20),
    @TimeWindow     NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate       DATETIME     = NULL,
    @ToDate         DATETIME     = NULL,
    @ClaimStatus    NVARCHAR(20) = NULL,   -- Pending / Approved / Rejected
    @PaymentStatus  NVARCHAR(20) = NULL,   -- Success / Failed / Pending

    @Page           INT = NULL,
    @Limit          INT = NULL,
    @IsExport BIT =NULL,
    @search nvarchar(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SAFETY DEFAULTS
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- DATE RANGE
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize TimeWindow
    IF (
           @TimeWindow IS NULL
        OR LTRIM(RTRIM(@TimeWindow)) = ''
        OR LOWER(LTRIM(RTRIM(@TimeWindow))) = 'null'
    )
        SET @TimeWindow = NULL;
    ELSE
        SET @TimeWindow = UPPER(LTRIM(RTRIM(@TimeWindow)));

    -- Explicit date range overrides TimeWindow
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF (@TimeWindow = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@TimeWindow = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@TimeWindow = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@TimeWindow = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END

        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), 1, 1);
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END

        ELSE IF (@TimeWindow = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(@EndDate) - 1, 12, 31);
        END

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    DECLARE @ClaimType VARCHAR(30) = 'GIFT';

    IF EXISTS (
        SELECT 1
        FROM tbl_UPILimitDetails
        WHERE Comp_ID = @Comp_Id
          AND Service_ID = 'SRV1029'
    )
    BEGIN
        SET @ClaimType = 'UPI';
    END



    ---------------------------------------------------------
    -- BASE WHERE (REUSED)
    ---------------------------------------------------------

    DECLARE @BaseWhere NVARCHAR(MAX) = N'
    WHERE VC.Comp_id = @Comp_Id
      AND (@StartDate IS NULL OR CD.Claim_Date >= @StartDate)
      AND (@EndDate   IS NULL OR CD.Claim_Date <  DATEADD(DAY, 1, @EndDate))
';

    IF @ClaimStatus IS NOT NULL
        SET @BaseWhere += N'
        AND (
            (@ClaimStatus = ''Pending''  AND (CD.Isapproved = 0 OR CD.Isapproved IS NULL)) OR
            (@ClaimStatus = ''Approved'' AND CD.Isapproved = 1) OR
            (@ClaimStatus = ''Rejected'' AND CD.Isapproved = 2)
        )';

    IF @PaymentStatus IS NOT NULL
        SET @BaseWhere += N'
        AND CD.PaymentStatus = @PaymentStatus';

    -- Mobile Search
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
        SET @BaseWhere += N'
        AND REPLACE(CD.Mobileno,'' '','''')
            LIKE ''%'' + REPLACE(@Search,'' '','''') + ''%''';

    ---------------------------------------------------------
    -- DATA QUERY
    ---------------------------------------------------------
    DECLARE @SQLData NVARCHAR(MAX) = N'
    SELECT
        CD.Row_id AS Claim_id,
        CD.Claim_date,
        CD.Amount AS Points,
        CASE 
            WHEN CAST(ISNULL(CD.PointsValue, 0) AS INT) < 1
            THEN CD.Amount 
        ELSE CD.PointsValue 
    END AS PointsValue,
        CD.tdsAmount,
        CD.tdsper,
        MC.ConsumerName,
        CD.Mobileno,
        CD.action_date,
        CASE 
            WHEN CD.Isapproved = 1 THEN ''Approved''
            WHEN CD.Isapproved = 2 THEN ''Rejected''
            ELSE ''Pending''
        END AS Claim_Status,
        CD.PaymentStatus,
        CD.BankRefID,
        CD.TransactionDate,
        CD.PaymentRemarks,
        CD.vendor_comment,
        
        MB.Account_HolderNm,
        MB.Account_No,
        MB.IFSC_Code,
        MB.Branch
    FROM ClaimDetails CD
    INNER JOIN M_Consumer MC 
        ON MC.MobileNo = CD.Mobileno
    INNER JOIN tbl_Vendorvisekycstatus VC 
        ON VC.M_consumerId = MC.M_Consumerid

    -- ONLY LATEST BANK ACCOUNT
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM M_BankAccount B
        WHERE B.M_Consumerid = MC.M_Consumerid
        ORDER BY B.Entry_Date DESC
    ) MB
    ' + @BaseWhere + N'
    ORDER BY CD.Claim_date DESC';

    IF @IsExport = 0
        SET @SQLData += N'
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY';

    ---------------------------------------------------------
    -- COUNT QUERY
    ---------------------------------------------------------
    DECLARE @SQLCount NVARCHAR(MAX) = N'
    SELECT
        COUNT(DISTINCT CD.Row_id) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(DISTINCT CD.Row_id) * 1.0 / @Limit) AS TotalPages
    FROM ClaimDetails CD
    INNER JOIN M_Consumer MC 
        ON MC.MobileNo = CD.Mobileno
    INNER JOIN tbl_Vendorvisekycstatus VC 
        ON VC.M_consumerId = MC.M_Consumerid
    ' + @BaseWhere;

    ---------------------------------------------------------
    -- FINAL EXECUTION
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        -- EXPORT: DATA ONLY
        EXEC sp_executesql
            @SQLData,
            N'
                @Comp_Id VARCHAR(20),
                @StartDate DATETIME,
                @EndDate DATETIME,
                @ClaimStatus NVARCHAR(20),
                @PaymentStatus NVARCHAR(20),
                @Search NVARCHAR(30)
            ',
            @Comp_Id,
            @StartDate,
            @EndDate,
            @ClaimStatus,
            @PaymentStatus,
            @Search;
    END
    ELSE
    BEGIN
        -- PAGINATION: DATA + COUNT
        DECLARE @FinalSQL NVARCHAR(MAX) = @SQLData + N'; ' + @SQLCount;

        EXEC sp_executesql
            @FinalSQL,
            N'
                @Comp_Id VARCHAR(20),
                @StartDate DATETIME,
                @EndDate DATETIME,
                @ClaimStatus NVARCHAR(20),
                @PaymentStatus NVARCHAR(20),
                @Search NVARCHAR(30),
                @Offset INT,
                @Limit INT,
                @Page INT
            ',
            @Comp_Id,
            @StartDate,
            @EndDate,
            @ClaimStatus,
            @PaymentStatus,
            @Search,
            @Offset,
            @Limit,
            @Page;
    END
END
GO
