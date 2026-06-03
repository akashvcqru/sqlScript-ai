-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-14
-- Description: Get Admin Company Service Report with advanced filters and nested JSON
-- =============================================
IF OBJECT_ID('USP_GetAdminCompanyServiceReport_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetAdminCompanyServiceReport_AI
GO

CREATE PROCEDURE USP_GetAdminCompanyServiceReport_AI
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @Search NVARCHAR(100) = NULL,
    @DatePreset NVARCHAR(50) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @CompanyStatus NVARCHAR(50) = NULL, -- 'Active' or 'Inactive'
    @ServiceStatus NVARCHAR(50) = NULL, -- 'Active' or 'Inactive'
    @ServiceId NVARCHAR(50) = NULL,
    @ServiceName NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate DATETIME = NULL;

    -- Normalize datePreset
    IF (@DatePreset IS NOT NULL AND LTRIM(RTRIM(@DatePreset)) <> '' AND LOWER(@DatePreset) <> 'null')
        SET @DatePreset = UPPER(LTRIM(RTRIM(@DatePreset)));
    ELSE
        SET @DatePreset = NULL;

    -- Handle Date Preset (Matching Manage BL Report logic)
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate = @ToDate;
    END
    ELSE IF @DatePreset IS NOT NULL
    BEGIN
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF @DatePreset = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'LASTDAY' OR @DatePreset = 'YESTERDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            SET @EndDate = CAST(DATEADD(SECOND, -1, CAST(@Today AS DATETIME)) AS DATETIME);
        END
        ELSE IF @DatePreset = 'WEEK'
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'LASTWEEK'
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
            SET @EndDate = CAST(DATEADD(SECOND, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today), 0)) AS DATETIME);
        END
        ELSE IF @DatePreset = 'MONTH'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'LASTMONTH'
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
            SET @EndDate = CAST(DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0)) AS DATETIME);
        END
        ELSE IF @DatePreset = 'QUARTER'
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Today) - 1, 0);
            SET @EndDate = CAST(DATEADD(SECOND, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Today), 0)) AS DATETIME);
        END
        ELSE IF @DatePreset = 'YEAR'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF @DatePreset = 'LASTYEAR'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(@Today) - 1, 12, 31);
        END
    END
    ELSE
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate = @ToDate;
    END

    ;WITH CompanySummary AS (
        SELECT TOP 1000
            CR.Comp_ID AS CompId,
            CR.Comp_Name AS CompName,
            (
                SELECT 
                    MS.Service_ID AS ServiceId,
                    SR.ServiceName,
                    MS.DateFrom AS StartDate,
                    MS.DateTo AS EndDate,
                    CASE WHEN MS.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS [Status]
                FROM M_ServiceSubscription MS
                INNER JOIN M_Service SR ON MS.Service_ID = SR.Service_ID
                WHERE MS.Comp_ID = CR.Comp_ID
                  AND (@ServiceStatus IS NULL OR (CASE WHEN MS.IsActive = 1 THEN 'Active' ELSE 'Inactive' END = @ServiceStatus))
                  AND (@ServiceId IS NULL OR MS.Service_ID = @ServiceId)
                  AND (@ServiceName IS NULL OR SR.ServiceName LIKE '%' + @ServiceName + '%')
                FOR JSON PATH
            ) AS ServicesJson,
            CASE
                WHEN BS.Comp_ID IS NOT NULL THEN 'APP SOLUTION'
                ELSE 'LANDING PAGE'
            END AS DeliveredSolution,
            CR.Comp_Email AS CompEmail,
            CR.Password,
            CR.Reg_Date AS RegDate,
            CASE
                WHEN CR.Status = 0 THEN 'Inactive'
                ELSE 'Active'
            END AS CompanyStatus,
            CASE
                WHEN EXISTS(SELECT 1 FROM M_ServiceSubscription WHERE Comp_ID = CR.Comp_ID AND IsActive = 1) THEN 'Service Active'
                ELSE 'Service Deactivate'
            END AS ServiceStatus
        FROM Comp_Reg CR
        LEFT JOIN BrandSettings BS ON CR.Comp_ID = BS.Comp_ID
        WHERE 1=1
          AND (@Search IS NULL OR CR.Comp_Name LIKE '%' + @Search + '%' OR CR.Comp_Email LIKE '%' + @Search + '%')
          AND (@StartDate IS NULL OR CR.Reg_Date >= @StartDate)
          AND (@EndDate IS NULL OR CR.Reg_Date <= @EndDate)
          AND (@CompanyStatus IS NULL OR (CASE WHEN CR.Status = 0 THEN 'Inactive' ELSE 'Active' END = @CompanyStatus))
          AND EXISTS (
              SELECT 1 FROM M_ServiceSubscription MS2 
              INNER JOIN M_Service SR2 ON MS2.Service_ID = SR2.Service_ID
              WHERE MS2.Comp_ID = CR.Comp_ID 
                AND (@ServiceStatus IS NULL OR (CASE WHEN MS2.IsActive = 1 THEN 'Active' ELSE 'Inactive' END = @ServiceStatus))
                AND (@ServiceId IS NULL OR MS2.Service_ID = @ServiceId)
                AND (@ServiceName IS NULL OR SR2.ServiceName LIKE '%' + @ServiceName + '%')
          )
    )
    SELECT *, COUNT(*) OVER() AS TotalRecords
    FROM CompanySummary
    ORDER BY RegDate DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
