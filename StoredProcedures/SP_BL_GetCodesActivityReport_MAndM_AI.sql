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
    @DialModeFilter NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize company ID parameter name
    IF @Comp_Id IS NULL AND @CompId IS NOT NULL
        SET @Comp_Id = @CompId;

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
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

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
        pc.Pro_Name,
        pc.Code1,
        pc.Code2,
        CONCAT(pc.Code1, pc.Code2) AS uniquecode,
        pc.Cash AS amount_won,
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
        mc.Branch,
        mc.kycremark, 
        mc.ConsumerName, 
        pc.MobileNo,
        mc.AadharHolderName, 
        CAST(mc.aadharNumber AS VARCHAR(20)) AS aadharNumber, 
        mc.Address,
        mc.PanHolderName, 
        mc.pancard_number,
        mc.Bank_Name, 
        mc.Account_HolderNm,
        mc.Account_No, 
        mc.IFSC_Code,
        mc.DealerTechnicianId AS [Mstar_TechMasterId],
        mc.DealerCode, 
        mc.transaction_status,
        mc.dealer_state, 
        mc.designation, 
        mc.DealerType,
        CASE 
            WHEN mc.VRKbl_KYC_status = 1 THEN 'APPROVED' 
            WHEN mc.VRKbl_KYC_status = 2 THEN 'REJECTED' 
            ELSE 'PENDING' 
        END AS KycStatus,
        CASE 
            WHEN ISNULL(pc.expireCodeAmount, 0) > 0 THEN 'EXPIRED' 
            ELSE 'ACTIVE' 
        END AS SchemeStatus,
        ROW_NUMBER() OVER (
            PARTITION BY pc.Code1, pc.Code2, pc.Enq_Date
            ORDER BY pc.Enq_Date DESC
        ) AS rn
    INTO #FilteredData
    FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
    LEFT JOIN dbo.UserData_MHCroneJob mc WITH (NOLOCK) ON mc.m_consumerid = pc.m_consumerid
    LEFT JOIN dbo.GeoLocationData gc WITH (NOLOCK) ON gc.Code1 = pc.Code1 AND gc.Code2 = pc.Code2
    WHERE
        pc.Comp_Id = @ActualCompId
        AND (
            (@IsSBUTeam = 0 AND (pc.distributedid <> 'SBUTEAM' OR pc.distributedid IS NULL) AND (mc.DealerCode <> 'SBUTEAM' OR mc.DealerCode IS NULL)) OR
            (@IsSBUTeam = 1 AND (pc.distributedid = 'SBUTEAM' OR mc.DealerCode = 'SBUTEAM'))
        )
        AND (@StartDate IS NULL OR pc.Enq_Date >= @StartDate)
        AND (@EndDate IS NULL OR pc.Enq_Date < DATEADD(DAY, 1, @EndDate))
        AND (@Scheme IS NULL OR pc.Pro_Name LIKE '%' + @Scheme + '%')
        AND (@DialModeFilter IS NULL OR pc.Dial_Mode = @DialModeFilter)
        AND (@StateFilter IS NULL OR gc.State = @StateFilter)
        AND (
            @CodeStatusFilter IS NULL
            OR (@CodeStatusFilter = 'Verified' AND pc.Is_Success = 1)
            OR (@CodeStatusFilter = 'Already Scanned' AND pc.Is_Success = 2)
            OR (@CodeStatusFilter = 'Invalid' AND pc.Is_Success NOT IN (1,2))
        )
        AND (
            @Search IS NULL
            OR pc.MobileNo LIKE '%' + @Search + '%'
            OR (pc.Code1 + pc.Code2) LIKE '%' + @Search + '%'
        );

    ---------------------------------------------------------
    -- EXPORT MODE
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT * FROM #FilteredData WHERE rn = 1 ORDER BY Enq_Date DESC;
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
