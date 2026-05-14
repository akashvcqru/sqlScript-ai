-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-14
-- Description: Get Admin Company Service Report with nested services as JSON
-- =============================================
IF OBJECT_ID('USP_GetAdminCompanyServiceReport_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetAdminCompanyServiceReport_AI
GO

CREATE PROCEDURE USP_GetAdminCompanyServiceReport_AI
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @Search NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH CompanySummary AS (
        SELECT TOP 1000
            CR.Comp_ID,
            CR.Comp_Name,
            (
                SELECT 
                    MS.Service_ID,
                    SR.ServiceName,
                    ISNULL(FORMAT(MS.DateFrom, 'dd-MM-yyyy'), 'NA') AS StartDate,
                    ISNULL(FORMAT(MS.DateTo, 'dd-MM-yyyy'), 'NA') AS EndDate,
                    CASE WHEN MS.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS [Status]
                FROM M_ServiceSubscription MS
                INNER JOIN M_Service SR ON MS.Service_ID = SR.Service_ID
                WHERE MS.Comp_ID = CR.Comp_ID
                FOR JSON PATH
            ) AS ServicesJson,
            CASE
                WHEN BS.Comp_ID IS NOT NULL THEN 'APP SOLUTION'
                ELSE 'LANDING PAGE'
            END AS DELIVERED_SOLUTION,
            CR.Comp_Email,
            CR.Password,
            CR.Reg_Date,
            CASE
                WHEN CR.Status = 0 THEN 'Inactive'
                ELSE 'Active'
            END AS COMPANY_STATUS,
            CASE
                WHEN EXISTS(SELECT 1 FROM M_ServiceSubscription WHERE Comp_ID = CR.Comp_ID AND IsActive = 1) THEN 'Service Active'
                ELSE 'Service Deactivate'
            END AS SERVICE_STATUS
        FROM Comp_Reg CR
        LEFT JOIN BrandSettings BS ON CR.Comp_ID = BS.Comp_ID
        WHERE EXISTS (SELECT 1 FROM M_ServiceSubscription WHERE Comp_ID = CR.Comp_ID)
          AND (@Search IS NULL OR CR.Comp_Name LIKE '%' + @Search + '%' OR CR.Comp_Email LIKE '%' + @Search + '%')
    )
    SELECT *, COUNT(*) OVER() AS TotalRecords
    FROM CompanySummary
    ORDER BY Reg_Date DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
