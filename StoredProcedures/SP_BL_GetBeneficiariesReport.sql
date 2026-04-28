USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetBeneficiariesReport]    Script Date: 4/28/2026 2:51:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [dbo].[SP_BL_GetBeneficiariesReport] 'Comp-1727','MONTH',NULL,NULL,'Approved',NULL,1,10
ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport]
(
    @Comp_Id     NVARCHAR(50),  
    @datePreset  NVARCHAR(20) = NULL,   -- TODAY, WEEK, LASTWEEK, MONTH, QUARTER, ALL
    @FromDate    DATE = NULL,
    @ToDate      DATE = NULL,
    @KYCStatusFilter NVARCHAR(20) = NULL, -- Approved / Rejected / Pending
    @StateFilter NVARCHAR(100) = NULL,
    @Page        INT = NULL,
    @Limit       INT = NULL,
    @IsExport BIT =NULL,
    @Search      NVARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- DEFAULT PAGINATION
    ---------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    ---------------------------------------------------------
    -- DATE RANGE
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Normalize TimeWindow
    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = LOWER(LTRIM(RTRIM(@datePreset)));

    -- Explicit date range overrides TimeWindow
    IF (@datePreset = 'custom' AND @FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME)); -- Exclusive end date
    END
    ELSE IF (@datePreset = 'today')
    BEGIN
        SET @StartDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@datePreset = 'lastday')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@datePreset = 'week')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@datePreset = 'lastweek')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()) - 7, CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 7, @StartDate);
    END
    ELSE IF (@datePreset = 'month')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@datePreset = 'lastmonth')
    BEGIN
        SET @StartDate = DATEADD(MONTH, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME));
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE IF (@datePreset = 'quarter')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
        SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
    END
    ELSE IF (@datePreset = 'year')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@datePreset = 'lastyear')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1) AS DATETIME);
        SET @EndDate = DATEADD(YEAR, 1, @StartDate);
    END
    ELSE IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE -- ALL / NULL
    BEGIN
        SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- CLEAN TEMP TABLES
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #Users, #State, #Benefit, #Claims, #UPI, #FinalData;

    ---------------------------------------------------------
    -- USERS + KYC
    ---------------------------------------------------------
    SELECT DISTINCT
        V.M_ConsumerId,
        MC.ConsumerName,
        MC.MobileNo,
        MC.PinCode,
        MC.State,
        MC.City,
        V.VRKbl_KYC_status,
        CASE
            WHEN V.VRKbl_KYC_status = 1 THEN 'Approved'
            WHEN V.VRKbl_KYC_status = 2 THEN 'Rejected'
            ELSE 'Pending'
        END AS KYCStatus
    INTO #Users
    FROM tbl_VendorViseKYCStatus V WITH (NOLOCK)
    LEFT JOIN M_Consumer MC WITH (NOLOCK)
        ON V.M_ConsumerId = MC.M_ConsumerId
    WHERE V.Comp_Id = @Comp_Id;

    ---------------------------------------------------------
    -- LATEST STATE / CITY
    ---------------------------------------------------------
    SELECT *
    INTO #State
    FROM
    (
        SELECT
            U.M_ConsumerId,
            GE.State,
            GE.City,
            ROW_NUMBER() OVER (
                PARTITION BY U.M_ConsumerId
                ORDER BY PE.Enq_Date DESC
            ) AS rn
        FROM #Users U
        LEFT JOIN Pro_Enq PE WITH (NOLOCK)
            ON PE.MobileNo = U.MobileNo
           AND PE.Comp_Id = @Comp_Id
        LEFT JOIN GeoLocationData GE WITH (NOLOCK)
            ON GE.MobileNo = PE.MobileNo
    ) x
    WHERE rn = 1;

    ---------------------------------------------------------
    -- BENEFITS
    ---------------------------------------------------------
	-- Drop temp if already exists
IF OBJECT_ID('tempdb..#Benefit') IS NOT NULL
    DROP TABLE #Benefit;

CREATE TABLE #Benefit
(
    M_ConsumerId INT,
    Benefit DECIMAL(18,2),
    LastScan DATETIME
);

