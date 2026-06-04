USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Description: Beneficiaries Report for Mahindra & Mahindra (Comp-1152)
-- exec [dbo].[SP_BL_GetBeneficiariesReport_MAndM_AI] 'Comp-1152','MONTH',NULL,NULL,'Approved',NULL,1,10
-- exec [dbo].[SP_BL_GetBeneficiariesReport_MAndM_AI] 'Comp-2345','ALL',NULL,NULL,NULL,NULL,1,10
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport_MAndM_AI]
(
    @Comp_Id     NVARCHAR(50),  
    @datePreset  NVARCHAR(20) = NULL,   -- TODAY, WEEK, LASTWEEK, MONTH, QUARTER, ALL
    @FromDate    DATE = NULL,
    @ToDate      DATE = NULL,
    @KYCStatusFilter NVARCHAR(20) = NULL, -- Approved / Rejected / Pending
    @StateFilter NVARCHAR(100) = NULL,
    @Page        INT = NULL,
    @Limit       INT = NULL,
    @IsExport    BIT = NULL,
    @Search      NVARCHAR(30) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(50) = @Comp_Id;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

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
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @ActualCompId AND Status = 1;

    DECLARE @StartDate DATETIME = '2022-11-25 00:00:00.000';
    DECLARE @EndDate   DATETIME = NULL;

    -- Normalize datePreset
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    IF (@Win = '' OR @Win = 'NULL') SET @Win = 'ALL';

    -- Explicit date range overrides datePreset
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME)); -- Exclusive end date
    END
    ELSE IF (@Win = 'TODAY')
    BEGIN
        SET @StartDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@Win = 'WEEK' OR @Win = 'THIS WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()) - 7, CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 7, @StartDate);
    END
    ELSE IF (@Win = 'MONTH' OR @Win = 'THIS MONTH')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, -1, CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME));
        SET @EndDate = DATEADD(MONTH, 1, @StartDate);
    END
    ELSE IF (@Win = 'QUARTER' OR @Win = 'THIS QUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
    END
    ELSE IF (@Win = 'LASTQUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
        SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
    END
    ELSE IF (@Win = 'YEAR' OR @Win = 'THIS YEAR')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'LASTYEAR')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1) AS DATETIME);
        SET @EndDate = DATEADD(YEAR, 1, @StartDate);
    END
    -- ALL / NULL
    ELSE
    BEGIN
       -- SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- CLEAN TEMP TABLES
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #Users, #State, #Benefit, #Claims, #UPI, #BPoints, #FinalData;

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
    FROM
    (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY M_ConsumerId ORDER BY Entry_date DESC) AS rn
        FROM tbl_VendorViseKYCStatus WITH (NOLOCK)
        WHERE Comp_Id = @ActualCompId
    ) V
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON V.M_ConsumerId = MC.M_ConsumerId
    WHERE V.rn = 1
      AND MC.IsDelete = 0
      AND (
            (@IsSBUTeam = 0 AND (MC.distributorID <> 'SBUTEAM' OR MC.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND MC.distributorID = 'SBUTEAM')
          );

    CREATE CLUSTERED INDEX IX_Users_ConsumerId ON #Users(M_ConsumerId);
    CREATE INDEX IX_Users_MobileNo ON #Users(MobileNo);

    ---------------------------------------------------------
    -- LATEST STATE / CITY (OPTIMIZED)
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
                ORDER BY GE.Enq_Date DESC
            ) AS rn
        FROM #Users U
        INNER JOIN GeoLocationData GE WITH (NOLOCK) ON GE.MobileNo = U.MobileNo
        WHERE GE.Comp_Id = @ActualCompId
    ) x
    WHERE rn = 1;

    CREATE CLUSTERED INDEX IX_State_ConsumerId ON #State(M_ConsumerId);

    ---------------------------------------------------------
    -- BENEFIT CALCULATION (DIRECT & OPTIMIZED FOR MAHINDRA)
    ---------------------------------------------------------
    SELECT
        BL.M_ConsumerId,
        SUM(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END) AS Benefit,
        MAX(BL.Enq_Date) AS LastScan
    INTO #Benefit
    FROM dbo.ConsumerPointsCashDetails BL WITH (NOLOCK)
    WHERE BL.Comp_id = @ActualCompId
      AND (@StartDate IS NULL OR BL.Enq_Date >= @StartDate)
      AND (@EndDate   IS NULL OR BL.Enq_Date <  @EndDate)
      AND BL.M_ConsumerId IN (SELECT M_ConsumerId FROM #Users)
    GROUP BY BL.M_ConsumerId;

    CREATE CLUSTERED INDEX IX_Benefit_ConsumerId ON #Benefit(M_ConsumerId);

    ---------------------------------------------------------
    -- CLAIMS
    ---------------------------------------------------------
    SELECT
        Mobileno,
        SUM(CASE WHEN ISNULL(Amount,0) > 0 THEN Amount ELSE ISNULL(TRY_CONVERT(NUMERIC(18,2), PointsValue),0) END) AS ClaimsAmount,
        SUM(ISNULL(tdsAmount,0)) AS TDSAmount
    INTO #Claims
    FROM ClaimDetails CD WITH (NOLOCK)
    WHERE CD.Comp_id = @ActualCompId
      AND Isapproved = 1
      AND (action_date IS NULL OR ((@StartDate IS NULL OR action_date >= @StartDate) AND (@EndDate IS NULL OR action_date < @EndDate)))
    GROUP BY Mobileno;

    CREATE CLUSTERED INDEX IX_Claims_MobileNo ON #Claims(Mobileno);

    ---------------------------------------------------------
    -- UPI
    ---------------------------------------------------------
    SELECT
        M_CounserID AS M_Consumerid,
        SUM(ISNULL(CAST(Amount AS DECIMAL(18,2)),0)) AS UPIAmount
    INTO #UPI
    FROM Transactions WITH (NOLOCK)
    WHERE CompId = REPLACE(@ActualCompId, 'Comp-', '')
      AND Issuccess = 1
      AND (@StartDate IS NULL OR TransactionDate >= @StartDate)
      AND (@EndDate   IS NULL OR TransactionDate <  @EndDate)
    GROUP BY M_CounserID;

    CREATE CLUSTERED INDEX IX_UPI_ConsumerId ON #UPI(M_Consumerid);

    ---------------------------------------------------------
    -- BPOINTS TRANSACTION
    ---------------------------------------------------------
    SELECT
        RedeemBy,
        SUM(ISNULL(RedeemPoints, 0)) AS BPointsAmount
    INTO #BPoints
    FROM BPointsTransaction WITH (NOLOCK)
    WHERE companyid = @ActualCompId
      AND bpstatus IN ('Accepted', 'SUCCESS')
      AND (@StartDate IS NULL OR Redeemdate >= @StartDate)
      AND (@EndDate   IS NULL OR Redeemdate <  @EndDate)
    GROUP BY RedeemBy;

    CREATE CLUSTERED INDEX IX_BPoints_RedeemBy ON #BPoints(RedeemBy);

    ---------------------------------------------------------
    -- FINAL DATA
    ---------------------------------------------------------
    IF LTRIM(RTRIM(ISNULL(@KYCStatusFilter, ''))) = '' OR @KYCStatusFilter = 'null' OR @KYCStatusFilter = 'ALL' OR @KYCStatusFilter = 'All' SET @KYCStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@StateFilter, ''))) = '' OR @StateFilter = 'null' SET @StateFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;

    SELECT
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, U.State) AS State,
        ISNULL(S.City,  U.City)  AS City,
        U.PinCode,
        U.KYCStatus,
        ISNULL(B.Benefit,0) AS PointsEarned,
        ISNULL(C.ClaimsAmount,0) + ISNULL(UU.UPIAmount,0) + ISNULL(BP.BPointsAmount,0) AS RedeemAmount,
        ISNULL(B.Benefit,0) - (ISNULL(C.ClaimsAmount,0) + ISNULL(UU.UPIAmount,0) + ISNULL(BP.BPointsAmount,0)) AS BalanceAmount,
        ISNULL(C.TDSAmount,0) AS TDSAmount,
        B.LastScan,
        ROW_NUMBER() OVER (ORDER BY ISNULL(B.Benefit,0) DESC, U.M_ConsumerId) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State   S  ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B  ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Claims  C  ON C.Mobileno     = U.MobileNo
    LEFT JOIN #UPI     UU ON UU.M_Consumerid = CAST(U.M_ConsumerId AS VARCHAR(50))
    LEFT JOIN #BPoints BP ON BP.RedeemBy    = U.M_ConsumerId
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
        SELECT
            ConsumerName, MobileNo, State, City, PinCode, KYCStatus,
            PointsEarned, RedeemAmount, BalanceAmount, TDSAmount, LastScan
        FROM #FinalData
        ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT
            ConsumerName, MobileNo, State, City, PinCode, KYCStatus,
            PointsEarned, RedeemAmount, BalanceAmount, TDSAmount, LastScan
        FROM #FinalData
        WHERE RN BETWEEN ((@Page - 1) * @Limit) + 1 AND (@Page * @Limit)
        ORDER BY RN;

        SELECT
            COUNT(*)                         AS TotalRecords,
            @Page                            AS CurrentPage,
            @Limit                           AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END
END
GO
