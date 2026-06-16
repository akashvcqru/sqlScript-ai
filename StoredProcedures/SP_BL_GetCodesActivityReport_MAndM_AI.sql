USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Description: Codes Activity Report for Mahindra & Mahindra (Comp-1152)
-- Updated: 2026-05-08 - Switched to ConsumerPointsCashDetails and fixed DTO mapping
-- exec [dbo].[SP_BL_GetCodesActivityReport_MAndM_AI] 'Comp-1152','MONTH',null,null,null,null,1,10,0
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetCodesActivityReport_MAndM_AI]
(
    @Comp_Id NVARCHAR(15) = NULL,
    @CompId NVARCHAR(15) = NULL,
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Search NVARCHAR(20) = NULL,
    @Scheme NVARCHAR(10) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL,
    @CodeStatusFilter NVARCHAR(20) = NULL,
    @StateFilter NVARCHAR(50) = NULL,
    @DialModeFilter NVARCHAR(50) = NULL,
    @Lot NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize company ID parameter name
    IF @Comp_Id IS NULL AND @CompId IS NOT NULL
        SET @Comp_Id = @CompId;

    -- Normalize Lot parameter name (e.g., 'LOT8', 'Lot 8', 'lot8' -> '8')
    IF @Lot IS NOT NULL
    BEGIN
        SET @Lot = LTRIM(RTRIM(@Lot));
        IF UPPER(@Lot) LIKE 'LOT%'
        BEGIN
            SET @Lot = LTRIM(RTRIM(SUBSTRING(@Lot, 4, LEN(@Lot))));
        END
    END

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(15) = @Comp_Id;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

    ---------------------------------------------------------
    -- Normalize
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @Limit > 5000 SET @Limit = 5000;

    IF (@Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR @Search = 'NULL')
        SET @Search = NULL;

    IF (@Scheme IS NULL OR LTRIM(RTRIM(@Scheme)) = '' OR @Scheme = 'NULL')
        SET @Scheme = NULL;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Date range calculation
    ---------------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @Win NVARCHAR(50) = @datePreset;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
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
        ELSE
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    ---------------------------------------------------------
    -- MATERIALIZE RESULT
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#FilteredData') IS NOT NULL DROP TABLE #FilteredData;

    SELECT
        pc.Comp_id,
        pc.M_ConsumerId,
        pc.Enq_Date,
        ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) AS Pro_Name,
        pc.Code1,
        pc.Code2,
        CONCAT(pc.Code1, pc.Code2) AS uniquecode,
        CASE 
            WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, ISNULL(pc.Cash, 0))
            ELSE CASE WHEN pc.Points IS NULL OR pc.Points = 0 THEN ISNULL(pc.Cash, 0) ELSE pc.Points END
        END AS amount_won,
        CASE 
            WHEN pc.Is_Success = 1 THEN 'Verified'
            WHEN pc.Is_Success = 2 THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
        pc.Dial_Mode AS mode_of_verification,
        gc.City, 
        gc.State,
        gc.Latitude,
        gc.Longitude,
        mc.PinCode, 
        bk.Branch,
        ts.kycremark, 
        mc.ConsumerName, 
        pc.MobileNo,
        mc.AadharHolderName, 
        CAST(mc.aadharNumber AS VARCHAR(20)) AS aadharNumber, 
        mc.Address,
        mc.PanHolderName, 
        mc.pancard_number,
        bk.Bank_Name, 
        bk.Account_HolderNm,
        bk.Account_No, 
        bk.IFSC_Code,
        mc.employeeID AS [Mstar_TechMasterId],
        mc.distributorID AS DealerCode, 
        mc.transaction_status,
        mc.dealer_state, 
        mc.designation, 
        mc.DealerType,
        CASE 
            WHEN ts.VRKbl_KYC_status = 1 THEN 'APPROVED' 
            WHEN ts.VRKbl_KYC_status = 2 THEN 'REJECTED' 
            ELSE 'PENDING' 
        END AS KycStatus,
        CASE 
            WHEN ISNULL(pc.expireCodeAmount, 0) > 0 THEN 'EXPIRED' 
            ELSE 'ACTIVE' 
        END AS SchemeStatus,
        CASE 
            WHEN pc.Is_Success = 1 THEN
                CASE WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(sst.IsCash, 0) ELSE ISNULL(sst.Points, 0) END
            ELSE 0 
        END AS AssignPoint,
        CASE 
            WHEN pc.Is_Success = 1 THEN
                CASE WHEN ss.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) ELSE ISNULL(BL.Points, 0) END
            ELSE 0 
        END AS WornPoint,
        ROW_NUMBER() OVER (
            PARTITION BY pc.Code1, pc.Code2, pc.Enq_Date
            ORDER BY pc.Enq_Date DESC, mc.dealer_state, mc.pancard_number, mc.aadharNumber, pc.Dial_Mode DESC
        ) AS rn
    INTO #FilteredData
    FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
    LEFT JOIN dbo.M_Consumer mc WITH (NOLOCK) ON mc.M_Consumerid = pc.m_consumerid AND mc.IsDelete = 0
    LEFT JOIN dbo.m_dealermaster md WITH (NOLOCK) ON md.DealerTechnicianId = mc.employeeID AND md.DealerCode = mc.distributorID
    LEFT JOIN dbo.tbl_VendorViseKYCStatus ts WITH (NOLOCK) ON ts.M_Consumerid = pc.m_consumerid AND ts.Comp_Id = pc.Comp_Id
    OUTER APPLY (
        SELECT TOP 1 mb.Bank_Name, mb.Account_HolderNm, mb.Account_No, mb.IFSC_Code, mb.Branch
        FROM dbo.M_BankAccount mb WITH (NOLOCK)
        WHERE mb.M_Consumerid = pc.m_consumerid
        ORDER BY mb.Entry_Date DESC, mb.Row_ID DESC
    ) bk
    LEFT JOIN dbo.GeoLocationData gc WITH (NOLOCK) ON gc.Code1 = pc.Code1 AND gc.Code2 = pc.Code2
    LEFT JOIN dbo.M_Code mcd WITH (NOLOCK) ON mcd.Code1 = pc.Code1 AND mcd.Code2 = pc.Code2
    LEFT JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mcd.Pro_ID
    LEFT JOIN dbo.M_ServiceSubscription ss WITH (NOLOCK) 
        ON ss.Pro_ID = mcd.Pro_ID
       AND CONCAT(FORMAT(mcd.Series_Order, '000#'), FORMAT(mcd.Series_Serial, '000#'))
           BETWEEN CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
           AND CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
           AND ss.IsActive = 1 AND ss.IsDelete = 0
    LEFT JOIN dbo.M_ServiceSubscriptionTrans sst WITH (NOLOCK) 
        ON sst.Subscribe_Id = ss.Subscribe_Id
       AND sst.IsActive = 1 AND sst.IsDelete = 0
    LEFT JOIN dbo.BLoyaltyPointsEarned BL WITH (NOLOCK)
        ON BL.Code1 = pc.Code1
       AND BL.Code2 = pc.Code2
       AND BL.compid = @ActualCompId
    WHERE
        pc.Comp_Id = @ActualCompId
        AND (
            (@IsSBUTeam = 0 AND (pc.distributedid <> 'SBUTEAM' OR pc.distributedid IS NULL) AND (mc.distributorID <> 'SBUTEAM' OR mc.distributorID IS NULL)) OR
            (@IsSBUTeam = 1 AND (pc.distributedid = 'SBUTEAM' OR mc.distributorID = 'SBUTEAM'))
        )
        AND (@StartDate IS NULL OR pc.Enq_Date >= @StartDate)  and PC.Enq_Date >='2022-08-04 00:00:00.000'
        AND (@EndDate IS NULL OR pc.Enq_Date < DATEADD(DAY, 1, @EndDate))
        AND (@Scheme IS NULL OR ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) LIKE '%' + @Scheme + '%')
        AND (@DialModeFilter IS NULL OR pc.Dial_Mode = @DialModeFilter)
        AND (@StateFilter IS NULL OR gc.State = @StateFilter)
        AND (
            @CodeStatusFilter IS NULL
            OR (@CodeStatusFilter = 'Verified' AND pc.Is_Success = 1)
            OR ((@CodeStatusFilter = 'Already Scanned' OR @CodeStatusFilter = 'Already Verified') AND pc.Is_Success = 2)
            OR (@CodeStatusFilter = 'Invalid' AND pc.Is_Success NOT IN (1,2))
        )
        AND (
            @Search IS NULL
            OR pc.MobileNo LIKE '%' + @Search + '%'
            OR (pc.Code1 + pc.Code2) LIKE '%' + @Search + '%'
        )
        AND (
            @Lot IS NULL
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 4) = @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 4) = 'MCS' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 4) = 'mcs' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 5) = '_' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 5) = '_MCS' + @Lot
            OR RIGHT(ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name), 5) = '_mcs' + @Lot
            OR ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) LIKE '%' + @Lot
        ) OPTION (RECOMPILE);

    ---------------------------------------------------------
    -- EXPORT MODE
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT 
            Enq_Date, Pro_Name, Code1, Code2, uniquecode, amount_won, Result, 
            mode_of_verification, City, State, Latitude, Longitude, PinCode, Branch, 
            kycremark, ConsumerName, MobileNo, AadharHolderName, aadharNumber, 
            Address, PanHolderName, pancard_number, Bank_Name, Account_HolderNm, 
            Account_No, IFSC_Code, Mstar_TechMasterId, DealerCode, 
            transaction_status, dealer_state, designation, DealerType, 
            KycStatus, SchemeStatus, AssignPoint, WornPoint
        FROM #FilteredData 
        WHERE rn = 1 
        ORDER BY Enq_Date DESC;
        RETURN;
    END

    ---------------------------------------------------------
    -- NORMAL MODE → PAGINATION
    ---------------------------------------------------------
    SELECT *
    FROM #FilteredData
    WHERE rn = 1 
    ORDER BY Enq_Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ---------------------------------------------------------
    -- META
    ---------------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #FilteredData
    WHERE rn = 1;

    DROP TABLE IF EXISTS #FilteredData;
END;
GO
