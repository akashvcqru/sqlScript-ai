-- =============================================
-- Procedure: USP_GetCompanyAssignedServicesWise_AI
-- Description: Returns all services assigned to a company and their
--              service settings data in two result sets.
--              Result Set 1: Distinct services subscribed by the company.
--              Result Set 2: All service setting transactions for the company.
-- =============================================
IF OBJECT_ID('USP_GetCompanyAssignedServicesWise_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetCompanyAssignedServicesWise_AI
GO

CREATE PROCEDURE USP_GetCompanyAssignedServicesWise_AI
    @Comp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Distinct services assigned to this company
    SELECT
        SS.Service_ID,
        S.ServiceName,
        COUNT(DISTINCT SS.Subscribe_Id) AS TotalSubscriptions
    FROM M_ServiceSubscription SS
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    WHERE SS.Comp_ID = @Comp_ID
      AND (SS.IsDelete = 0 OR SS.IsDelete IS NULL)
    GROUP BY SS.Service_ID, S.ServiceName
    ORDER BY S.ServiceName;

    -- Result Set 2: All settings data grouped under each service for this company
    SELECT
        SST.SST_Id,
        SST.Subscribe_Id,
        P.Pro_Name,
        SS.Service_ID,
        S.ServiceName,
        CASE
            WHEN SS.start_order IS NOT NULL AND SS.start_series IS NOT NULL
                THEN CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR)
                     + ' to ' + CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR)
            ELSE 'All'
        END AS servicerange,
        SST.DateFrom,
        SST.DateTo,
        SST.Points,
        SST.IsCashConvert,
        SST.IsCash,
        SST.Frequency,
        SST.Comments,
        SST.IsActive,
        CASE WHEN SST.IsActive = 0 THEN 'Activated' ELSE 'De-Activated' END AS StatusText,
        SST.IsDelete,
        CT.mastercode,
        CT.Batch_No,
        CT.Dealer_Name,
        CT.Dealer_Location,
        CT.Mobile,
        CT.Email,
        CT.Invoice_Number,
        CT.BatchSize,
        CT.ID AS TrackTrace_ID
    FROM M_ServiceSubscriptionTrans SST
    INNER JOIN M_ServiceSubscription SS ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    LEFT JOIN codeassign_tractrac CT ON SST.SST_Id = CT.SST_Id
    WHERE SS.Comp_ID = @Comp_ID
      AND (SST.IsDelete = 0 OR SST.IsDelete IS NULL)
    ORDER BY S.ServiceName, SST.Entry_Date DESC;
END
GO
