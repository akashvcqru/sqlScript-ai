USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-07-02
-- Description: Retrieves duplicate claim records from ClaimDetails based on grouping criteria.
-- =============================================
ALTER PROCEDURE [dbo].[USP_GetDuplicateClaim_Admin_AI]
(
      @Compid           NVARCHAR(50) = NULL,   -- Optional company filter
      @FromDate         DATE = NULL,
      @ToDate           DATE = NULL,
      @datePreset       NVARCHAR(20) = NULL,
      @MobileNo         NVARCHAR(20) = NULL,   -- Search parameter (sub-search on mobile number)
      @Page             INT = 1,
      @Limit            INT = 10,
      @IsExport         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #FinalData;

    -- Pre-declare temporary table to prevent parser error due to SELECT INTO
    CREATE TABLE #FinalData (
        MobileNo VARCHAR(15) NULL,
        ActualAmount DECIMAL(18, 2) NOT NULL,
        ExtraPayCount INT NOT NULL,
        ExtraPayAmount DECIMAL(18, 2) NOT NULL,
        TotalTransactions INT NOT NULL,
        SuccessCount INT NOT NULL,
        PendingCount INT NOT NULL,
        FailedCount INT NOT NULL,
        TotalPaidAmount DECIMAL(18, 2) NOT NULL,
        Claimid VARCHAR(MAX) NULL,
        [UPIID/AC] VARCHAR(100) NULL,
        Comp_Id VARCHAR(50) NULL,
        CompName NVARCHAR(150) NULL,
        Claim_date VARCHAR(MAX) NULL
    );

    -- 1. Date window resolution
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@datePreset,''));

    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(DAY, 1, @ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            SET @EndDate   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'MONTH'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE
        BEGIN
            -- Default to last 30 days
            SET @StartDate = DATEADD(DAY, -30, @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
    END

    -- 2. Fetch duplicate entries using GROUP BY and HAVING COUNT(*) > 1
    INSERT INTO #FinalData (MobileNo, ActualAmount, ExtraPayCount, ExtraPayAmount, TotalTransactions, SuccessCount, PendingCount, FailedCount, TotalPaidAmount, Claimid, [UPIID/AC], Comp_Id, CompName, Claim_date)
    SELECT
        p.Mobileno AS MobileNo,
        p.Amount AS ActualAmount,
        CASE
            WHEN SUM(CASE WHEN p.Isapproved = 1 THEN 1 ELSE 0 END) > 0
            THEN SUM(CASE WHEN p.Isapproved = 1 THEN 1 ELSE 0 END) - 1
            ELSE 0
        END AS ExtraPayCount,
        CASE
            WHEN SUM(CASE WHEN p.Isapproved = 1 THEN 1 ELSE 0 END) > 0
            THEN p.Amount * (SUM(CASE WHEN p.Isapproved = 1 THEN 1 ELSE 0 END) - 1)
            ELSE 0
        END AS ExtraPayAmount,
        COUNT(*) AS TotalTransactions,
        SUM(CASE WHEN p.Isapproved = 1 THEN 1 ELSE 0 END) AS SuccessCount,
        SUM(CASE WHEN p.Isapproved = 0 THEN 1 ELSE 0 END) AS PendingCount,
        SUM(CASE WHEN p.Isapproved = 2 THEN 1 ELSE 0 END) AS FailedCount,
        p.Amount * SUM(CASE WHEN p.Isapproved = 1 THEN 1 ELSE 0 END) AS TotalPaidAmount,
        STRING_AGG(CAST(p.Row_id AS VARCHAR(20)), ', ') AS Claimid,
        MAX(p.UPIID) AS [UPIID/AC],
        MAX(p.Comp_id) AS Comp_Id,
        ISNULL(MAX(c.Comp_Name), 'Unknown') AS CompName,
        STRING_AGG(CONVERT(VARCHAR(20), p.Claim_date, 120), ', ') AS Claim_date
    FROM ClaimDetails p WITH (NOLOCK)
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = p.Comp_id
    WHERE p.Claim_date >= @StartDate
      AND p.Claim_date < @EndDate
      AND (@Compid IS NULL OR p.Comp_id = @Compid)
      AND (@MobileNo IS NULL OR p.Mobileno LIKE '%' + @MobileNo + '%')
    GROUP BY
        p.Mobileno,
        p.Amount
    HAVING COUNT(*) > 1;

    -- 3. Paged Output & Metadata
    DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM #FinalData);

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #FinalData
        ORDER BY ActualAmount DESC;
    END
    ELSE
    BEGIN
        DECLARE @Offset INT = (@Page - 1) * @Limit;

        SELECT * FROM #FinalData
        ORDER BY ActualAmount DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata
        SELECT 
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CAST(CEILING(CAST(@TotalRecords AS DECIMAL) / @Limit) AS INT) AS TotalPages;
    END
END
GO
