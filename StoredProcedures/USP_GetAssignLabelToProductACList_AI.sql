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
        SELECT ss.Comp_ID, ss.Service_ID, p.Pro_Name, 
               ISNULL(sst.Entry_Date, ss.EntryDate) AS Entry_Date, 
               ISNULL(sst.IsDelete, ss.IsDelete) AS IsDelete
        FROM M_ServiceSubscription AS ss
        INNER JOIN Pro_Reg AS p ON ss.Pro_ID = p.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans AS sst ON ss.Subscribe_Id = sst.Subscribe_Id 
        WHERE (ss.Comp_ID = @Comp_ID) 
          AND (ss.Service_ID = 'SRV1018') 
          AND (@Pro_Name IS NULL OR p.Pro_Name LIKE '%' + @Pro_Name + '%')
          AND (@FromDate IS NULL OR ISNULL(sst.Entry_Date, ss.EntryDate) >= @FromDate)
          AND (@ToDate IS NULL OR ISNULL(sst.Entry_Date, ss.EntryDate) <= @ToDate)
          AND (ISNULL(sst.IsDelete, ss.IsDelete) = 0)
    ) AS T;

    -- Fetch the list with pagination
    SELECT DISTINCT 
        REG.Row_ID, 
        REG.Pro_ID, 
        REG.Points,
        REG.Frequency,
        REG.IsCashConvert,
        CONVERT(NVARCHAR, REG.DateFrom, 103) AS DateFrom,
        CONVERT(NVARCHAR, REG.DateTo, 103) AS DateTo,
        REG.Pasted_Date,
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
        REG.FromSeries,
        REG.ToSeries,
        -- Sound Paths (derived from Row_ID)
        CASE WHEN REG.IsSound = 1 THEN '../Data/Sound/' + SUBSTRING(REG.Comp_ID, 6, 4) + '/' + REG.Pro_ID + '/Loyalty/'+ CONVERT(VARCHAR,REG.Row_ID) +'/' + CONVERT(VARCHAR,REG.Row_ID) + '_H.wav' ELSE '' END AS SoundPath_H,
        CASE WHEN REG.IsSound = 1 THEN '../Data/Sound/' + SUBSTRING(REG.Comp_ID, 6, 4) + '/' + REG.Pro_ID + '/Loyalty/'+ CONVERT(VARCHAR,REG.Row_ID) +'/' + CONVERT(VARCHAR,REG.Row_ID) + '_E.wav' ELSE '' END AS SoundPath_E,
        -- Check if the service is currently active via Date check.
        CAST(CASE WHEN (GETDATE() BETWEEN REG.DateFrom AND REG.DateTo) THEN 1 ELSE 0 END AS BIT) AS IsCounterFittingServiceActive,
        @TotalRecords AS TotalRecords
    FROM (
        SELECT 
            ss.Service_ID, 
            ISNULL(CAST(sst.SST_Id AS VARCHAR(50)), ss.Subscribe_Id) AS Row_ID, 
            sst.Subscribe_Id, 
            ISNULL(sst.Points, 0) AS Points, 
            ISNULL(sst.Frequency, ss.PlanMasterPeriod) AS Frequency, 
            ISNULL(sst.IsCashConvert, 0) AS IsCashConvert, 
            ISNULL(sst.DateFrom, ss.DateFrom) AS DateFrom, 
            ISNULL(sst.DateTo, ss.DateTo) AS DateTo, 
            ISNULL(sst.Entry_Date, ss.EntryDate) AS Pasted_Date, 
            ISNULL(sst.Comments, ss.PlanName) AS Comments, 
            ISNULL(sst.IsActive, ss.IsActive) AS IsActive, 
            ISNULL(sst.IsDelete, ss.IsDelete) AS IsDelete, 
            ms.ServiceName, 
            p.Pro_Name, 
            ISNULL(mf.IsSound, 0) AS IsSound,
            ss.Comp_ID,
            ss.Pro_ID, 
            ss.PlanName,
            ss.PlanMasterPeriod,
            ss.start_order,
            ss.start_series,
            ss.end_order,
            ss.end_series,
            CASE WHEN ss.start_order IS NULL THEN '' ELSE CONCAT(ss.start_order,'-',ss.start_series,',',CONCAT(ss.end_order,'-',ss.end_series)) END AS servicerange,
            ISNULL(tr.FromSeries, CASE WHEN ss.start_order IS NULL THEN '' ELSE CONCAT(ss.Pro_ID, '-', RIGHT('0000' + CAST(ss.start_order AS VARCHAR(4)), 4), '-', RIGHT('0000' + CAST(ss.start_series AS VARCHAR(4)), 4)) END) AS FromSeries,
            ISNULL(tr.ToSeries, CASE WHEN ss.end_order IS NULL THEN '' ELSE CONCAT(ss.Pro_ID, '-', RIGHT('0000' + CAST(ss.end_order AS VARCHAR(4)), 4), '-', RIGHT('0000' + CAST(ss.end_series AS VARCHAR(4)), 4)) END) AS ToSeries
        FROM M_ServiceFeature mf
        INNER JOIN M_Service AS ms ON mf.Service_ID = ms.Service_ID 
        INNER JOIN M_ServiceSubscription AS ss ON ms.Service_ID = ss.Service_ID 
        INNER JOIN Pro_Reg AS p ON ss.Pro_ID = p.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans AS sst ON ss.Subscribe_Id = sst.Subscribe_Id 
        LEFT JOIN T_ReassignCode AS tr ON tr.ReassignCodeProId = ss.Pro_ID 
            AND tr.Comp_Id = ss.Comp_ID 
            AND tr.ServiceId = ss.Service_ID
            AND (
                (tr.Series_Order_From IS NOT NULL AND ss.start_order = tr.Series_Order_From AND ss.start_series = tr.Series_Serial_From AND ss.end_order = tr.Series_Order_To AND ss.end_series = tr.Series_Serial_To)
                OR
                (tr.Series_Order_From IS NULL AND 
                 ss.start_order = CAST(SUBSTRING(tr.FromSeries, CHARINDEX('-', tr.FromSeries) + 1, CHARINDEX('-', tr.FromSeries, CHARINDEX('-', tr.FromSeries) + 1) - CHARINDEX('-', tr.FromSeries) - 1) AS INT) AND
                 ss.start_series = CAST(REVERSE(SUBSTRING(REVERSE(tr.FromSeries), 1, CHARINDEX('-', REVERSE(tr.FromSeries)) - 1)) AS INT) AND
                 ss.end_order = CAST(SUBSTRING(tr.ToSeries, CHARINDEX('-', tr.ToSeries) + 1, CHARINDEX('-', tr.ToSeries, CHARINDEX('-', tr.ToSeries) + 1) - CHARINDEX('-', tr.ToSeries) - 1) AS INT) AND
                 ss.end_series = CAST(REVERSE(SUBSTRING(REVERSE(tr.ToSeries), 1, CHARINDEX('-', REVERSE(tr.ToSeries)) - 1)) AS INT)
                )
            )
    ) REG 
    WHERE (REG.Comp_ID = @Comp_ID) 
      AND (REG.Service_ID = 'SRV1018') 
      AND (@Pro_Name IS NULL OR REG.Pro_Name LIKE '%' + @Pro_Name + '%')
      AND (@FromDate IS NULL OR REG.Pasted_Date >= @FromDate)
      AND (@ToDate IS NULL OR REG.Pasted_Date <= @ToDate)
      AND (REG.IsDelete = 0)
    ORDER BY REG.Pasted_Date DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
