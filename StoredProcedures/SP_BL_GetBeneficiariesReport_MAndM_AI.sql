USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Description: Beneficiaries Report for Mahindra & Mahindra (Comp-1152)
-- exec [dbo].[SP_BL_GetBeneficiariesReport_MAndM_AI] 'Comp-1152','MONTH',NULL,NULL,'Approved',NULL,1,10
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetBeneficiariesReport_MAndM_AI]
(
    @Comp_Id     NVARCHAR(50),  
    @datePreset  NVARCHAR(20) = NULL,
    @FromDate    DATE = NULL,
    @ToDate      DATE = NULL,
    @KYCStatusFilter NVARCHAR(20) = NULL,
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

    -- Normalize datePreset
    DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));
    IF (@Win = '' OR @Win = 'NULL') SET @Win = 'ALL';

    -- Explicit date range overrides datePreset
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE IF (@Win = 'TODAY')
    BEGIN
        SET @StartDate = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@Win = 'YESTERDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
        SET @EndDate = DATEADD(DAY, 1, @StartDate);
    END
    ELSE IF (@Win = 'WEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE)) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'MONTH')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE IF (@Win = 'QUARTER')
    BEGIN
        SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        SET @EndDate = DATEADD(QUARTER, 1, @StartDate);
    END
    ELSE IF (@Win = 'YEAR')
    BEGIN
        SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
        SET @EndDate = DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
    END
    ELSE -- ALL
    BEGIN
        SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- CLEAN TEMP TABLES
    ---------------------------------------------------------
    DROP TABLE IF EXISTS #Users, #State, #Benefit, #Claims, #UPI, #FinalData, #UniqueScans, #EarnedPoints, #ConfigPoints;

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
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON V.M_ConsumerId = MC.M_ConsumerId
    WHERE V.Comp_Id = @Comp_Id AND MC.IsDelete = 0;

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
            ROW_NUMBER() OVER (PARTITION BY U.M_ConsumerId ORDER BY GE.Enq_Date DESC) AS rn
        FROM #Users U
        INNER JOIN GeoLocationData GE WITH (NOLOCK) ON GE.MobileNo = U.MobileNo
        WHERE GE.Comp_Id = @Comp_Id
    ) x
    WHERE rn = 1;

    ---------------------------------------------------------
    -- BENEFIT CALCULATION (Simplified for Mahindra context)
    ---------------------------------------------------------
    SELECT
        MC.M_ConsumerId,
        SUM(ISNULL(BL.Points, 0)) AS Benefit,
        MAX(PE.Enq_Date) AS LastScan
    INTO #Benefit
    FROM Pro_Enq PE WITH (NOLOCK)
    INNER JOIN M_Code M WITH (NOLOCK) ON PE.Received_Code1 = M.Code1 AND PE.Received_Code2 = M.Code2
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON PR.Pro_ID = M.Pro_ID
    INNER JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = PE.MobileNo
    LEFT JOIN BLoyaltyPointsEarned BL WITH (NOLOCK) ON BL.M_ConsumerId = MC.M_ConsumerId AND BL.compid = PR.Comp_Id
    WHERE PR.Comp_Id = @Comp_Id AND PE.Is_Success = '1'
      AND (@StartDate IS NULL OR PE.Enq_Date >= @StartDate)
      AND (@EndDate IS NULL OR PE.Enq_Date < @EndDate)
    GROUP BY MC.M_ConsumerId;

    ---------------------------------------------------------
    -- CLAIMS + UPI
    ---------------------------------------------------------
    SELECT
        Mobileno,
        SUM(ISNULL(Amount, 0)) AS ClaimsAmount,
        SUM(ISNULL(tdsAmount, 0)) AS TDSAmount
    INTO #Claims
    FROM ClaimDetails WITH (NOLOCK)
    WHERE Comp_id = @Comp_Id AND Isapproved = 1
      AND (@StartDate IS NULL OR action_date >= @StartDate)
      AND (@EndDate   IS NULL OR action_date <  @EndDate)
    GROUP BY Mobileno;

    SELECT
        M_Consumerid,
        SUM(ISNULL(Amount, 0)) AS UPIAmount
    INTO #UPI
    FROM tblUPITransactionDetails WITH (NOLOCK)
    WHERE Comp_Id = @Comp_Id AND Status = 'Success'
      AND (@StartDate IS NULL OR ReqDate >= @StartDate)
      AND (@EndDate   IS NULL OR ReqDate <  @EndDate)
    GROUP BY M_Consumerid;

    ---------------------------------------------------------
    -- FINAL DATA
    ---------------------------------------------------------
    SELECT
        U.ConsumerName,
        U.MobileNo,
        ISNULL(S.State, U.State) AS State,
        ISNULL(S.City,  U.City)  AS City,
        U.PinCode,
        U.KYCStatus,
        ISNULL(B.Benefit, 0) AS PointsEarned,
        ISNULL(C.ClaimsAmount, 0) + ISNULL(UU.UPIAmount, 0) AS RedeemAmount,
        ISNULL(B.Benefit, 0) - (ISNULL(C.ClaimsAmount, 0) + ISNULL(UU.UPIAmount, 0)) AS BalanceAmount,
        ISNULL(C.TDSAmount, 0) AS TDSAmount,
        B.LastScan,
        ROW_NUMBER() OVER (ORDER BY ISNULL(B.Benefit, 0) DESC) AS RN
    INTO #FinalData
    FROM #Users U
    LEFT JOIN #State S ON S.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Benefit B ON B.M_ConsumerId = U.M_ConsumerId
    LEFT JOIN #Claims C ON C.Mobileno = U.MobileNo
    LEFT JOIN #UPI UU ON UU.M_Consumerid = CAST(U.M_ConsumerId AS VARCHAR(50))
    WHERE
        (@StateFilter IS NULL OR ISNULL(S.State, U.State) = @StateFilter)
        AND (@KYCStatusFilter IS NULL OR U.KYCStatus = @KYCStatusFilter)
        AND (@Search IS NULL OR U.ConsumerName LIKE '%' + @Search + '%' OR U.MobileNo LIKE '%' + @Search + '%');

    ---------------------------------------------------------
    -- OUTPUT
    ---------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        SELECT ConsumerName, MobileNo, State, City, PinCode, KYCStatus, PointsEarned, RedeemAmount, BalanceAmount, TDSAmount, LastScan
        FROM #FinalData ORDER BY RN;
    END
    ELSE
    BEGIN
        SELECT ConsumerName, MobileNo, State, City, PinCode, KYCStatus, PointsEarned, RedeemAmount, BalanceAmount, TDSAmount, LastScan
        FROM #FinalData WHERE RN BETWEEN ((@Page - 1) * @Limit) + 1 AND (@Page * @Limit) ORDER BY RN;

        SELECT COUNT(*) AS TotalRecords, @Page AS CurrentPage, @Limit AS [Limit], CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages FROM #FinalData;
    END
END;
GO
