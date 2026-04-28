/****** Object:  StoredProcedure [dbo].[SP_Get_M_StarCodeVerificationReport_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Get_M_StarCodeVerificationReport_AI]
(
    @CompId NVARCHAR(15),
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Search NVARCHAR(20) = NULL,
    @Scheme NVARCHAR(10) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
)
AS
BEGIN
SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Normalize
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @Limit > 500 SET @Limit = 500;

    IF (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR @Search = 'NULL')
        SET @Search = NULL;

    IF (@Scheme IS NULL OR LTRIM(RTRIM(@Scheme)) = '' OR @Scheme = 'NULL')
        SET @Scheme = NULL;
    ELSE
        SET @Scheme = UPPER(@Scheme);

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Date range
    ---------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize datePreset
    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @Win NVARCHAR(50) = @datePreset;

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

        IF (@Win = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@Win = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);

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

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END
    ---------------------------------------------------------
    -- MATERIALIZE RESULT (KEY FIX)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#ResultData') IS NOT NULL DROP TABLE #ResultData;

    SELECT
        enquiry_date,
        product_name,
        completecode,
        status,
        Mobile_Number,
        remarks,
        SUM(ISNULL(amount_won,0)) 
            OVER (PARTITION BY Mobile_Number) AS amount_won,
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
        transactionDate,
        tdsAmount,
        ROW_NUMBER() OVER
        (
            PARTITION BY Mobile_Number
            ORDER BY enquiry_date DESC
        ) AS RN
    INTO #ResultData
    FROM dbo.Tbl_M_Star_CodeVerification
         WITH (NOLOCK)
    WHERE
        Comp_Id = @CompId
        AND (@StartDate IS NULL OR enquiry_date >= @StartDate)
        AND (@EndDate IS NULL OR enquiry_date <= @EndDate)
        AND (
        @Search IS NULL
        OR
        (
            ABS(CAST(ROUND(Mobile_Number, 0) AS BIGINT)) % 10000000000
            =
            CAST(RIGHT(@Search, 10) AS BIGINT)
        )
    )
        AND (@Scheme IS NULL OR product_name LIKE '%' + @Scheme + '%');

    ---------------------------------------------------------
    -- EXPORT MODE → ALL UNIQUE MOBILES
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT *
        FROM #ResultData
        WHERE RN = 1
        ORDER BY enquiry_date DESC;
        RETURN;
    END

    ---------------------------------------------------------
    -- NORMAL MODE → PAGINATION
    ---------------------------------------------------------
    SELECT *
    FROM #ResultData
    WHERE RN = 1 
    ORDER BY enquiry_date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ---------------------------------------------------------
    -- META
    ---------------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #ResultData
    WHERE RN = 1;

END
GO
