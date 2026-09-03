USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetFailedTransactionSummaryAdmin_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================
-- Author:      Antigravity
-- Create date: 2026-09-03
-- Description: Retrieves failed transaction summary report for Admin
--              directly and exclusively from tblUPITransactionDetails.
--              No external table lookups or deductions; only failed records.
-- ====================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetFailedTransactionSummaryAdmin_AI]
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

    -- 1. Total count query (only when not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM tblUPITransactionDetails u WITH (NOLOCK)
        WHERE u.Status = 'Failed'
          AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
          AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
          AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
          AND (
              @Search IS NULL OR @Search = ''
              OR u.OrderId LIKE '%' + @Search + '%'
              OR u.MobileNo LIKE '%' + @Search + '%'
              OR u.ConsumerName LIKE '%' + @Search + '%'
              OR u.Code1 LIKE '%' + @Search + '%'
              OR u.Code2 LIKE '%' + @Search + '%'
              OR (u.Code1 + u.Code2) LIKE '%' + @Search + '%'
              OR u.Comp_Id LIKE '%' + @Search + '%'
              OR u.UPI_Id LIKE '%' + @Search + '%'
              OR u.account_no LIKE '%' + @Search + '%'
              OR u.ifsc_code LIKE '%' + @Search + '%'
              OR u.Remarks LIKE '%' + @Search + '%'
              OR u.FinalRemarks LIKE '%' + @Search + '%'
              OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
              OR EXISTS (SELECT 1 FROM Comp_Reg cr WITH (NOLOCK) WHERE cr.Comp_ID = u.Comp_Id AND cr.Comp_Name LIKE '%' + @Search + '%')
          );
    END

    -- 2. Data result set
    IF @IsExport = 1
    BEGIN
        SELECT 
            u.Id,
            u.OrderId,
            u.Comp_Id,
            ISNULL(c.Comp_Name, u.Comp_Id) AS CompanyName,
            u.MobileNo,
            u.ConsumerName,
            CASE 
                WHEN ISNULL(u.Code1, '') <> '' AND ISNULL(u.Code2, '') <> '' AND u.Code1 <> '0' AND u.Code2 <> '0'
                THEN u.Code1 + u.Code2
                ELSE ISNULL(NULLIF(u.Code1, '0'), ISNULL(NULLIF(u.Code2, '0'), ''))
            END AS CompleteCode,
            u.Amount,
            u.Status,
            u.Remarks,
            u.FinalStatus,
            u.FinalRemarks,
            u.ReqDate,
            u.ifsc_code AS IfscCode,
            CASE 
                WHEN ISNULL(LTRIM(RTRIM(u.account_no)), '') <> '' THEN u.account_no
                ELSE NULLIF(LTRIM(RTRIM(u.UPI_Id)), '')
            END AS AccountNo,
            ISNULL(NULLIF(LTRIM(RTRIM(u.UPI_Id)), ''), u.account_no) AS [UPI/AC]
        FROM tblUPITransactionDetails u WITH (NOLOCK)
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = u.Comp_Id
        WHERE u.Status = 'Failed'
          AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
          AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
          AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
          AND (
              @Search IS NULL OR @Search = ''
              OR u.OrderId LIKE '%' + @Search + '%'
              OR u.MobileNo LIKE '%' + @Search + '%'
              OR u.ConsumerName LIKE '%' + @Search + '%'
              OR u.Code1 LIKE '%' + @Search + '%'
              OR u.Code2 LIKE '%' + @Search + '%'
              OR (u.Code1 + u.Code2) LIKE '%' + @Search + '%'
              OR u.Comp_Id LIKE '%' + @Search + '%'
              OR u.UPI_Id LIKE '%' + @Search + '%'
              OR u.account_no LIKE '%' + @Search + '%'
              OR u.ifsc_code LIKE '%' + @Search + '%'
              OR u.Remarks LIKE '%' + @Search + '%'
              OR u.FinalRemarks LIKE '%' + @Search + '%'
              OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
              OR EXISTS (SELECT 1 FROM Comp_Reg cr WITH (NOLOCK) WHERE cr.Comp_ID = u.Comp_Id AND cr.Comp_Name LIKE '%' + @Search + '%')
          )
        ORDER BY u.ReqDate DESC, u.Id DESC;
    END
    ELSE
    BEGIN
        SELECT 
            u.Id,
            u.OrderId,
            u.Comp_Id,
            ISNULL(c.Comp_Name, u.Comp_Id) AS CompanyName,
            u.MobileNo,
            u.ConsumerName,
            CASE 
                WHEN ISNULL(u.Code1, '') <> '' AND ISNULL(u.Code2, '') <> '' AND u.Code1 <> '0' AND u.Code2 <> '0'
                THEN u.Code1 + u.Code2
                ELSE ISNULL(NULLIF(u.Code1, '0'), ISNULL(NULLIF(u.Code2, '0'), ''))
            END AS CompleteCode,
            u.Amount,
            u.Status,
            u.Remarks,
            u.FinalStatus,
            u.FinalRemarks,
            u.ReqDate,
            u.ifsc_code AS IfscCode,
            CASE 
                WHEN ISNULL(LTRIM(RTRIM(u.account_no)), '') <> '' THEN u.account_no
                ELSE NULLIF(LTRIM(RTRIM(u.UPI_Id)), '')
            END AS AccountNo,
            ISNULL(NULLIF(LTRIM(RTRIM(u.UPI_Id)), ''), u.account_no) AS [UPI/AC]
        FROM tblUPITransactionDetails u WITH (NOLOCK)
        LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = u.Comp_Id
        WHERE u.Status = 'Failed'
          AND (@CompId IS NULL OR @CompId = '' OR @CompId = 'ALL' OR u.Comp_Id = @CompId)
          AND (@StartDate IS NULL OR u.ReqDate >= @StartDate)
          AND (@EndDate IS NULL OR u.ReqDate < @EndDate)
          AND (
              @Search IS NULL OR @Search = ''
              OR u.OrderId LIKE '%' + @Search + '%'
              OR u.MobileNo LIKE '%' + @Search + '%'
              OR u.ConsumerName LIKE '%' + @Search + '%'
              OR u.Code1 LIKE '%' + @Search + '%'
              OR u.Code2 LIKE '%' + @Search + '%'
              OR (u.Code1 + u.Code2) LIKE '%' + @Search + '%'
              OR u.Comp_Id LIKE '%' + @Search + '%'
              OR u.UPI_Id LIKE '%' + @Search + '%'
              OR u.account_no LIKE '%' + @Search + '%'
              OR u.ifsc_code LIKE '%' + @Search + '%'
              OR u.Remarks LIKE '%' + @Search + '%'
              OR u.FinalRemarks LIKE '%' + @Search + '%'
              OR CAST(u.Id AS VARCHAR(20)) LIKE '%' + @Search + '%'
              OR EXISTS (SELECT 1 FROM Comp_Reg cr WITH (NOLOCK) WHERE cr.Comp_ID = u.Comp_Id AND cr.Comp_Name LIKE '%' + @Search + '%')
          )
        ORDER BY u.ReqDate DESC, u.Id DESC
        OFFSET @Offset ROWS
        FETCH NEXT @Limit ROWS ONLY;
    END
END
GO
