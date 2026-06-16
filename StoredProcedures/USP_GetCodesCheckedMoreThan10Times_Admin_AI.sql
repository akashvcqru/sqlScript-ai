USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-06-04
-- Description: Retrieves products and scan details for codes checked more than 10 times across all companies (Admin view).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodesCheckedMoreThan10Times_Admin_AI]
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Explicit date range wins
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE IF (@datePreset IS NOT NULL AND LTRIM(RTRIM(@datePreset)) <> '' AND LOWER(LTRIM(RTRIM(@datePreset))) <> 'null')
    BEGIN
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

        IF (@datePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'YESTERDAY' OR @datePreset = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@datePreset = 'WEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'MONTH')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'QUARTER')
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
    END

    SELECT 
        (pe.Received_Code1 + pe.Received_Code2) AS UniqueCode,
        pr.Pro_Name AS ProductName,
        pr.Pro_ID AS ProductID,
        pe.Comp_ID AS CompId,
        c.Comp_Name AS CompanyName,
        COUNT(pe.Enq_Date) AS CodeCheckCount,
        MAX(pe.Enq_Date) AS LastCodeCheckTime,
        pr.Pro_Entry_Date AS ProRegDate
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN Comp_Reg c WITH (NOLOCK) ON pe.Comp_ID = c.Comp_ID
    LEFT JOIN M_Code mc WITH (NOLOCK) ON mc.Code1 = TRY_CAST(pe.Received_Code1 AS NUMERIC(5,0)) AND mc.Code2 = TRY_CAST(pe.Received_Code2 AS NUMERIC(8,0))
    LEFT JOIN M_Code_PFL mcp WITH (NOLOCK) ON mcp.Code1 = TRY_CAST(pe.Received_Code1 AS NUMERIC(5,0)) AND mcp.Code2 = TRY_CAST(pe.Received_Code2 AS NUMERIC(8,0))
    LEFT JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = COALESCE(mc.Pro_ID, mcp.Pro_ID)
    WHERE (@StartDate IS NULL OR pe.Enq_Date >= @StartDate)
      AND (@EndDate IS NULL OR pe.Enq_Date < @EndDate)
    GROUP BY pr.Pro_ID, pr.Pro_Name, pr.Pro_Entry_Date, pe.Received_Code1, pe.Received_Code2, pe.Comp_ID, c.Comp_Name
    HAVING COUNT(pe.Enq_Date) > 10
    ORDER BY LastCodeCheckTime DESC;
END
GO
