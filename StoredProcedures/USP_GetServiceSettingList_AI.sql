-- =============================================
-- Procedure: USP_GetServiceSettingList_AI
-- Description: Fetch list of service settings for a vendor
-- =============================================
IF OBJECT_ID('USP_GetServiceSettingList_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetServiceSettingList_AI
GO

CREATE PROCEDURE USP_GetServiceSettingList_AI
    @Comp_ID       NVARCHAR(50),
    @Pro_ID        NVARCHAR(50) = NULL,
    @Service_ID    NVARCHAR(10) = NULL,
    @Pro_Name      NVARCHAR(100) = NULL
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
        -- Sound paths (stubbed as per legacy UI expectation)
        '' AS SoundPath,
        '' AS SoundPath1
    FROM M_ServiceSubscriptionTrans SST
    INNER JOIN M_ServiceSubscription SS ON SST.Subscribe_Id = SS.Subscribe_Id
    INNER JOIN Pro_Reg P ON SS.Pro_ID = P.Pro_ID
    INNER JOIN M_Service S ON SS.Service_ID = S.Service_ID
    WHERE SS.Comp_ID = @Comp_ID
      AND (SST.IsDelete = 0 OR SST.IsDelete IS NULL)
      AND (@Pro_ID IS NULL OR SS.Pro_ID = @Pro_ID)
      AND (@Service_ID IS NULL OR SS.Service_ID = @Service_ID)
      AND (@Pro_Name IS NULL OR P.Pro_Name LIKE '%' + @Pro_Name + '%')
    ORDER BY SST.Entry_Date DESC;
END
GO
