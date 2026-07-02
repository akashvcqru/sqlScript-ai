USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-07-02
-- Description: Retrieves duplicate UPI/Payout transactions from tblUPITransactionDetails for all companies or filtered by company.
-- =============================================
ALTER PROCEDURE [dbo].[USP_GetDuplicateTransaction_Admin_AI]
(
      @Compid           NVARCHAR(50) = NULL,   -- Optional company filter
      @FromDate         DATE = NULL,
      @ToDate           DATE = NULL,
      @datePreset       NVARCHAR(20) = NULL,
      @MobileNo         NVARCHAR(20) = NULL,   -- Search parameter (sub-search on mobile number)
      @DuplicateType    NVARCHAR(20) = 'CODE', -- 'CODE' or 'TIME'
      @Page             INT = 1,
      @Limit            INT = 10,
      @IsExport         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #TempDuplicates;
    DROP TABLE IF EXISTS #FinalData;

    CREATE TABLE #TempDuplicates (
        Id BIGINT NOT NULL,
        DupCount INT NOT NULL,
        DupReason NVARCHAR(100) NOT NULL
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

    -- 2. Fetch duplicate IDs
    IF UPPER(@DuplicateType) = 'CODE'
    BEGIN
        -- Find duplicate scratch codes (Code1 + Code2)
        WITH DuplicateCodes AS (
            SELECT Code1, Code2, Comp_Id, COUNT(*) AS DupCount
            FROM tblUPITransactionDetails WITH (NOLOCK)
            WHERE ReqDate >= @StartDate
              AND ReqDate < @EndDate
              AND (@Compid IS NULL OR Comp_Id = @Compid)
              AND (@MobileNo IS NULL OR MobileNo LIKE '%' + @MobileNo + '%')
              AND Code1 IS NOT NULL AND Code1 <> ''
              AND Code2 IS NOT NULL AND Code2 <> ''
              AND Status IN ('Success', 'Pending')
            GROUP BY Code1, Code2, Comp_Id
            HAVING COUNT(*) > 1
        )
        INSERT INTO #TempDuplicates (Id, DupCount, DupReason)
        SELECT t.Id, dc.DupCount, 'Duplicate Scratch Code' AS DupReason
        FROM tblUPITransactionDetails t WITH (NOLOCK)
        INNER JOIN DuplicateCodes dc 
            ON t.Code1 = dc.Code1 
            AND t.Code2 = dc.Code2 
            AND t.Comp_Id = dc.Comp_Id;
    END
    ELSE
    BEGIN
        -- Find rapid payouts (same mobile + amount in 5 minutes time window)
        WITH RapidPayouts AS (
            SELECT t1.Id
            FROM tblUPITransactionDetails t1 WITH (NOLOCK)
            INNER JOIN tblUPITransactionDetails t2 WITH (NOLOCK)
                ON t1.Comp_Id = t2.Comp_Id 
                AND t1.MobileNo = t2.MobileNo 
                AND t1.Amount = t2.Amount
                AND t1.Id <> t2.Id
                AND ABS(DATEDIFF(MINUTE, t1.ReqDate, t2.ReqDate)) <= 5
            WHERE t1.Status IN ('Success', 'Pending')
              AND t2.Status IN ('Success', 'Pending')
              AND t1.ReqDate >= @StartDate
              AND t1.ReqDate < @EndDate
              AND (@Compid IS NULL OR t1.Comp_Id = @Compid)
              AND (@MobileNo IS NULL OR t1.MobileNo LIKE '%' + @MobileNo + '%')
        )
        INSERT INTO #TempDuplicates (Id, DupCount, DupReason)
        SELECT DISTINCT Id, 2 AS DupCount, 'Rapid Payout Duplication' AS DupReason
        FROM RapidPayouts;
    END

    -- 3. Gather full details including company name & consumer name
    SELECT
        ISNULL(c.Comp_Name, 'Unknown') AS CompName,
        p.Id AS TransId,
        p.OrderId,
        p.RefenceId AS ReferenceId,
        p.ConsumerName,
        p.MobileNo,
        p.Code1,
        p.Code2,
        COALESCE(p.UPI_Id, p.account_no) AS [UPI_Id/AC],
        p.ifsc_code,
        p.account_no,
        p.benef_name,
        p.Amount AS Amount,
        p.Amount - ISNULL(p.tdsAmount, 0) AS FinalPayment,
        p.tdsAmount,
        p.tdsper,
        p.Status AS BankStatus,
        p.Remarks AS BankRemark,
        p.ReqDate,
        CONVERT(VARCHAR(20), p.ReqDate, 120) AS ReqDate_str,
        p.Remarks AS FinalStatus,
        p.FinalRemarks AS FinalRemark,
        td.DupReason AS DuplicateReason,
        td.DupCount AS DuplicateCount
    INTO #FinalData
    FROM tblUPITransactionDetails p WITH (NOLOCK)
    INNER JOIN #TempDuplicates td ON p.Id = td.Id
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = p.Comp_Id
    ORDER BY p.ReqDate DESC;

    -- 4. Paged Output & Metadata
    DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM #FinalData);

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #FinalData;
    END
    ELSE
    BEGIN
        DECLARE @Offset INT = (@Page - 1) * @Limit;

        SELECT * FROM #FinalData
        ORDER BY ReqDate DESC
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
