-- =============================================
-- Procedure: USP_GetServiceSettingTracTrashList_AI
-- Description: Fetch list of service settings for Track & Trace with master code details
-- =============================================
IF OBJECT_ID('USP_GetServiceSettingTracTrashList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceSettingTracTrashList_AI
GO

CREATE PROCEDURE USP_GetServiceSettingTracTrashList_AI
    @Comp_ID       NVARCHAR(50),
    @PageIndex     INT = 1,
    @PageSize      INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        SST.SST_Id,
        SST.Subscribe_Id,
        P.Pro_Name,
        S.ServiceName,
        CASE 
            WHEN SS.start_order IS NOT NULL AND SS.start_series IS NOT NULL 
            THEN CAST(SS.start_order AS VARCHAR) + '-' + CAST(SS.start_series AS VARCHAR) + ' to ' + CAST(SS.end_order AS VARCHAR) + '-' + CAST(SS.end_series AS VARCHAR)
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
        CASE 
            WHEN SST.IsActive = 0 THEN 'Activated' 
            ELSE 'De-Activated' 
        END AS StatusText,
        SST.IsDelete,
        CT.mastercode,
        CT.Batch_No,
        CT.Dealer_Name,
        CT.Dealer_Location,
        CT.Contact_Information,
        CT.Invoice_Number,
        CT.ID AS TrackTrace_ID,
        COUNT(*) OVER() as TotalRecords
    FROM M_ServiceSubscriptionTrans SST
    INNER JOIN M_ServiceSubscription SS ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    LEFT JOIN codeassign_tractrac CT ON SST.SST_Id = CT.SST_Id
    WHERE SS.Comp_ID = @Comp_ID
      AND SS.Service_ID = 'SRV1021'
    ORDER BY SST.Entry_Date DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
