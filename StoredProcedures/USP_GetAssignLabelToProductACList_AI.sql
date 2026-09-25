USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetAssignLabelToProductACList_AI]    Script Date: 18-08-2026 20:30:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_GetAssignLabelToProductACList_AI]
    @Comp_ID NVARCHAR(50),
    @Search NVARCHAR(MAX) = NULL,
    @Pro_Name NVARCHAR(MAX) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @PageIndex INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');
    SET @Pro_Name = NULLIF(LTRIM(RTRIM(@Pro_Name)), '');

    -- Calculate total records count
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*)
    FROM (
        SELECT ss.Comp_ID, ss.Service_ID, p.Pro_Name, 
               ISNULL(sst.Entry_Date, ss.EntryDate) AS Entry_Date, 
               ISNULL(sst.IsDelete, ISNULL(ss.IsDelete, 0)) AS IsDelete
        FROM M_ServiceSubscription AS ss
        INNER JOIN Pro_Reg AS p ON ss.Pro_ID = p.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans AS sst ON ss.Subscribe_Id = sst.Subscribe_Id 
        WHERE (ss.Comp_ID = @Comp_ID) 
          AND (ss.Service_ID = 'SRV1018') 
          AND (@Pro_Name IS NULL OR p.Pro_Name LIKE '%' + @Pro_Name + '%')
          AND (@FromDate IS NULL OR ISNULL(sst.Entry_Date, ss.EntryDate) >= @FromDate)
          AND (@ToDate IS NULL OR ISNULL(sst.Entry_Date, ss.EntryDate) <= @ToDate)
          AND (ISNULL(sst.IsDelete, ISNULL(ss.IsDelete, 0)) = 0)
          AND (
              @Search IS NULL
              OR p.Pro_Name LIKE '%' + @Search + '%'
              OR ss.Pro_ID LIKE '%' + @Search + '%'
              OR ss.PlanName LIKE '%' + @Search + '%'
              OR CAST(ss.start_order AS VARCHAR) LIKE '%' + @Search + '%'
              OR CAST(ss.start_series AS VARCHAR) LIKE '%' + @Search + '%'
              OR CAST(ss.end_order AS VARCHAR) LIKE '%' + @Search + '%'
              OR CAST(ss.end_series AS VARCHAR) LIKE '%' + @Search + '%'
              OR (CAST(ss.start_order AS VARCHAR) + '-' + CAST(ss.start_series AS VARCHAR)) LIKE '%' + @Search + '%'
              OR (CAST(ss.end_order AS VARCHAR) + '-' + CAST(ss.end_series AS VARCHAR)) LIKE '%' + @Search + '%'
              OR (CAST(ss.start_order AS VARCHAR) + '-' + CAST(ss.start_series AS VARCHAR) + ' to ' + CAST(ss.end_order AS VARCHAR) + '-' + CAST(ss.end_series AS VARCHAR)) LIKE '%' + @Search + '%'
          )
    ) AS T;

    -- Fetch the list with pagination
    SELECT DISTINCT 
        ISNULL(REG.SST_Id, 0) AS SST_Id,
        REG.Subscribe_Id,
        REG.Pro_ID,
        REG.Service_ID,
        REG.Points,
        REG.Frequency,
        REG.IsCashConvert,
        CONVERT(VARCHAR(23), REG.DateFrom, 121) AS DateFrom,
        CONVERT(VARCHAR(23), REG.DateTo, 121) AS DateTo,
        REG.EntryDate,
        REG.Comments,
        REG.Comp_ID,  
        REG.Pro_Name,
        REG.ServiceName,
        REG.servicerange,
        REG.PlanName,
        REG.PlanMasterPeriod,
        REG.FromSeries,
        REG.ToSeries,
        REG.Batch_No,
        REG.Tpro_Id,
        -- Sound Paths
        CASE WHEN REG.IsSound = 1 THEN '../Data/Sound/' + SUBSTRING(REG.Comp_ID, 6, 4) + '/' + REG.Pro_ID + '/Loyalty/'+ CONVERT(VARCHAR, ISNULL(CAST(REG.SST_Id AS VARCHAR(50)), REG.Subscribe_Id)) +'/' + CONVERT(VARCHAR, ISNULL(CAST(REG.SST_Id AS VARCHAR(50)), REG.Subscribe_Id)) + '_H.wav' ELSE '' END AS SoundPath_H,
        CASE WHEN REG.IsSound = 1 THEN '../Data/Sound/' + SUBSTRING(REG.Comp_ID, 6, 4) + '/' + REG.Pro_ID + '/Loyalty/'+ CONVERT(VARCHAR, ISNULL(CAST(REG.SST_Id AS VARCHAR(50)), REG.Subscribe_Id)) +'/' + CONVERT(VARCHAR, ISNULL(CAST(REG.SST_Id AS VARCHAR(50)), REG.Subscribe_Id)) + '_E.wav' ELSE '' END AS SoundPath_E,
        -- Service is active only when both M_ServiceSubscription (ss) and M_ServiceSubscriptionTrans (sst) have IsActive = 1
        CAST(CASE WHEN ISNULL(REG.SS_IsActive, 0) = 1 AND ISNULL(REG.SST_IsActive, 1) = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive,
        CASE WHEN ISNULL(REG.SS_IsActive, 0) = 1 AND ISNULL(REG.SST_IsActive, 1) = 1 THEN 'Activated' ELSE 'De-Activated' END AS StatusText,
        REG.IsDelete,
        CAST(CASE WHEN ISNULL(REG.SS_IsActive, 0) = 1 AND ISNULL(REG.SST_IsActive, 1) = 1 THEN 1 ELSE 0 END AS BIT) AS IsCounterFittingServiceActive,
        @TotalRecords AS TotalRecords
    FROM (
        SELECT 
            ss.Service_ID, 
            sst.SST_Id, 
            ss.Subscribe_Id, 
            ISNULL(sst.Points, 0) AS Points, 
            ISNULL(sst.Frequency, ss.PlanMasterPeriod) AS Frequency, 
            ISNULL(sst.IsCashConvert, 0) AS IsCashConvert, 
            ISNULL(sst.DateFrom, ss.DateFrom) AS DateFrom, 
            ISNULL(sst.DateTo, ss.DateTo) AS DateTo, 
            ISNULL(sst.Entry_Date, ss.EntryDate) AS EntryDate, 
            ISNULL(sst.Comments, ss.PlanName) AS Comments, 
            ss.IsActive AS SS_IsActive,
            sst.IsActive AS SST_IsActive,
            ISNULL(sst.IsActive, ss.IsActive) AS IsActive, 
            ISNULL(sst.IsDelete, ISNULL(ss.IsDelete, 0)) AS IsDelete, 
            ISNULL(ms.ServiceName, 'Anti Counterfeit') AS ServiceName, 
            p.Pro_Name, 
            ISNULL(mf.IsSound, 0) AS IsSound,
            ss.Comp_ID,
            ss.Pro_ID, 
            ss.PlanName,
            ISNULL(CAST(ss.PlanMasterPeriod AS VARCHAR(50)), '') AS PlanMasterPeriod,
            ss.start_order,
            ss.start_series,
            ss.end_order,
            ss.end_series,
            TP.Tpro_Id,
            ISNULL(TP.Batch_No, '') AS Batch_No,
            CASE WHEN ss.start_order IS NULL THEN '' ELSE CONCAT(ss.start_order,'-',ss.start_series,',',CONCAT(ss.end_order,'-',ss.end_series)) END AS servicerange,
            ISNULL(tr.FromSeries, CASE WHEN ss.start_order IS NULL THEN '' ELSE CONCAT(ss.Pro_ID, '-', RIGHT('0000' + CAST(ss.start_order AS VARCHAR(4)), 4), '-', RIGHT('0000' + CAST(ss.start_series AS VARCHAR(4)), 4)) END) AS FromSeries,
            ISNULL(tr.ToSeries, CASE WHEN ss.end_order IS NULL THEN '' ELSE CONCAT(ss.Pro_ID, '-', RIGHT('0000' + CAST(ss.end_order AS VARCHAR(4)), 4), '-', RIGHT('0000' + CAST(ss.end_series AS VARCHAR(4)), 4)) END) AS ToSeries
        FROM M_ServiceSubscription AS ss
        INNER JOIN Pro_Reg AS p ON ss.Pro_ID = p.Pro_ID
        LEFT JOIN M_Service AS ms ON ss.Service_ID = ms.Service_ID 
        LEFT JOIN M_ServiceFeature mf ON ss.Service_ID = mf.Service_ID 
        LEFT JOIN M_ServiceSubscriptionTrans AS sst ON ss.Subscribe_Id = sst.Subscribe_Id 
        OUTER APPLY (
            SELECT TOP 1 Row_ID AS Tpro_Id, Batch_No 
            FROM T_Pro WITH (NOLOCK) 
            WHERE Pro_ID = ss.Pro_ID 
              AND (
                  (ss.start_order IS NOT NULL AND Series_Limit LIKE '%' + CAST(ss.start_order AS VARCHAR) + '%')
                  OR (Comments = sst.Comments AND Comments IS NOT NULL AND Comments <> '')
                  OR (Entry_Date >= DATEADD(SECOND, -30, ISNULL(sst.Entry_Date, ss.EntryDate)) AND Entry_Date <= DATEADD(SECOND, 30, ISNULL(sst.Entry_Date, ss.EntryDate)))
              )
            ORDER BY Row_ID DESC
        ) TP
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
      AND (@FromDate IS NULL OR REG.EntryDate >= @FromDate)
      AND (@ToDate IS NULL OR REG.EntryDate <= @ToDate)
      AND (REG.IsDelete = 0)
      AND (
          @Search IS NULL
          OR REG.Pro_Name LIKE '%' + @Search + '%'
          OR REG.Pro_ID LIKE '%' + @Search + '%'
          OR REG.PlanName LIKE '%' + @Search + '%'
          OR REG.FromSeries LIKE '%' + @Search + '%'
          OR REG.ToSeries LIKE '%' + @Search + '%'
          OR REG.servicerange LIKE '%' + @Search + '%'
          OR REG.Comments LIKE '%' + @Search + '%'
      )
    ORDER BY REG.EntryDate DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
