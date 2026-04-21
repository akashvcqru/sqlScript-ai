/****** Object:  StoredProcedure [dbo].[SP_Get_M_StarCodeVerification_ByMobile_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Get_M_StarCodeVerification_ByMobile_AI]
(
    @CompId NVARCHAR(15),
    @MobileNumber NVARCHAR(20),
    @TimeWindow NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PaymentStatus NVARCHAR(10) = NULL,   -- 'Paid' or 'Unpaid'
    @Search NVARCHAR(50) = NULL,       -- partial or full completecode
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Normalize inputs
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);

      IF (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR @Search = 'NULL')
        SET @Search = NULL;

    IF (@TimeWindow IS NULL OR LTRIM(RTRIM(@TimeWindow)) = '' OR UPPER(@TimeWindow) = 'NULL')
        SET @TimeWindow = NULL;
    ELSE
        SET @TimeWindow = UPPER(@TimeWindow);

    IF @CompId IS NULL OR LTRIM(RTRIM(@CompId)) = ''
    BEGIN
        RAISERROR ('CompId is required', 16, 1);
        RETURN;
    END

    IF @MobileNumber IS NULL OR LTRIM(RTRIM(@MobileNumber)) = ''
    BEGIN
        RAISERROR ('MobileNumber is required', 16, 1);
        RETURN;
    END

    ---------------------------------------------------------
    -- Date Calculation (From/To has priority)
    ---------------------------------------------------------
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

        ELSE IF (@TimeWindow = 'YESTERDAY')
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
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ---------------------------------------------------------
    -- EXPORT MODE (NO PAGINATION)
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT
            enquiry_date,
            product_name,
            completecode,
            status,
            Mobile_Number,
            remarks,
            amount_won,
            transaction_status,
            mode_of_verification,
            technicianid,
            dealercode,
            dealer_state,
            designation,
            consumername,
            city,
            address,
            pincode,
            aadharnumber,
            bank_name,
            account_holder_name,
            account_no,
            ifsc_code,
            branch,
            city_of_branch,
            br_address,
            CASE 
                WHEN payStatus = 1 THEN 'Paid'
                ELSE 'Unpaid'
            END AS PaymentStatus,
            tdsAmount
        FROM dbo.Tbl_M_Star_CodeVerification WITH (NOLOCK)
        WHERE
            Comp_Id = @CompId
            AND Mobile_Number = @MobileNumber
            AND (@StartDate IS NULL OR enquiry_date >= @StartDate)
            AND (@EndDate   IS NULL OR enquiry_date <= @EndDate)
            AND (
                @PaymentStatus IS NULL
                OR (@PaymentStatus = 'PAID' AND payStatus = 1)
                OR (@PaymentStatus = 'UNPAID' AND ISNULL(payStatus,0) = 0)
            )
             AND (
            @Search IS NULL
            OR CAST(ROUND(completecode, 0) AS BIGINT) = CAST(@Search AS BIGINT)
        )
        ORDER BY enquiry_date DESC;

        RETURN;
    END

    ---------------------------------------------------------
    -- Pagination defaults
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Store filtered data once
    ---------------------------------------------------------
    SELECT
        enquiry_date,
        product_name,
        completecode,
        status,
        Mobile_Number,
        remarks,
        amount_won,
        transaction_status,
        mode_of_verification,
        technicianid,
        dealercode,
        dealer_state,
        designation,
        consumername,
        city,
        address,
        pincode,
        aadharnumber,
        bank_name,
        account_holder_name,
        account_no,
        ifsc_code,
        branch,
        city_of_branch,
        br_address,
         CASE 
            WHEN payStatus = 1 THEN 'Paid'
            ELSE 'Unpaid'
        END AS PaymentStatus,
        tdsAmount
    INTO #ResultData
    FROM dbo.Tbl_M_Star_CodeVerification WITH (NOLOCK)
    WHERE
        Comp_Id = @CompId
        AND Mobile_Number = @MobileNumber
        AND (@StartDate IS NULL OR enquiry_date >= @StartDate)
        AND (@EndDate   IS NULL OR enquiry_date <= @EndDate)
          AND (
            @PaymentStatus IS NULL
            OR (@PaymentStatus = 'PAID' AND payStatus = 1)
            OR (@PaymentStatus = 'UNPAID' AND ISNULL(payStatus,0) = 0)
        )
        AND (
        @Search IS NULL
        OR CAST(ROUND(completecode, 0) AS BIGINT) = CAST(@Search AS BIGINT)
    );
    ---------------------------------------------------------
    -- RESULT SET 1: PAGED DATA
    ---------------------------------------------------------
    SELECT *
    FROM #ResultData
    ORDER BY enquiry_date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ---------------------------------------------------------
    -- RESULT SET 2: META
    ---------------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page  AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #ResultData;

END
GO