IF @Comp_Id IN ('Comp-1567','Comp-1650')
BEGIN
    INSERT INTO #Benefit (M_ConsumerId, Benefit, LastScan)
    SELECT
        bp.M_ConsumerId,
        SUM(ISNULL(bp.Points,0)) AS Benefit,
        MAX(bp.UpdateDate) AS LastScan
    FROM BLoyaltyPointsEarned bp
    INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id 
    INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
    WHERE ms.Comp_ID IN ('Comp-1567','Comp-1650')
      AND (@StartDate IS NULL OR bp.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR bp.UpdateDate <  @EndDate)
    GROUP BY bp.M_ConsumerId;
END
ELSE
BEGIN
    INSERT INTO #Benefit (M_ConsumerId, Benefit, LastScan)
    /*SELECT
        M_ConsumerId,
		CASE WHEN @Comp_Id='Comp-1274' THEN  SUM(ISNULL(Cash,0)) ELSE  SUM(ISNULL(Points,0)) END Benefit,
       -- SUM(ISNULL(Points,0)) AS Benefit,
        MAX(UpdateDate) AS LastScan
    FROM BLoyaltyPointsEarned WITH (NOLOCK)
    WHERE CompId = @Comp_Id
      AND (@StartDate IS NULL OR UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR UpdateDate <  @EndDate)
    GROUP BY M_ConsumerId; */
	SELECT
        bp.M_ConsumerId,
		--CASE WHEN @Comp_Id='Comp-1274' THEN  SUM(ISNULL(bp.Cash,0)) ELSE  SUM(ISNULL(bp.Points,0)) END Benefit,
		CAST(
    CASE 
        WHEN @Comp_Id = 'Comp-1274' 
            THEN SUM(ISNULL(bp.Cash,0)) * 1.10   -- add 10% extra
        ELSE 
            SUM(ISNULL(bp.Points,0))
    END
AS DECIMAL(18,2)) AS Benefit,
       -- SUM(ISNULL(bp.Points,0)) AS Benefit,
        MAX(bp.UpdateDate) AS LastScan
    FROM BLoyaltyPointsEarned bp
    INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id 
    INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
    WHERE  CompId = @Comp_Id
      AND (@StartDate IS NULL OR bp.UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR bp.UpdateDate <  @EndDate)
    GROUP BY bp.M_ConsumerId;

END

	 /*SELECT
        M_ConsumerId,
        SUM(ISNULL(Points,0)) AS Benefit,
        MAX(UpdateDate) AS LastScan
    INTO #Benefit
    FROM BLoyaltyPointsEarned WITH (NOLOCK)
    WHERE CompId = @Comp_Id
      AND (@StartDate IS NULL OR UpdateDate >= @StartDate)
      AND (@EndDate   IS NULL OR UpdateDate <  @EndDate)
    GROUP BY M_ConsumerId; */


	

    ---------------------------------------------------------
    -- CLAIMS
    ---------------------------------------------------------


    /*SELECT
        Mobileno,
        SUM(
            CASE
                WHEN NULLIF(LTRIM(RTRIM(PointsValue)), '') IS NOT NULL
                     THEN ISNULL(Amount,0)
                ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue),0)
            END
        ) AS ClaimsAmount,
        SUM(ISNULL(tdsAmount,0)) AS TDSAmount
    INTO #Claims
    FROM ClaimDetails WITH (NOLOCK)
    WHERE Comp_id = @Comp_Id
      AND Isapproved = 1
    GROUP BY Mobileno;

	*/
	
	
	SELECT
        Mobileno,
        SUM(
        CASE
            WHEN ISNULL(Amount,0) > 0
                THEN Amount
            ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue),0)
        END
    ) AS ClaimsAmount,
    SUM(ISNULL(tdsAmount,0)) AS TDSAmount
    INTO #Claims
    FROM ClaimDetails WITH (NOLOCK)
	WHERE 
	(
		(@Comp_Id IN ('Comp-1567','Comp-1650') AND Comp_id IN ('Comp-1567','Comp-1650'))
		OR
		(@Comp_Id NOT IN ('Comp-1567','Comp-1650') AND Comp_id = @Comp_Id)
	)
	AND Isapproved = 1
	 AND (@StartDate IS NULL OR action_date >= @StartDate)
      AND (@EndDate   IS NULL OR action_date <  @EndDate)
	GROUP BY Mobileno;
	

    ---------------------------------------------------------
    -- UPI
    ---------------------------------------------------------
	-- Create temp table once
