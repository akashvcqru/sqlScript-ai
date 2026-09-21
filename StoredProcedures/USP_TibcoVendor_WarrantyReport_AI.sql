USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 21-Sep-2026
-- Description: Get Warranty Report for Tibco Vendor API joining WarrentyDetails, M_Consumer, Pro_Enq, M_code, Pro_Reg
-- wstatus:     WarrentyDetails.IsWarrantyClaimed (NULL/0: 'Pending', 1: 'Approved', 2: 'Rejected')
-- h_code:      WarrentyDetails.Code (Format: 67531-71971822)
-- Order By:    Pro_Enq.Enq_Date DESC
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_TibcoVendor_WarrantyReport_AI]
(
    @AccessKey NVARCHAR(100) = 'VI2026ACCESSKEY',
    @Comp_Id NVARCHAR(50) = NULL,
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

    ------------------------------------------------------
    -- Pagination Defaults
    ------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- Date Range Logic (datePreset)
    ------------------------------------------------------
    DECLARE @StartDate DATETIME = @FromDate;
    DECLARE @EndDate   DATETIME = @ToDate;

    IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null')
    BEGIN
        DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
        BEGIN
            SET @StartDate = CAST(@Today AS DATETIME);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
        END
        ELSE IF (@Win = 'WEEK')
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
        END
        ELSE IF (@Win = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END

        IF @EndDate IS NULL SET @EndDate = GETDATE();
    END

    ------------------------------------------------------
    -- Search Filter Setup
    ------------------------------------------------------
    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + @Search + '%';

    ------------------------------------------------------
    -- Claim Status Filter Setup
    ------------------------------------------------------
    DECLARE @ClaimStatusFilter NVARCHAR(50) = NULL;
    IF @ClaimStatus IS NOT NULL AND @ClaimStatus <> '' AND LOWER(@ClaimStatus) <> 'all'
        SET @ClaimStatusFilter = @ClaimStatus;

    ------------------------------------------------------
    -- Main Result Query
    ------------------------------------------------------
    ;WITH MainResult AS (
        SELECT    
            war.[id],
            ISNULL(@AccessKey, 'VI2026ACCESSKEY') AS [accessKey],
            ISNULL(war.[Mobile], ISNULL(c.[MobileNo], ISNULL(pe.[MobileNo], ''))) AS [cust_mobile],
            ISNULL(c.[ConsumerName], ISNULL(war.[Brand], '')) AS [customer_name],
            ISNULL(war.[Pincode], ISNULL(c.[PinCode], ISNULL(pe.[PinCode], ''))) AS [pincode],
            ISNULL(war.[Address], ISNULL(c.[Address], '')) AS [address],
            ISNULL(war.[Email], ISNULL(c.[Email], '')) AS [email],
            ISNULL(war.[Serialno], '') AS [serial_no],
            ISNULL(war.[Model], ISNULL(pr.[Pro_Name], '')) AS [model_id],
            ISNULL(war.[Comment], '') AS [remarks],
            CASE 
                WHEN war.[VendorClaimStatus] IS NOT NULL AND war.[VendorClaimStatus] <> '' THEN war.[VendorClaimStatus]
                ELSE 'Repair' 
            END AS [complaint_type],
            ISNULL(war.[VendorComments], ISNULL(war.[Comment], 'VOC')) AS [problem_details],
            CASE 
                WHEN war.[PurchaseDate] IS NOT NULL THEN CONVERT(VARCHAR(10), war.[PurchaseDate], 120)
                ELSE ''
            END AS [dop],
            CASE 
                WHEN war.[IsWarrantyClaimed] = 1 THEN 'Approved'
                WHEN war.[IsWarrantyClaimed] = 2 THEN 'Rejected'
                ELSE 'Pending'
            END AS [wstatus],
            COALESCE(
                CASE 
                    WHEN war.[Code] LIKE '%-%' THEN war.[Code]
                    WHEN LEN(war.[Code]) = 13 THEN LEFT(war.[Code], 5) + '-' + SUBSTRING(war.[Code], 6, 8)
                    ELSE NULL
                END,
                CASE 
                    WHEN Mc.[Code1] IS NOT NULL AND Mc.[Code2] IS NOT NULL THEN CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20))
                    ELSE NULL
                END,
                war.[Code],
                ''
            ) AS [h_code],
            ISNULL(pe.[Enq_Date], war.[claimdate]) AS [Enq_Date],
            war.[claimdate] AS [ClaimDate]
        FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
        LEFT JOIN [dbo].[M_code] Mc WITH (NOLOCK) 
            ON (CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code] 
                OR CAST(Mc.[Code1] AS VARCHAR(20)) + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
                OR (LEN(war.[Code]) = 13 AND Mc.[Code1] = LEFT(war.[Code], 5) AND Mc.[Code2] = SUBSTRING(war.[Code], 6, 8)))
        LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) 
            ON pr.[Pro_ID] = Mc.[Pro_ID]
        OUTER APPLY (
            SELECT TOP 1 
                peq.[Enq_Date], 
                peq.[MobileNo], 
                peq.[PinCode], 
                peq.[City], 
                peq.[state],
                peq.[Latitude], 
                peq.[Longitude], 
                peq.[Dial_Mode]
            FROM [dbo].[Pro_Enq] peq WITH (NOLOCK)
            WHERE (Mc.[Code1] IS NOT NULL AND peq.[Received_Code1] = CAST(Mc.[Code1] AS NVARCHAR(50)) AND peq.[Received_Code2] = CAST(Mc.[Code2] AS NVARCHAR(50)))
               OR (RIGHT(peq.[MobileNo], 10) = RIGHT(war.[Mobile], 10))
            ORDER BY peq.[Enq_Date] DESC
        ) pe
        OUTER APPLY (
            SELECT TOP 1 
                mcon.[ConsumerName], 
                mcon.[MobileNo], 
                mcon.[Email], 
                mcon.[PinCode], 
                mcon.[Address], 
                mcon.[City], 
                mcon.[state]
            FROM [dbo].[M_Consumer] mcon WITH (NOLOCK)
            WHERE (mcon.[MobileNo] = war.[Mobile] OR RIGHT(mcon.[MobileNo], 10) = RIGHT(war.[Mobile], 10))
              AND mcon.[IsDelete] = 0
            ORDER BY mcon.[M_Consumerid] DESC
        ) c
        WHERE (@Comp_Id IS NULL OR @Comp_Id = '' OR war.[Comp_id] = @Comp_Id OR pr.[Comp_ID] = @Comp_Id)
          AND (@StartDate IS NULL OR pe.[Enq_Date] >= @StartDate OR war.[claimdate] >= @StartDate OR war.[PurchaseDate] >= @StartDate)
          AND (@EndDate IS NULL OR pe.[Enq_Date] <= @EndDate OR war.[claimdate] <= @EndDate OR war.[PurchaseDate] <= @EndDate)
          AND (@SearchParam IS NULL 
               OR war.[Mobile] LIKE @SearchParam 
               OR c.[MobileNo] LIKE @SearchParam
               OR pe.[MobileNo] LIKE @SearchParam
               OR c.[ConsumerName] LIKE @SearchParam
               OR war.[Serialno] LIKE @SearchParam 
               OR war.[Model] LIKE @SearchParam
               OR war.[Code] LIKE @SearchParam
               OR war.[BillNo] LIKE @SearchParam)
          AND (@ClaimStatusFilter IS NULL 
               OR (@ClaimStatusFilter = 'Pending' AND (war.[IsWarrantyClaimed] IS NULL OR war.[IsWarrantyClaimed] = 0))
               OR (@ClaimStatusFilter = 'Approved' AND war.[IsWarrantyClaimed] = 1)
               OR (@ClaimStatusFilter IN ('Reject', 'Rejected') AND war.[IsWarrantyClaimed] = 2)
               OR CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)) = @ClaimStatusFilter
               OR war.[VendorClaimStatus] = @ClaimStatusFilter)
    )
    SELECT 
        [accessKey],
        [cust_mobile],
        [customer_name],
        [pincode],
        [address],
        [email],
        [serial_no],
        [model_id],
        [remarks],
        [complaint_type],
        [problem_details],
        [dop],
        [wstatus],
        [h_code]
    FROM MainResult
    ORDER BY [Enq_Date] DESC, [id] DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ------------------------------------------------------
    -- Pagination Meta Query
    ------------------------------------------------------
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    LEFT JOIN [dbo].[M_code] Mc WITH (NOLOCK) 
        ON (CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code] 
            OR CAST(Mc.[Code1] AS VARCHAR(20)) + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]
            OR (LEN(war.[Code]) = 13 AND Mc.[Code1] = LEFT(war.[Code], 5) AND Mc.[Code2] = SUBSTRING(war.[Code], 6, 8)))
    LEFT JOIN [dbo].[Pro_Reg] pr WITH (NOLOCK) 
        ON pr.[Pro_ID] = Mc.[Pro_ID]
    OUTER APPLY (
        SELECT TOP 1 
            peq.[Enq_Date], 
            peq.[MobileNo], 
            peq.[PinCode]
        FROM [dbo].[Pro_Enq] peq WITH (NOLOCK)
        WHERE (Mc.[Code1] IS NOT NULL AND peq.[Received_Code1] = CAST(Mc.[Code1] AS NVARCHAR(50)) AND peq.[Received_Code2] = CAST(Mc.[Code2] AS NVARCHAR(50)))
           OR (RIGHT(peq.[MobileNo], 10) = RIGHT(war.[Mobile], 10))
        ORDER BY peq.[Enq_Date] DESC
    ) pe
    OUTER APPLY (
        SELECT TOP 1 
            mcon.[ConsumerName], 
            mcon.[MobileNo]
        FROM [dbo].[M_Consumer] mcon WITH (NOLOCK)
        WHERE (mcon.[MobileNo] = war.[Mobile] OR RIGHT(mcon.[MobileNo], 10) = RIGHT(war.[Mobile], 10))
          AND mcon.[IsDelete] = 0
        ORDER BY mcon.[M_Consumerid] DESC
    ) c
    WHERE (@Comp_Id IS NULL OR @Comp_Id = '' OR war.[Comp_id] = @Comp_Id OR pr.[Comp_ID] = @Comp_Id)
      AND (@StartDate IS NULL OR pe.[Enq_Date] >= @StartDate OR war.[claimdate] >= @StartDate OR war.[PurchaseDate] >= @StartDate)
      AND (@EndDate IS NULL OR pe.[Enq_Date] <= @EndDate OR war.[claimdate] <= @EndDate OR war.[PurchaseDate] <= @EndDate)
      AND (@SearchParam IS NULL 
           OR war.[Mobile] LIKE @SearchParam 
           OR c.[MobileNo] LIKE @SearchParam
           OR pe.[MobileNo] LIKE @SearchParam
           OR c.[ConsumerName] LIKE @SearchParam
           OR war.[Serialno] LIKE @SearchParam 
           OR war.[Model] LIKE @SearchParam
           OR war.[Code] LIKE @SearchParam
           OR war.[BillNo] LIKE @SearchParam)
      AND (@ClaimStatusFilter IS NULL 
           OR (@ClaimStatusFilter = 'Pending' AND (war.[IsWarrantyClaimed] IS NULL OR war.[IsWarrantyClaimed] = 0))
           OR (@ClaimStatusFilter = 'Approved' AND war.[IsWarrantyClaimed] = 1)
           OR (@ClaimStatusFilter IN ('Reject', 'Rejected') AND war.[IsWarrantyClaimed] = 2)
           OR CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)) = @ClaimStatusFilter
           OR war.[VendorClaimStatus] = @ClaimStatusFilter);
END
GO
