/****** Object:  StoredProcedure [dbo].[SP_BL_GetNewUsersAndKYCReportAutoFilterData_MAndM_AI]    Script Date: 3/2/2026 12:27:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Antigravity
-- Create date: 08-05-2026
-- Description:	Get New Users and KYC Report for Mahindra & Mahindra (M&M) Dashboard
-- =============================================
ALTER PROCEDURE [dbo].[SP_BL_GetNewUsersAndKYCReportAutoFilterData_MAndM_AI]
    @Comp_Id VARCHAR(15),
    @datePreset NVARCHAR(20) = NULL ,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate DATE = NULL,              
    @ToDate DATE = NULL,                
    @KYCStatusFilter NVARCHAR(20) = NULL,
    @StateFilter NVARCHAR(100) = NULL,   
    @Page INT = NULL,                    
    @Limit INT = NULL,
    @IsExport BIT =NULL,
    @Search nvarchar(30) = null
  
AS
BEGIN
   SET NOCOUNT ON;

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

        ELSE IF (@datePreset = 'LASTDAY')
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

	IF OBJECT_ID('tempdb..#TempDealerMaster') IS NOT NULL
    DROP TABLE #TempDealerMaster;
	SELECT 
    DealerCode, DealerTechnicianId, D_Name,D_state,DealerLocation, DealerType
INTO #TempDealerMaster
FROM
(
    SELECT  DealerCode, DealerTechnicianId, D_Name,D_state,DealerLocation, DealerType 
    FROM m_dealermaster 
    WHERE Comp_id = @ActualCompId 
      AND (
            (@IsSBUTeam = 0 AND DealerCode != 'SBUTEAM') OR
            (@IsSBUTeam = 1 AND DealerCode = 'SBUTEAM')
          )
    UNION
    SELECT  DealerCode, DealerTechnicianId, D_Name,D_state,DealerLocation, DealerType FROM m_dealermaster_mahindra_emp where Comp_id = @ActualCompId
) AS A;


    ------------------------------------------------------
    -- Base WHERE clause
    ------------------------------------------------------
    DECLARE @BaseWhere NVARCHAR(MAX) = N'
        WHERE VKS.Comp_ID = @Comp_Id
          AND MC.IsDelete = 0
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
            (@KYCStatusFilter = ''PENDING'' AND (VKS.VRKbl_KYC_status = 0 OR VKS.VRKbl_KYC_status IS NULL))
        )';

    IF @StateFilter IS NOT NULL AND LTRIM(RTRIM(@StateFilter)) <> ''
        SET @BaseWhere += N' AND MC.[State] = @StateFilter';

    ------------------------------------------------------
    -- Mobile Number Search
    ------------------------------------------------------
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
        SET @BaseWhere += N' AND MC.MobileNo LIKE ''%'' + @Search + ''%''';

    ------------------------------------------------------
    -- Data Query
    ------------------------------------------------------
 
    DECLARE @SQLData NVARCHAR(MAX) = N'
    SELECT
        MC.ConsumerName,
        MC.MobileNo,
        MC.City,
        MC.PinCode,
        TD.D_state AS state,
		TD.DealerLocation, TD.DealerType,
        -- KYC Status
        CASE 
            WHEN VKS.VRKbl_KYC_status = 1 THEN ''KYC Approved''
            WHEN VKS.VRKbl_KYC_status = 2 THEN ''KYC Rejected''
            WHEN VKS.VRKbl_KYC_status = 3 THEN ''Send Request again''
            ELSE ''KYC Pending''
        END AS KYCStatus,

        -- KYC channel-wise statuses
        CASE WHEN MC.panekycStatus IN (''1'', ''Online'') THEN ''Online'' ELSE ISNULL(MC.panekycStatus, '''') END AS panekycStatus,
        CASE WHEN MC.bankekycStatus IN (''1'', ''Online'') THEN ''Online'' ELSE ISNULL(MC.bankekycStatus, '''') END AS bankekycStatus,

        MC.pancard_number,
        VKS.kycremark,

        -- Mahindra Specific Fields
        MC.employeeID AS techmasterID,
        MC.MstarID,
        MC.distributorID AS Dealercode,
        MC.designation AS Designation,

        -- Bank Information (Latest Bank Record)
        MB.[Bank_Name] AS bankName,
        MB.Account_HolderNm,
        MB.Account_No,
        MB.Branch,
        MB.IFSC_Code,

        -- Additional Details
        VKS.Entry_Date,
        MC.M_Consumerid
    FROM tbl_Vendorvisekycstatus VKS
    INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
	LEFT JOIN #TempDealerMaster TD ON MC.employeeID=TD.DealerTechnicianId AND MC.distributorID=TD.DealerCode
    OUTER APPLY (
        SELECT TOP 1 *
        FROM M_BankAccount MB
        WHERE MB.M_Consumerid = MC.M_Consumerid
        ORDER BY MB.Entry_Date DESC
    ) MB
    ' + @BaseWhere + N'
    ORDER BY VKS.Entry_Date DESC';

    IF @IsExport = 0
        SET @SQLData += N' OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY';

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
        FROM tbl_Vendorvisekycstatus VKS
        INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
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
            @Offset,
            @Limit,
            @Page;
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
            @Offset,
            @Limit,
            @Page;
    END
END
GO
