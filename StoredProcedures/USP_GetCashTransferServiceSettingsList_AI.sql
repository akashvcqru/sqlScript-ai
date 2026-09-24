USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================================================
-- Author:      AI
-- Create date: 2026-09-24
-- Description: Get Cash Transfer Service Settings List (SRV1005) with Pagination, Filters, and Export
-- =============================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCashTransferServiceSettingsList_AI]
    @Comp_ID    NVARCHAR(50),
    @Search     NVARCHAR(MAX) = NULL,
    @Pro_Name   NVARCHAR(MAX) = NULL,
    @FromDate   DATETIME = NULL,
    @ToDate     DATETIME = NULL,
    @PageIndex  INT = 1,
    @PageSize   INT = 10,
    @IsExport   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SET @Search = NULLIF(LTRIM(RTRIM(@Search)), '');
    SET @Pro_Name = NULLIF(LTRIM(RTRIM(@Pro_Name)), '');

    IF @IsExport = 1
    BEGIN
        SET @PageIndex = 1;
        SET @PageSize = 1000000;
    END

    -- Calculate total records count
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*)
    FROM (
        SELECT ss.Comp_ID, ss.Service_ID, p.Pro_Name, 
               ISNULL(sst.Entry_Date, ss.EntryDate) AS Entry_Date, 
               ISNULL(sst.IsDelete, ISNULL(ss.IsDelete, 0)) AS IsDelete
        FROM M_ServiceSubscription AS ss WITH (NOLOCK)
        INNER JOIN Pro_Reg AS p WITH (NOLOCK) ON ss.Pro_ID = p.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans AS sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id 
        WHERE (ss.Comp_ID = @Comp_ID) 
          AND (ss.Service_ID = 'SRV1005') 
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
        REG.Points,
        REG.IsCash,
        REG.Frequency,
        REG.IsCashConvert,
        CONVERT(VARCHAR(23), REG.DateFrom, 121) AS DateFrom,
        CONVERT(VARCHAR(23), REG.DateTo, 121) AS DateTo,
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
        REG.AmtType,
        REG.totalamont AS TotalLoyalty,
        REG.Minval,
        REG.Maxval,
        CAST(CASE WHEN ISNULL(REG.SS_IsActive, 0) = 1 AND ISNULL(REG.SST_IsActive, 1) = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive,
        @TotalRecords AS TotalRecords
    FROM (
        SELECT 
            ss.Service_ID, 
            sst.SST_Id, 
            ss.Subscribe_Id, 
            ISNULL(sst.Points, 0) AS Points, 
            ISNULL(sst.IsCash, ISNULL(sst.Points, 0)) AS IsCash,
            ISNULL(sst.Frequency, ss.PlanMasterPeriod) AS Frequency, 
            ISNULL(sst.IsCashConvert, 1) AS IsCashConvert, 
            ISNULL(sst.DateFrom, ss.DateFrom) AS DateFrom, 
            ISNULL(sst.DateTo, ss.DateTo) AS DateTo, 
            ISNULL(sst.Entry_Date, ss.EntryDate) AS Pasted_Date, 
            sst.Comments, 
            ss.Comp_ID, 
            p.Pro_Name,
            ISNULL(s.ServiceName, 'Cash Transfer') AS ServiceName,
            CAST(ISNULL(ss.start_order, '') AS VARCHAR(100)) + '-' + 
            CAST(ISNULL(ss.start_series, '') AS VARCHAR(100)) + ' to ' + 
            CAST(ISNULL(ss.end_order, '') AS VARCHAR(100)) + '-' + 
            CAST(ISNULL(ss.end_series, '') AS VARCHAR(100)) AS servicerange,
            ss.PlanName,
            ss.PlanMasterPeriod,
            ss.start_order,
            ss.start_series,
            ss.end_order,
            ss.end_series,
            CAST(ISNULL(ss.start_order, '') AS VARCHAR(100)) + '-' + CAST(ISNULL(ss.start_series, '') AS VARCHAR(100)) AS FromSeries,
            CAST(ISNULL(ss.end_order, '') AS VARCHAR(100)) + '-' + CAST(ISNULL(ss.end_series, '') AS VARCHAR(100)) AS ToSeries,
            ss.IsActive AS SS_IsActive,
            sst.IsActive AS SST_IsActive,
            sst.AmtType,
            sst.totalamont,
            sst.Minval,
            sst.Maxval,
            ss.Pro_ID
        FROM M_ServiceSubscription AS ss WITH (NOLOCK)
        INNER JOIN Pro_Reg AS p WITH (NOLOCK) ON ss.Pro_ID = p.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans AS sst WITH (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id 
        LEFT JOIN M_Service AS s WITH (NOLOCK) ON ss.Service_ID = s.Service_ID
        WHERE (ss.Comp_ID = @Comp_ID) 
          AND (ss.Service_ID = 'SRV1005')
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
    ) AS REG
    ORDER BY REG.Pasted_Date DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
