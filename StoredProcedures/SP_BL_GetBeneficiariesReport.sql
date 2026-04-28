/****** Object:  StoredProcedure [dbo].[SP_BL_GetBeneficiariesReport]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport]
(
    @Comp_Id            VARCHAR(15),
    @TimeWindow         NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate           DATE = NULL,
    @ToDate             DATE = NULL,
    @KYCStatusFilter    NVARCHAR(20) = NULL,   -- APPROVED, REJECTED, PENDING
    @StateFilter        NVARCHAR(100) = NULL,
    
    @Page               INT = NULL,
    @Limit              INT = NULL,
    @IsExport           BIT = NULL,
    @Search             NVARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1️⃣ PAGINATION DEFAULTS
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    ---------------------------------------------------------
    -- 2️⃣ DATE RANGE LOGIC
    ---------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize TimeWindow
    IF (@TimeWindow IS NULL OR LTRIM(RTRIM(@TimeWindow)) = '' OR LOWER(LTRIM(RTRIM(@TimeWindow))) = 'null')
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
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END
        ELSE IF (@TimeWindow = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);
        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END
        ELSE IF (@TimeWindow = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);
        ELSE
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ---------------------------------------------------------
    -- 3️⃣ FETCH DATA
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalData') IS NOT NULL DROP TABLE #FinalData;

    SELECT 
        MC.ConsumerName,
        MC.MobileNo,
        MC.Email,
        MC.[State],
        MC.City,
        CASE 
            WHEN VKS.VRKbl_KYC_status = 1 THEN 'Approved'
            WHEN VKS.VRKbl_KYC_status = 2 THEN 'Rejected'
            ELSE 'Pending'
        END AS KYCStatus,
        ISNULL(SUM(BPE.Points), 0) AS PointsBalance,
        ISNULL(SUM(BPE.Amount), 0) AS BalanceAmount,
        ISNULL(SUM(BPE.TDSAmount), 0) AS TDSAmount,
        MAX(BPE.UpdateDate) AS LastScan,
        ROW_NUMBER() OVER (ORDER BY MAX(BPE.UpdateDate) DESC) AS RN
    INTO #FinalData
    FROM tbl_Vendorvisekycstatus VKS
    INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
    LEFT JOIN BLoyaltyPointsEarned BPE ON BPE.M_ConsumerId = MC.M_Consumerid AND BPE.CompId = VKS.Comp_ID
    WHERE VKS.Comp_ID = @Comp_Id
      AND MC.IsDelete = 0
      AND (@StartDate IS NULL OR CAST(VKS.Entry_Date AS DATE) BETWEEN @StartDate AND @EndDate)
      AND (
          @KYCStatusFilter IS NULL OR
          (@KYCStatusFilter = 'APPROVED' AND VKS.VRKbl_KYC_status = 1) OR
          (@KYCStatusFilter = 'REJECTED' AND VKS.VRKbl_KYC_status = 2) OR
          (@KYCStatusFilter = 'PENDING' AND (VKS.VRKbl_KYC_status = 0 OR VKS.VRKbl_KYC_status IS NULL))
      )
      AND (@StateFilter IS NULL OR LTRIM(RTRIM(@StateFilter)) = '' OR MC.[State] = @StateFilter)
      AND (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR MC.MobileNo LIKE '%' + @Search + '%')
    GROUP BY 
        MC.ConsumerName,
        MC.MobileNo,
        MC.Email,
        MC.[State],
        MC.City,
        VKS.VRKbl_KYC_status;

    ---------------------------------------------------------
    -- 4️⃣ RETURN DATA
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT 
            ConsumerName,
            MobileNo,
            Email,
            [State],
            City,
            KYCStatus,
            PointsBalance,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        ORDER BY LastScan DESC;
    END
    ELSE
    BEGIN
        SELECT 
            ConsumerName,
            MobileNo,
            Email,
            [State],
            City,
            KYCStatus,
            PointsBalance,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        WHERE RN BETWEEN ((@Page - 1) * @Limit) + 1 AND (@Page * @Limit)
        ORDER BY RN;

        ---------------------------------------------------------
        -- 5️⃣ PAGINATION INFO
        ---------------------------------------------------------
        SELECT
            COUNT(*)                         AS TotalRecords,
            @Page                            AS CurrentPage,
            @Limit                           AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
