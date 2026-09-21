USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 21-Sep-2026
-- Optimized:   21-Sep-2026 (Broad Comp_Id & Date filtering for Comp-2356)
-- Description: Get Warranty Report for Tibco Vendor API joining WarrentyDetails, M_Consumer, Pro_Enq, M_code, Pro_Reg
-- wstatus:     WarrentyDetails.IsWarrantyClaimed (NULL/0: 'Pending', 1: 'Approved', 2: 'Rejected')
-- h_code:      WarrentyDetails.Code (Format: 67531-71971822)
-- Order By:    id DESC
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_TibcoVendor_WarrantyReport_AI]
(
    @AccessKey NVARCHAR(100) = 'VI2026ACCESSKEY',
    @Comp_Id NVARCHAR(50) = 'Comp-2356',
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @ClaimStatus NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    IF (@Comp_Id IS NULL OR @Comp_Id = '')
        SET @Comp_Id = 'Comp-2356';

    DECLARE @NumericCompId NVARCHAR(50) = REPLACE(@Comp_Id, 'Comp-', '');

    ------------------------------------------------------
    -- 1. Pagination Defaults
    ------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- 2. Date Range Logic
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Prioritize explicit fromDate/toDate if provided
    IF (@FromDate IS NOT NULL)
        SET @StartDate = CAST(CONVERT(VARCHAR(10), @FromDate, 120) + ' 00:00:00' AS DATETIME);

    IF (@ToDate IS NOT NULL)
        SET @EndDate = CAST(CONVERT(VARCHAR(10), @ToDate, 120) + ' 23:59:59' AS DATETIME);

    -- If no explicit fromDate/toDate, use datePreset
    IF (@StartDate IS NULL AND @EndDate IS NULL AND @datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null' AND UPPER(@datePreset) <> 'ALL')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @TodayDt DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = @TodayDt;
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @TodayDt));
        END
        ELSE IF (@Win = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @TodayDt);
            SET @EndDate   = DATEADD(SECOND, -1, @TodayDt);
        END
        ELSE IF (@Win = 'WEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @TodayDt), @TodayDt);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TodayDt) - 1, CAST(0 AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @TodayDt), CAST(0 AS DATETIME)));
        END
        ELSE IF (@Win = 'MONTH')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TodayDt) - 1, CAST(0 AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @TodayDt), CAST(0 AS DATETIME)));
        END
        ELSE IF (@Win = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -180, @TodayDt); -- Extended to 180 days to capture recent 2 quarters
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS DATETIME);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = CAST(DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1) AS DATETIME);
            SET @EndDate   = CAST(CAST(YEAR(GETDATE()) - 1 AS VARCHAR(4)) + '-12-31 23:59:59' AS DATETIME);
        END

        IF @EndDate IS NULL SET @EndDate = GETDATE();
    END

    ------------------------------------------------------
    -- 3. Search Filter Setup
    ------------------------------------------------------
    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + LTRIM(RTRIM(@Search)) + '%';

    ------------------------------------------------------
    -- 4. Claim Status Filter Setup
    ------------------------------------------------------
    DECLARE @ClaimStatusFilter NVARCHAR(50) = NULL;
    IF @ClaimStatus IS NOT NULL AND @ClaimStatus <> '' AND LOWER(@ClaimStatus) <> 'all'
        SET @ClaimStatusFilter = LTRIM(RTRIM(@ClaimStatus));

    ------------------------------------------------------
    -- 5. Primary Filtered Dataset (Fast evaluation on WarrentyDetails)
    ------------------------------------------------------
    ;WITH FilteredWar AS (
        SELECT 
            war.[id],
            war.[Mobile],
            war.[Brand],
            war.[Pincode],
            war.[Address],
            war.[Email],
            war.[Serialno],
            war.[Model],
            war.[Comment],
            war.[VendorClaimStatus],
            war.[VendorComments],
            war.[PurchaseDate],
            war.[ExpirationDate],
            war.[IsWarrantyClaimed],
            war.[Code],
            war.[claimdate],
            war.[Comp_id],
            war.[ImagePath],
            war.[ImagePathBill],
            war.[BillNo],
            CASE 
                WHEN CHARINDEX('-', war.[Code]) > 0 THEN LEFT(war.[Code], CHARINDEX('-', war.[Code]) - 1)
                WHEN LEN(war.[Code]) = 13 THEN LEFT(war.[Code], 5)
                ELSE ''
            END AS [Code1],
            CASE 
                WHEN CHARINDEX('-', war.[Code]) > 0 THEN SUBSTRING(war.[Code], CHARINDEX('-', war.[Code]) + 1, 20)
                WHEN LEN(war.[Code]) = 13 THEN SUBSTRING(war.[Code], 6, 8)
                ELSE ''
            END AS [Code2]
        FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
        WHERE (
               @Comp_Id IS NULL OR @Comp_Id = '' 
               OR LTRIM(RTRIM(ISNULL(war.[Comp_id], ''))) = @Comp_Id 
               OR LTRIM(RTRIM(ISNULL(war.[Comp_id], ''))) = @NumericCompId
               OR war.[ImagePath] LIKE '%' + @Comp_Id + '%' 
               OR war.[ImagePathBill] LIKE '%' + @Comp_Id + '%'
               OR war.[ImagePath] LIKE '%' + @NumericCompId + '%'
               OR war.[ImagePathBill] LIKE '%' + @NumericCompId + '%'
              )
          AND (
               @StartDate IS NULL 
               OR (war.[PurchaseDate] IS NOT NULL AND war.[PurchaseDate] >= @StartDate AND war.[PurchaseDate] <= @EndDate)
               OR (war.[claimdate] IS NOT NULL AND war.[claimdate] >= @StartDate AND war.[claimdate] <= @EndDate)
               OR (war.[PurchaseDate] IS NULL AND war.[claimdate] IS NULL)
              )
          AND (@SearchParam IS NULL 
               OR war.[Mobile] LIKE @SearchParam 
               OR war.[Serialno] LIKE @SearchParam 
               OR war.[Model] LIKE @SearchParam 
               OR war.[Code] LIKE @SearchParam 
               OR war.[BillNo] LIKE @SearchParam 
               OR war.[Brand] LIKE @SearchParam
               OR war.[Email] LIKE @SearchParam)
          AND (@ClaimStatusFilter IS NULL 
               OR (@ClaimStatusFilter = 'Pending' AND (war.[IsWarrantyClaimed] IS NULL OR war.[IsWarrantyClaimed] = 0))
               OR (@ClaimStatusFilter = 'Approved' AND war.[IsWarrantyClaimed] = 1)
               OR (@ClaimStatusFilter IN ('Reject', 'Rejected') AND war.[IsWarrantyClaimed] = 2)
               OR CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)) = @ClaimStatusFilter
               OR war.[VendorClaimStatus] = @ClaimStatusFilter)
    ),
    PagedWar AS (
        SELECT *
        FROM FilteredWar
        ORDER BY [id] DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
    )
    ------------------------------------------------------
    -- 6. Final Result (Only joins M_Consumer, Pro_Reg, M_code for the 10 paged records)
    ------------------------------------------------------
    SELECT 
        ISNULL(@AccessKey, 'VI2026ACCESSKEY') AS [accessKey],
        ISNULL(p.[Mobile], ISNULL(c.[MobileNo], '')) AS [cust_mobile],
        ISNULL(c.[ConsumerName], ISNULL(p.[Brand], '')) AS [customer_name],
        ISNULL(p.[Pincode], ISNULL(c.[PinCode], '')) AS [pincode],
        ISNULL(p.[Address], ISNULL(c.[Address], '')) AS [address],
        ISNULL(p.[Email], ISNULL(c.[Email], '')) AS [email],
        ISNULL(p.[Serialno], '') AS [serial_no],
        ISNULL(p.[Model], ISNULL(pr.[Pro_Name], '')) AS [model_id],
        ISNULL(p.[Comment], '') AS [remarks],
        CASE 
            WHEN p.[VendorClaimStatus] IS NOT NULL AND p.[VendorClaimStatus] <> '' THEN p.[VendorClaimStatus]
            ELSE 'Repair' 
        END AS [complaint_type],
        ISNULL(p.[VendorComments], ISNULL(p.[Comment], 'VOC')) AS [problem_details],
        CASE 
            WHEN p.[PurchaseDate] IS NOT NULL THEN CONVERT(VARCHAR(10), p.[PurchaseDate], 120)
            ELSE ''
        END AS [dop],
        CASE 
            WHEN p.[IsWarrantyClaimed] = 1 THEN 'Approved'
            WHEN p.[IsWarrantyClaimed] = 2 THEN 'Rejected'
            ELSE 'Pending'
        END AS [wstatus],
        COALESCE(
            CASE 
                WHEN p.[Code] LIKE '%-%' THEN p.[Code]
                WHEN LEN(p.[Code]) = 13 THEN LEFT(p.[Code], 5) + '-' + SUBSTRING(p.[Code], 6, 8)
                ELSE NULL
            END,
            CASE 
                WHEN p.[Code1] <> '' AND p.[Code2] <> '' THEN p.[Code1] + '-' + p.[Code2]
                ELSE NULL
            END,
            p.[Code],
            ''
        ) AS [h_code]
    FROM PagedWar p
    LEFT JOIN [dbo].[M_Consumer] c WITH (NOLOCK) 
        ON c.[MobileNo] = p.[Mobile] AND c.[IsDelete] = 0
    LEFT JOIN [dbo].[M_code] Mc WITH (NOLOCK) 
        ON p.[Code1] <> '' AND p.[Code2] <> '' AND Mc.[Code1] = p.[Code1] AND Mc.[Code2] = p.[Code2]
    LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) 
        ON pr.[Pro_ID] = Mc.[Pro_ID]
    ORDER BY p.[id] DESC;

    ------------------------------------------------------
    -- 7. Pagination Meta Query
    ------------------------------------------------------
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    WHERE (
           @Comp_Id IS NULL OR @Comp_Id = '' 
           OR LTRIM(RTRIM(ISNULL(war.[Comp_id], ''))) = @Comp_Id 
           OR LTRIM(RTRIM(ISNULL(war.[Comp_id], ''))) = @NumericCompId
           OR war.[ImagePath] LIKE '%' + @Comp_Id + '%' 
           OR war.[ImagePathBill] LIKE '%' + @Comp_Id + '%'
           OR war.[ImagePath] LIKE '%' + @NumericCompId + '%'
           OR war.[ImagePathBill] LIKE '%' + @NumericCompId + '%'
          )
      AND (
           @StartDate IS NULL 
           OR (war.[PurchaseDate] IS NOT NULL AND war.[PurchaseDate] >= @StartDate AND war.[PurchaseDate] <= @EndDate)
           OR (war.[claimdate] IS NOT NULL AND war.[claimdate] >= @StartDate AND war.[claimdate] <= @EndDate)
           OR (war.[PurchaseDate] IS NULL AND war.[claimdate] IS NULL)
          )
      AND (@SearchParam IS NULL 
           OR war.[Mobile] LIKE @SearchParam 
           OR war.[Serialno] LIKE @SearchParam 
           OR war.[Model] LIKE @SearchParam 
           OR war.[Code] LIKE @SearchParam 
           OR war.[BillNo] LIKE @SearchParam 
           OR war.[Brand] LIKE @SearchParam
           OR war.[Email] LIKE @SearchParam)
      AND (@ClaimStatusFilter IS NULL 
           OR (@ClaimStatusFilter = 'Pending' AND (war.[IsWarrantyClaimed] IS NULL OR war.[IsWarrantyClaimed] = 0))
           OR (@ClaimStatusFilter = 'Approved' AND war.[IsWarrantyClaimed] = 1)
           OR (@ClaimStatusFilter IN ('Reject', 'Rejected') AND war.[IsWarrantyClaimed] = 2)
           OR CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)) = @ClaimStatusFilter
           OR war.[VendorClaimStatus] = @ClaimStatusFilter);
END
GO