CREATE TABLE #UPI
(
    M_Consumerid VARCHAR(50),
    UPIAmount NUMERIC(18,2)
);
--select top 1* from Transactions
IF(@Comp_Id = 'Comp-1274')
BEGIN
    INSERT INTO #UPI (M_Consumerid, UPIAmount)
    SELECT
        M_CounserID,
        SUM(ISNULL(Amount,0))
    FROM Transactions WITH (NOLOCK)
    WHERE CompId = '1274'
	 AND (@StartDate IS NULL OR TransactionDate >= @StartDate)
      AND (@EndDate   IS NULL OR TransactionDate <  @EndDate)
    GROUP BY M_CounserID;
END
ELSE
BEGIN
    INSERT INTO #UPI (M_Consumerid, UPIAmount)
    SELECT
        M_Consumerid,
        SUM(ISNULL(Amount,0))
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id
      AND Status = 'Success'
      AND LEN(Code1) > 3
	   AND (@StartDate IS NULL OR ReqDate >= @StartDate)
      AND (@EndDate   IS NULL OR ReqDate <  @EndDate)
    GROUP BY M_Consumerid;
END
	/*
    SELECT
        M_Consumerid,
        SUM(ISNULL(Amount,0)) AS UPIAmount
    INTO #UPI
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id
      AND Status = 'Success'
      AND LEN(Code1) > 3
    GROUP BY M_Consumerid;
*/

    ---------------------------------------------------------
    -- FINAL DATA WITH ROW_NUMBER (KEY FIX)
    ---------------------------------------------------------
    SELECT
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, U.State) AS State,
        ISNULL(S.City,  U.City)  AS City,
        U.PinCode,
        U.KYCStatus,
        ISNULL(B.Benefit,0) AS PointsEarned,
        ISNULL(C.ClaimsAmount,0) + ISNULL(UU.UPIAmount,0) AS RedeemAmount,
        ISNULL(B.Benefit,0)
            - (ISNULL(C.ClaimsAmount,0) + ISNULL(UU.UPIAmount,0)) AS BalanceAmount,
        ISNULL(C.TDSAmount,0) AS TDSAmount,
        B.LastScan,

        ROW_NUMBER() OVER (
            ORDER BY ISNULL(B.Benefit,0) DESC, U.M_ConsumerId
        ) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State   S  ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B  ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Claims  C  ON C.Mobileno     = U.MobileNo
    LEFT JOIN #UPI     UU ON UU.M_Consumerid = U.M_ConsumerId
    WHERE
        (@StateFilter IS NULL OR ISNULL(S.State, U.State) = @StateFilter)
        AND (
            @KYCStatusFilter IS NULL OR
            (@KYCStatusFilter = 'Approved' AND U.VRKbl_KYC_status = 1) OR
            (@KYCStatusFilter = 'Rejected' AND U.VRKbl_KYC_status = 2) OR
            (@KYCStatusFilter = 'Pending'  AND ISNULL(U.VRKbl_KYC_status,0) NOT IN (1,2))
        )
        AND (
            @Search IS NULL OR
            U.ConsumerName LIKE '%' + @Search + '%' OR
            U.MobileNo     LIKE '%' + @Search + '%' OR
            U.City         LIKE '%' + @Search + '%' OR
            U.State        LIKE '%' + @Search + '%'
        );

    ---------------------------------------------------------
    -- PAGED RESULT
   IF @IsExport = 1
    BEGIN
        -- EXPORT: ALL DATA
        SELECT
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RedeemAmount,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        ORDER BY RN;
    END
    ELSE
    BEGIN
        -- PAGINATED DATA
        SELECT
            ConsumerName,
            MobileNo,
            State,
            City,
            PinCode,
            KYCStatus,
            PointsEarned,
            RedeemAmount,
            BalanceAmount,
            TDSAmount,
            LastScan
        FROM #FinalData
        WHERE RN BETWEEN ((@Page - 1) * @Limit) + 1
                    AND (@Page * @Limit)
        ORDER BY RN;

        -- PAGINATION META
        SELECT
            COUNT(*)                         AS TotalRecords,
            @Page                            AS CurrentPage,
            @Limit                           AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END