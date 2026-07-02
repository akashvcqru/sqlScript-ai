USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-07-02
-- Description: Retrieves duplicate UPI/Payout transactions from tblUPITransactionDetails based on grouping criteria.
-- =============================================
ALTER PROCEDURE [dbo].[USP_GetDuplicateTransaction_Admin_AI]
(
      @Compid           NVARCHAR(50) = NULL,   -- Optional company filter
      @FromDate         DATE = NULL,
      @ToDate           DATE = NULL,
      @datePreset       NVARCHAR(20) = NULL,
      @MobileNo         NVARCHAR(20) = NULL,   -- Search parameter (sub-search on mobile number)
      @DuplicateType    NVARCHAR(20) = 'CODE', -- 'CODE', 'CLAIM' or 'TIME'
      @Page             INT = 1,
      @Limit            INT = 10,
      @IsExport         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #FinalData;

    -- Pre-declare temporary table to prevent parser error due to SELECT INTO in multiple branches
    CREATE TABLE #FinalData (
        MobileNo VARCHAR(15) NULL,
        Code1 VARCHAR(200) NULL, -- Increased length for string aggregations in TIME checks
        Code2 VARCHAR(200) NULL,
        ActualAmount DECIMAL(18, 2) NOT NULL,
        ExtraPayCount INT NOT NULL,
        ExtraPayAmount DECIMAL(18, 2) NOT NULL,
        TotalTransactions INT NOT NULL,
        SuccessCount INT NOT NULL,
        PendingCount INT NOT NULL,
        FailedCount INT NOT NULL,
        TotalPaidAmount DECIMAL(18, 2) NOT NULL,
        TxnIds VARCHAR(MAX) NULL,
        IFSCCode VARCHAR(50) NULL,
        AccountNo VARCHAR(50) NULL,
        BeneficiaryName NVARCHAR(100) NULL,
        Comp_Id VARCHAR(50) NULL,
        CompName NVARCHAR(150) NULL
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
    IF UPPER(@DuplicateType) = 'TIME'
    BEGIN
        -- Group by MobileNo and Amount (Rapid payout checks)
        INSERT INTO #FinalData (MobileNo, Code1, Code2, ActualAmount, ExtraPayCount, ExtraPayAmount, TotalTransactions, SuccessCount, PendingCount, FailedCount, TotalPaidAmount, TxnIds, IFSCCode, AccountNo, BeneficiaryName, Comp_Id, CompName)
        SELECT
            p.MobileNo,
            STRING_AGG(p.Code1, ', ') AS Code1,
            STRING_AGG(p.Code2, ', ') AS Code2,
            p.Amount AS ActualAmount,
            CASE
                WHEN SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) > 0
                THEN SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) - 1
                ELSE 0
            END AS ExtraPayCount,
            CASE
                WHEN SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) > 0
                THEN p.Amount * (SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) - 1)
                ELSE 0
            END AS ExtraPayAmount,
            COUNT(*) AS TotalTransactions,
            SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) AS SuccessCount,
            SUM(CASE WHEN p.Status = 'Pending' THEN 1 ELSE 0 END) AS PendingCount,
            SUM(CASE WHEN p.Status = 'Failed' THEN 1 ELSE 0 END) AS FailedCount,
            p.Amount * SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) AS TotalPaidAmount,
            STRING_AGG(CAST(p.Id AS VARCHAR(20)), ', ') AS TxnIds,
            MAX(p.ifsc_code) AS IFSCCode,
            MAX(p.account_no) AS AccountNo,
            MAX(p.benef_name) AS BeneficiaryName,
            MAX(p.Comp_Id) AS Comp_Id,
            ISNULL(MAX(c.Comp_Name), 'Unknown') AS CompName
        FROM tblUPITransactionDetails p WITH (NOLOCK)
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = p.Comp_Id
        WHERE p.ReqDate >= @StartDate
          AND p.ReqDate < @EndDate
          AND (@Compid IS NULL OR p.Comp_Id = @Compid)
          AND (@MobileNo IS NULL OR p.MobileNo LIKE '%' + @MobileNo + '%')
          AND p.Status = 'Success'
        GROUP BY
            p.MobileNo,
            p.Amount
        HAVING COUNT(*) > 1;
    END
    ELSE
    BEGIN
        -- Default: CLAIM / CODE duplication (Group by MobileNo, Amount, Code1, Code2)
        INSERT INTO #FinalData (MobileNo, Code1, Code2, ActualAmount, ExtraPayCount, ExtraPayAmount, TotalTransactions, SuccessCount, PendingCount, FailedCount, TotalPaidAmount, TxnIds, IFSCCode, AccountNo, BeneficiaryName, Comp_Id, CompName)
        SELECT
            p.MobileNo,
            p.Code1,
            p.Code2,
            p.Amount AS ActualAmount,
            CASE
                WHEN SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) > 0
                THEN SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) - 1
                ELSE 0
            END AS ExtraPayCount,
            CASE
                WHEN SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) > 0
                THEN p.Amount * (SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) - 1)
                ELSE 0
            END AS ExtraPayAmount,
            COUNT(*) AS TotalTransactions,
            SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) AS SuccessCount,
            SUM(CASE WHEN p.Status = 'Pending' THEN 1 ELSE 0 END) AS PendingCount,
            SUM(CASE WHEN p.Status = 'Failed' THEN 1 ELSE 0 END) AS FailedCount,
            p.Amount * SUM(CASE WHEN p.Status = 'Success' THEN 1 ELSE 0 END) AS TotalPaidAmount,
            STRING_AGG(CAST(p.Id AS VARCHAR(20)), ', ') AS TxnIds,
            MAX(p.ifsc_code) AS IFSCCode,
            MAX(p.account_no) AS AccountNo,
            MAX(p.benef_name) AS BeneficiaryName,
            MAX(p.Comp_Id) AS Comp_Id,
            ISNULL(MAX(c.Comp_Name), 'Unknown') AS CompName
        FROM tblUPITransactionDetails p WITH (NOLOCK)
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = p.Comp_Id
        WHERE p.ReqDate >= @StartDate
          AND p.ReqDate < @EndDate
          AND (@Compid IS NULL OR p.Comp_Id = @Compid)
          AND (@MobileNo IS NULL OR p.MobileNo LIKE '%' + @MobileNo + '%')
          AND p.Status = 'Success'
        GROUP BY
            p.MobileNo,
            p.Amount,
            p.Code1,
            p.Code2
        HAVING COUNT(*) > 1;
    END

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
