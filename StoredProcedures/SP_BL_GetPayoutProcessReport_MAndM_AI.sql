USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Antigravity
-- Create date: 12-06-2026
-- Description:	Get Payout Process Report for Mahindra & Mahindra (M&M) Dashboard
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetPayoutProcessReport_MAndM_AI]
    @Comp_Id VARCHAR(15),
    @datePreset NVARCHAR(20) = NULL,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate DATE = NULL,              
    @ToDate DATE = NULL,                
    @KYCStatusFilter NVARCHAR(20) = NULL,
    @StateFilter NVARCHAR(100) = NULL,   
    @Page INT = NULL,                    
    @Limit INT = NULL,
    @IsExport BIT = NULL,
    @Search NVARCHAR(30) = NULL,
    @Lot NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Normalize Lot parameter name (e.g., 'LOT8', 'Lot 8' -> '8')
    ------------------------------------------------------
    IF @Lot IS NOT NULL
    BEGIN
        SET @Lot = LTRIM(RTRIM(@Lot));
        IF UPPER(@Lot) LIKE 'LOT%'
        BEGIN
            SET @Lot = LTRIM(RTRIM(SUBSTRING(@Lot, 4, LEN(@Lot))));
        END
    END

    ------------------------------------------------------
    -- SBU Company Check Logic
    ------------------------------------------------------
    DECLARE @ActualCompId VARCHAR(15) = @Comp_Id;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

    ------------------------------------------------------
    -- Pagination Defaults
    ------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- Date Range
    ------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @ActualCompId AND Status = 1;

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

    -- Normalize KYCStatusFilter
    IF @KYCStatusFilter IS NOT NULL
    BEGIN
        SET @KYCStatusFilter = UPPER(LTRIM(RTRIM(@KYCStatusFilter)));
        IF @KYCStatusFilter IN ('1', 'APPROVED', 'APPROVE')
            SET @KYCStatusFilter = 'APPROVED';
        ELSE IF @KYCStatusFilter IN ('2', 'REJECTED', 'REJECT')
            SET @KYCStatusFilter = 'REJECTED';
        ELSE IF @KYCStatusFilter IN ('0', 'PENDING', '3')
            SET @KYCStatusFilter = 'PENDING';
    END

    -- Explicit date range overrides datePreset
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF (@datePreset = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@datePreset = 'LASTDAY' OR @datePreset = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@datePreset = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@datePreset = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                                DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@datePreset = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@datePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                                DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@datePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                                DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @EndDate), 0));
        END

        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), 1, 1);
        END

        ELSE IF (@datePreset = 'LASTYEAR')
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

    ------------------------------------------------------
    -- Temp Dealer Master
    ------------------------------------------------------
	IF OBJECT_ID('tempdb..#TempDealerMaster') IS NOT NULL
        DROP TABLE #TempDealerMaster;

	SELECT 
        DealerCode, DealerTechnicianId, D_Name, D_state, DealerLocation, DealerType, D_Status, DE_Designation
    INTO #TempDealerMaster
    FROM
    (
        SELECT DealerCode, DealerTechnicianId, D_Name, D_state, DealerLocation, DealerType, D_Status, DE_Designation 
        FROM m_dealermaster 
        WHERE Comp_id = @ActualCompId 
          AND (
                (@IsSBUTeam = 0 AND DealerCode != 'SBUTEAM') OR
                (@IsSBUTeam = 1 AND DealerCode = 'SBUTEAM')
              )
        UNION
        SELECT DealerCode, DealerTechnicianId, D_Name, D_state, DealerLocation, DealerType, D_Status, DE_Designation 
        FROM m_dealermaster_mahindra_emp 
        WHERE Comp_id = @ActualCompId
    ) AS A;

    ------------------------------------------------------
    -- Base WHERE clause
    ------------------------------------------------------
    DECLARE @BaseWhere NVARCHAR(MAX) = N'
        WHERE VKS.Comp_ID = @Comp_Id
          AND VKS.rn = 1
          AND MC.IsDelete = 0
		  AND MC.distributorID IS NOT NULL
          AND (
                (' + CAST(@IsSBUTeam AS VARCHAR(1)) + ' = 0 AND (MC.distributorID != ''SBUTEAM'' OR MC.distributorID IS NULL)) OR
                (' + CAST(@IsSBUTeam AS VARCHAR(1)) + ' = 1 AND MC.distributorID = ''SBUTEAM'')
              )';

    IF @StartDate IS NOT NULL
        SET @BaseWhere += N' AND CAST(VKS.Entry_Date AS DATE) BETWEEN @StartDate AND @EndDate';

    IF @KYCStatusFilter IS NOT NULL
        SET @BaseWhere += N'
        AND (
            (@KYCStatusFilter = ''APPROVED'' AND VKS.VRKbl_KYC_status = 1) OR
            (@KYCStatusFilter = ''REJECTED'' AND VKS.VRKbl_KYC_status = 2) OR
            (@KYCStatusFilter = ''PENDING'' AND (VKS.VRKbl_KYC_status NOT IN (1, 2) OR VKS.VRKbl_KYC_status IS NULL))
        )';

    IF @StateFilter IS NOT NULL AND LTRIM(RTRIM(@StateFilter)) <> ''
        SET @BaseWhere += N' AND MC.[State] = @StateFilter';

    ------------------------------------------------------
    -- Mobile Number / Name Search
    ------------------------------------------------------
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
        SET @BaseWhere += N' AND (MC.MobileNo LIKE ''%'' + @Search + ''%'' OR MC.ConsumerName LIKE ''%'' + @Search + ''%'')';

    ------------------------------------------------------
    -- Lot Filter (For Comp-1152)
    -- Pro_Name pattern: e.g. 'M&M_Star_Scheme_MCS6'  RIGHT(4) = 'MCS6'
    -- @Lot is already normalized (LOT prefix stripped above, e.g. 'MCS6')
    -- Checks BOTH pr.Pro_Name (via M_Code join) AND pc.Pro_Name (stored on transaction)
    -- independently so either source matching is sufficient.
    ------------------------------------------------------
    IF @Lot IS NOT NULL AND LTRIM(RTRIM(@Lot)) <> ''
    BEGIN
        SET @BaseWhere += N'
        AND MC.M_Consumerid IN (
            SELECT DISTINCT pc.M_Consumerid 
            FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
            LEFT JOIN dbo.M_Code mcd WITH (NOLOCK) ON mcd.Code1 = pc.Code1 AND mcd.Code2 = pc.Code2
            LEFT JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mcd.Pro_ID
            WHERE pc.Comp_Id = @Comp_Id
              AND pc.Is_Success = 1
              AND (
                    -- Match via Pro_Reg Pro_Name (canonical name from product registration)
                    RIGHT(UPPER(ISNULL(pr.Pro_Name, '''')), 4) = UPPER(@Lot)
                    OR RIGHT(UPPER(ISNULL(pr.Pro_Name, '''')), LEN(@Lot) + 1) = ''_'' + UPPER(@Lot)
                    OR UPPER(ISNULL(pr.Pro_Name, '''')) LIKE ''%[_]'' + UPPER(@Lot)
                    -- Match via Pro_Name stored directly on the transaction record
                    OR RIGHT(UPPER(ISNULL(pc.Pro_Name, '''')), 4) = UPPER(@Lot)
                    OR RIGHT(UPPER(ISNULL(pc.Pro_Name, '''')), LEN(@Lot) + 1) = ''_'' + UPPER(@Lot)
                    OR UPPER(ISNULL(pc.Pro_Name, '''')) LIKE ''%[_]'' + UPPER(@Lot)
              )
        )';
    END

    ------------------------------------------------------
    -- Query result selection
    -- SumOfTotalAmount is calculated here so we can ORDER BY it for pagination
    ------------------------------------------------------
    DECLARE @SQLData NVARCHAR(MAX) = N'
    SELECT
        ROW_NUMBER() OVER (ORDER BY (ISNULL(PointsCash.TotalEarned, 0) - ISNULL(Trans.TotalRedeemed, 0)) DESC, VKS.Entry_date DESC) AS SN,
        MC.M_Consumerid AS M_Consumerid,
        MC.MobileNo AS UserNumber,
        MC.employeeID AS TechmasterID,
        MC.MStarId AS MstarID,
        CASE 
            WHEN TD.D_Status IS NOT NULL THEN UPPER(TD.D_Status) + '' MSTAR'' 
            ELSE ''INACTIVE'' 
        END AS IDStatus,
        CASE 
            WHEN MC.panekycStatus IN (''1'', ''Online'') 
              OR MC.aadharkycStatus IN (''1'', ''Online'') 
              OR MC.bankekycStatus IN (''1'', ''Online'') THEN ''ONLINE''
            ELSE ''MANUAL''
        END AS ModeOfKYC,
        MC.distributorID AS DealerCode,
        ISNULL(TD.D_state, MC.[state]) AS [State],
        ISNULL(TD.DE_Designation, MC.designation) AS Designation,
        MC.ConsumerName AS NameAsPerFDW,
        MB.Bank_Name AS BankName,
        MB.Account_HolderNm AS NameAsPerBank,
        MB.Account_No AS AccountNo,
        MB.IFSC_Code AS IFSCcode,
        MB.Branch AS Branch,
        MC.pancard_number AS PanCard,
        MC.PanHolderName AS NameAsPerPan,
        CASE 
            WHEN MC.panekycStatus IN (''1'', ''Online'') 
              OR MC.Pancard_Status IN (''1'', ''Online'', ''Approved'', ''Y'') THEN ''Y'' 
            ELSE ''N'' 
        END AS PanStatus,
        CASE 
            WHEN VKS.VRKbl_KYC_status = 1 THEN ''APPROVED''
            WHEN VKS.VRKbl_KYC_status = 2 THEN ''REJECTED''
            ELSE ''PENDING''
        END AS [Status],
        VKS.kycremark AS Comments,
        ISNULL(PointsCash.TotalEarned, 0) - ISNULL(Trans.TotalRedeemed, 0) AS SumOfTotalAmount
    INTO #TempPaged
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY M_Consumerid, Comp_Id ORDER BY Entry_date DESC) AS rn
        FROM tbl_Vendorvisekycstatus WITH (NOLOCK)
    ) VKS
    INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
    LEFT JOIN #TempDealerMaster TD ON MC.employeeID = TD.DealerTechnicianId AND MC.distributorID = TD.DealerCode
    OUTER APPLY (
        SELECT TOP 1 *
        FROM M_BankAccount MB
        WHERE MB.M_Consumerid = MC.M_Consumerid
        ORDER BY MB.Entry_Date DESC
    ) MB
    OUTER APPLY (
        SELECT ISNULL(SUM(CASE WHEN pc.Points IS NULL OR pc.Points = 0 THEN ISNULL(pc.Cash, 0) ELSE pc.Points END), 0) AS TotalEarned
        FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
        WHERE pc.M_Consumerid = MC.M_Consumerid
          AND pc.Comp_Id = @Comp_Id
          AND pc.Is_Success = 1
    ) PointsCash
    OUTER APPLY (
        SELECT ISNULL(SUM(t.Amount), 0) AS TotalRedeemed
        FROM dbo.Transactions t WITH (NOLOCK)
        WHERE t.M_CounserID = CAST(MC.M_Consumerid AS VARCHAR(50))
          AND t.CompId = REPLACE(@Comp_Id, ''Comp-'', '''')
          AND t.Issuccess = 1
    ) Trans
    ' + @BaseWhere + N' ORDER BY (ISNULL(PointsCash.TotalEarned, 0) - ISNULL(Trans.TotalRedeemed, 0)) DESC, VKS.Entry_date DESC';

    IF @IsExport = 0
        SET @SQLData += N' OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY';

    SET @SQLData += N';
    SELECT 
        tp.*
    FROM #TempPaged tp
    ORDER BY tp.SN;
    DROP TABLE #TempPaged;';

    ------------------------------------------------------
    -- Count Query (only for non-export)
    ------------------------------------------------------
    DECLARE @SQLCount NVARCHAR(MAX) = N'';

    IF @IsExport = 0
    BEGIN
        SET @SQLCount = N'
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY M_Consumerid, Comp_Id ORDER BY Entry_date DESC) AS rn
            FROM tbl_Vendorvisekycstatus WITH (NOLOCK)
        ) VKS
        INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
        LEFT JOIN #TempDealerMaster TD ON MC.employeeID = TD.DealerTechnicianId AND MC.distributorID = TD.DealerCode
        ' + @BaseWhere;
    END

    ------------------------------------------------------
    -- Execute
    ------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        EXEC sp_executesql
            @SQLData,
            N'
                @Comp_Id VARCHAR(15),
                @StartDate DATE,
                @EndDate DATE,
                @KYCStatusFilter NVARCHAR(20),
                @StateFilter NVARCHAR(100),
                @Search NVARCHAR(30),
                @Lot NVARCHAR(50)
            ',
            @ActualCompId,
            @StartDate,
            @EndDate,
            @KYCStatusFilter,
            @StateFilter,
            @Search,
            @Lot;
    END
    ELSE
    BEGIN
        DECLARE @FinalSQL NVARCHAR(MAX);
        SET @FinalSQL = @SQLData + N'; ' + @SQLCount;

        EXEC sp_executesql
            @FinalSQL,
            N'
                @Comp_Id VARCHAR(15),
                @StartDate DATE,
                @EndDate DATE,
                @KYCStatusFilter NVARCHAR(20),
                @StateFilter NVARCHAR(100),
                @Search NVARCHAR(30),
                @Lot NVARCHAR(50),
                @Offset INT,
                @Limit INT,
                @Page INT
            ',
            @ActualCompId,
            @StartDate,
            @EndDate,
            @KYCStatusFilter,
            @StateFilter,
            @Search,
            @Lot,
            @Offset,
            @Limit,
            @Page;
    END

    DROP TABLE IF EXISTS #TempDealerMaster;
END;
GO
