USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_WarrantyReport_AI]    Script Date: 7/17/2026 3:54:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Apr-2026
-- Description: Get Warranty Report for Company Dashboard with Pagination and TimeWindow
-- Reference:   GetWarrantyDetails
-- =============================================
ALTER   PROCEDURE [dbo].[USP_WarrantyReport_AI]
(
    @Comp_Id VARCHAR(50),
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
    -- Date Range Logic
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
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0));
        END
        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
        END
        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
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
            
        IF @EndDate IS NULL SET @EndDate = GETDATE();
    END

    ------------------------------------------------------
    -- Search Param
    ------------------------------------------------------
    DECLARE @SearchParam NVARCHAR(102) = NULL;
    IF @Search IS NOT NULL AND @Search <> ''
        SET @SearchParam = '%' + @Search + '%';

    ------------------------------------------------------
    -- Claim Status Param
    ------------------------------------------------------
    DECLARE @ClaimStatusFilter NVARCHAR(50) = NULL;
    IF @ClaimStatus IS NOT NULL AND @ClaimStatus <> '' AND LOWER(@ClaimStatus) <> 'all'
        SET @ClaimStatusFilter = @ClaimStatus;

    ------------------------------------------------------
    -- Main Query
    ------------------------------------------------------
    ;WITH MainResult AS (
        SELECT    
            war.[id],    
            CASE 
                WHEN @Comp_Id = 'Comp-1913' THEN war.Serialno
                ELSE war.[BillNo]
            END AS [BillNo],
            war.OldSerialno,
            pr.[Pro_Name] AS [Product_Name],    
            (SELECT TOP 1 Logo_Path FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = pr.Comp_ID) AS [LogoPath],
            CONCAT(Mc.[Code1], Mc.[Code2]) AS [Code],    
            war.[Mobile],    
            war.[Email] AS [EmailID],
            war.[WarrantyPeriod],    
            war.[PurchaseDate],    
            war.[ExpirationDate],    
            DATEDIFF(DAY, GETDATE(), war.[ExpirationDate]) AS [NumberOfDays],    
            war.[ImagePathBill],    
            ISNULL(CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)), '') AS [IsWarrantyClaimed],
            war.[ImagePath],    
            war.[VendorComments],    
            war.[Comment],    
            CASE 
                WHEN war.[IsWarrantyClaimed] = '0' THEN 'Pending' 
                WHEN war.[IsWarrantyClaimed] ='1' THEN 'Approved' 
                WHEN war.[IsWarrantyClaimed] ='2' THEN 'Reject' 
                ELSE ISNULL(war.[VendorClaimStatus], '') 
            END AS VendorClaimStatus,   
            war.claimdate as [ClaimDate],  
            CASE 
                WHEN @Comp_Id = 'Comp-1827' THEN war.SerialNo
                WHEN @Comp_Id = 'Comp-1993' THEN war.SerialNo
                ELSE war.[State]
            END AS [State],
            war.Comp_id,
            ISNULL(c.ConsumerName, '') AS [UserName]
        FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
        INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]    
        INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]    
        LEFT JOIN [dbo].[M_Consumer] c WITH (NOLOCK) ON RIGHT(c.MobileNo, 10) = RIGHT(war.Mobile, 10) AND c.IsDelete = 0
        WHERE pr.[Comp_ID] = @Comp_Id and  IsWarrantyClaimed is not null
          AND (@StartDate IS NULL OR war.claimdate >= @StartDate)
          AND (@EndDate IS NULL OR war.claimdate <= @EndDate)
          AND (@SearchParam IS NULL OR war.Mobile LIKE @SearchParam OR war.BillNo LIKE @SearchParam OR war.SerialNo LIKE @SearchParam)
          AND (@ClaimStatusFilter IS NULL OR CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)) = @ClaimStatusFilter)
    )
    SELECT * FROM MainResult
    ORDER BY [ClaimDate] DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ------------------------------------------------------
    -- Pagination Meta
    ------------------------------------------------------
    SELECT 
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM [dbo].[WarrentyDetails] war WITH (NOLOCK)
    INNER JOIN [M_code] Mc WITH (NOLOCK) ON CAST(Mc.[Code1] AS VARCHAR(20)) + '-' + CAST(Mc.[Code2] AS VARCHAR(20)) = war.[Code]    
    INNER JOIN [Pro_Reg] pr WITH (NOLOCK) ON pr.[Pro_ID] = Mc.[Pro_ID]    
    WHERE pr.[Comp_ID] = @Comp_Id  and  IsWarrantyClaimed is not null
      AND (@StartDate IS NULL OR war.claimdate >= @StartDate)
      AND (@EndDate IS NULL OR war.claimdate <= @EndDate)
      AND (@SearchParam IS NULL OR war.Mobile LIKE @SearchParam OR war.BillNo LIKE @SearchParam OR war.SerialNo LIKE @SearchParam)
      AND (@ClaimStatusFilter IS NULL OR CAST(war.[IsWarrantyClaimed] AS VARCHAR(10)) = @ClaimStatusFilter);
END
