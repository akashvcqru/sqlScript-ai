SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure: USP_GetServiceSettingMasterCodeTrackAndTraceList_AI
-- Description: Fetch list of service settings for Track & Trace (No MasterCode)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetServiceSettingMasterCodeTrackAndTraceList_AI]
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
            WHEN SST.IsActive = 1 THEN 'Activated' 
            ELSE 'De-Activated' 
        END AS StatusText,
        SST.IsDelete,
        (SELECT STRING_AGG(CAST(m.Pro_ID AS VARCHAR(MAX)) + '-' + FORMAT(m.Series_Order, '000') + '-' + FORMAT(m.Series_Serial, '0000'), ', ') 
         FROM M_Code m 
         INNER JOIN T_Pro TP ON m.Pro_ID = TP.Pro_ID AND m.Batch_No = CAST(TP.Row_ID AS VARCHAR(50))
         WHERE TP.Pro_ID = CT.Pro_ID AND TP.Batch_No = CT.Batch_No
        ) AS MasterCode,
        CT.Batch_No,
        CT.Dealer_Name,
        CT.Dealer_Location,
        CT.Mobile,
        CT.Email,
        CT.Invoice_Number,
        CT.BatchSize,
        CT.ID AS TrackTrace_ID,
        CT.SeriesStart,
        CT.SeriesEnd,
        COUNT(*) OVER() as TotalRecords
    FROM M_ServiceSubscriptionTrans SST
    INNER JOIN M_ServiceSubscription SS ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    LEFT JOIN M_ServiceSubscriptionTracTrace_MasterCodeLess CT ON SST.SST_Id = CT.SST_Id
    WHERE SS.Comp_ID = @Comp_ID
      AND SS.Service_ID = 'SRV1021' -- Track & Trace
    ORDER BY SST.Entry_Date DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
