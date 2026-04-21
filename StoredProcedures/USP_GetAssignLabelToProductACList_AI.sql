IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[USP_GetAssignLabelToProductACList_AI]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[USP_GetAssignLabelToProductACList_AI]
GO

CREATE PROCEDURE [dbo].[USP_GetAssignLabelToProductACList_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_Name NVARCHAR(MAX) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageIndex INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate total records count
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*)
    FROM (
        SELECT ss.Comp_ID, ss.Service_ID, p.Pro_Name, sst.Entry_Date, sst.IsDelete
        FROM M_ServiceSubscription AS ss
        INNER JOIN M_ServiceSubscriptionTrans AS sst ON ss.Subscribe_Id = sst.Subscribe_Id 
        INNER JOIN Pro_Reg AS p ON ss.Pro_ID = p.Pro_ID
        WHERE (ss.Comp_ID = @Comp_ID) 
          AND (ss.Service_ID = 'SRV1018') 
          AND (@Pro_Name IS NULL OR p.Pro_Name LIKE '%' + @Pro_Name + '%')
          AND (@FromDate IS NULL OR sst.Entry_Date >= @FromDate)
          AND (@ToDate IS NULL OR sst.Entry_Date <= @ToDate)
          AND (sst.IsDelete = 0)
    ) AS T;

    -- Fetch the list with pagination
    SELECT DISTINCT 
        REG.SST_Id AS Row_ID, 
        REG.Pro_ID, 
        REG.Points,
        REG.Frequency,
        REG.IsCashConvert,
        CONVERT(NVARCHAR, REG.DateFrom, 103) AS DateFrom,
        CONVERT(NVARCHAR, REG.DateTo, 103) AS DateTo,
        REG.Entry_Date AS Pasted_Date,
        REG.Comments,
        REG.Comp_ID,  
        REG.Pro_Name,
        REG.ServiceName,
        REG.servicerange,
        REG.PlanName,
        REG.PlanMasterPeriod,
        REG.start_order,
        REG.start_series,
        REG.end_order,
        REG.end_series,
        -- Sound Paths (derived from SST_Id)
        CASE WHEN REG.IsSound = 1 THEN '../Data/Sound/' + SUBSTRING(REG.Comp_ID, 6, 4) + '/' + REG.Pro_ID + '/Loyalty/'+ CONVERT(VARCHAR,REG.SST_Id) +'/' + CONVERT(VARCHAR,REG.SST_Id) + '_H.wav' ELSE '' END AS SoundPath_H,
        CASE WHEN REG.IsSound = 1 THEN '../Data/Sound/' + SUBSTRING(REG.Comp_ID, 6, 4) + '/' + REG.Pro_ID + '/Loyalty/'+ CONVERT(VARCHAR,REG.SST_Id) +'/' + CONVERT(VARCHAR,REG.SST_Id) + '_E.wav' ELSE '' END AS SoundPath_E,
        -- Check if the service is currently active via Date check.
        CAST(CASE WHEN (GETDATE() BETWEEN REG.DateFrom AND REG.DateTo) THEN 1 ELSE 0 END AS BIT) AS IsCounterFittingServiceActive,
        @TotalRecords AS TotalRecords
    FROM (
        SELECT 
            ss.Service_ID, 
            sst.SST_Id, 
            sst.Subscribe_Id, 
            sst.Points, 
            sst.Frequency, 
            sst.IsCashConvert, 
            sst.DateFrom, 
            sst.DateTo, 
            sst.Entry_Date, 
            sst.Comments, 
            sst.IsActive, 
            sst.IsDelete, 
            ms.ServiceName, 
            p.Pro_Name, 
            mf.IsSound,
            ss.Comp_ID,
            ss.Pro_ID, 
            ss.PlanName,
            ss.PlanMasterPeriod,
            ss.start_order,
            ss.start_series,
            ss.end_order,
            ss.end_series,
            CASE WHEN ss.start_order IS NULL THEN '' ELSE CONCAT(ss.start_order,'-',ss.start_series,',',CONCAT(ss.end_order,'-',ss.end_series)) END AS servicerange 
        FROM M_ServiceFeature mf
        INNER JOIN M_Service AS ms ON mf.Service_ID = ms.Service_ID 
        INNER JOIN M_ServiceSubscription AS ss ON ms.Service_ID = ss.Service_ID 
        INNER JOIN M_ServiceSubscriptionTrans AS sst ON ss.Subscribe_Id = sst.Subscribe_Id 
        INNER JOIN Pro_Reg AS p ON ss.Pro_ID = p.Pro_ID
    ) REG 
    WHERE (REG.Comp_ID = @Comp_ID) 
      AND (REG.Service_ID = 'SRV1018') 
      AND (@Pro_Name IS NULL OR REG.Pro_Name LIKE '%' + @Pro_Name + '%')
      AND (@FromDate IS NULL OR REG.Entry_Date >= @FromDate)
      AND (@ToDate IS NULL OR REG.Entry_Date <= @ToDate)
      AND (REG.IsDelete = 0)
    ORDER BY REG.SST_Id DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
