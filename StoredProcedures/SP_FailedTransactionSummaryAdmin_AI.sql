USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_FailedTransactionSummaryAdmin_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-09-02
-- Description: Retrieves failed transaction summary report for Admin with company info, wallet balances, pagination, presets, and search.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_FailedTransactionSummaryAdmin_AI]
    @CompId       NVARCHAR(50) = NULL,
    @Search       NVARCHAR(100) = NULL,
    @DatePreset   NVARCHAR(50) = NULL,
    @FromDate     DATETIME = NULL,
    @ToDate       DATETIME = NULL,
    @Offset       INT = 0,
    @Limit        INT = 10,
    @IsExport     BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Explicit Date Range overrides DatePreset
    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        IF @DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> ''
        BEGIN
            SET @DatePreset = UPPER(LTRIM(RTRIM(@DatePreset)));
            
            IF @DatePreset = 'TODAY'
            BEGIN
                SET @StartDate = CAST(GETDATE() AS DATE);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset IN ('LASTDAY', 'YESTERDAY')
            BEGIN
                SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
                SET @EndDate   = CAST(GETDATE() AS DATE);
            END
            ELSE IF @DatePreset = 'WEEK'
            BEGIN
                SET DATEFIRST 1;
                SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTWEEK'
            BEGIN
                SET DATEFIRST 1;
                SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'MONTH'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTMONTH'
            BEGIN
                SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'QUARTER'
            BEGIN
                SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
                SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            END
            ELSE IF @DatePreset = 'YEAR'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset = 'LASTYEAR'
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
                SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
            END
            ELSE IF @DatePreset IN ('ALL', 'NULL')
            BEGIN
                SET @StartDate = NULL;
                SET @EndDate   = NULL;
            END
        END
    END

    -- Total count query (only executed when not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM tblUPITransactionDetails u WITH (NOLOCK)
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = u.Comp_Id
        WHERE (
            ISNULL(u.Status, '') NOT IN ('Success', 'Cancelled', 'CANCELLED')
            OR (
                u.OrderId LIKE 'TXN[2][0][2-9][0-9]%'
                AND LEN(u.OrderId) = 17
            )
        )
          AND ISNULL(u.Status, '') NOT IN ('Cancelled', 'CANCELLED')
          AND ISNULL(u.FinalStatus, '') NOT IN ('Cancelled', 'CANCELLED')
          AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
          AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
          AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
          AND (
              @Search IS NULL OR @Search = ''
              OR u.MobileNo LIKE '%' + @Search + '%'
              OR u.ConsumerName LIKE '%' + @Search + '%'
              OR u.Code1 LIKE '%' + @Search + '%'
              OR u.Code2 LIKE '%' + @Search + '%'
              OR u.Comp_Id LIKE '%' + @Search + '%'
              OR c.Comp_Name LIKE '%' + @Search + '%'
              OR u.UPI_Id LIKE '%' + @Search + '%'
              OR u.account_no LIKE '%' + @Search + '%'
              OR u.ifsc_code LIKE '%' + @Search + '%'
              OR u.Remarks LIKE '%' + @Search + '%'
              OR u.FinalRemarks LIKE '%' + @Search + '%'
              OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
          );
    END

    -- Data result set
    SELECT 
        u.Id,
        u.Comp_Id,
        ISNULL(c.Comp_Name, u.Comp_Id) AS Comp_Name,
        u.MobileNo,
        u.ConsumerName,
        u.Code1,
        u.Code2,
        u.Amount,
        u.Status,
        u.Remarks,
        u.FinalStatus,
        u.FinalRemarks,
        u.ReqDate,
        u.ifsc_code,
        u.account_no,
        ISNULL(u.UPI_Id, u.account_no) AS [UPI/AC],
        u.UPI_Id,
        w.Service_ID,
        w.OldBal,
        w.NewBal,
        w.Amount AS WalletAmount
    FROM tblUPITransactionDetails u WITH (NOLOCK)
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = u.Comp_Id
    OUTER APPLY (
        SELECT TOP 1 
            w.Service_ID,
            w.OldBal,
            w.NewBal,
            w.Amount
        FROM tblCashWalletBalance w WITH (NOLOCK)
        WHERE w.PayrefId = u.Id
        ORDER BY w.Id DESC
    ) w
    WHERE (
        ISNULL(u.Status, '') NOT IN ('Success', 'Cancelled', 'CANCELLED')
        OR (
            u.OrderId LIKE 'TXN[2][0][2-9][0-9]%'
            AND LEN(u.OrderId) = 17
        )
    )
      AND ISNULL(u.Status, '') NOT IN ('Cancelled', 'CANCELLED')
      AND ISNULL(u.FinalStatus, '') NOT IN ('Cancelled', 'CANCELLED')
      AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
      AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
      AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
      AND (
          @Search IS NULL OR @Search = ''
          OR u.MobileNo LIKE '%' + @Search + '%'
          OR u.ConsumerName LIKE '%' + @Search + '%'
          OR u.Code1 LIKE '%' + @Search + '%'
          OR u.Code2 LIKE '%' + @Search + '%'
          OR u.Comp_Id LIKE '%' + @Search + '%'
          OR c.Comp_Name LIKE '%' + @Search + '%'
          OR u.UPI_Id LIKE '%' + @Search + '%'
          OR u.account_no LIKE '%' + @Search + '%'
          OR u.ifsc_code LIKE '%' + @Search + '%'
          OR u.Remarks LIKE '%' + @Search + '%'
          OR u.FinalRemarks LIKE '%' + @Search + '%'
          OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
      )
    ORDER BY u.ReqDate DESC, u.Id DESC
    OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY;
END
GO
