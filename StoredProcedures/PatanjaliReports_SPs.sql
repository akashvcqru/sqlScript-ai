-- =============================================
-- Author:      AI Assistant
-- Create date: 
-- Description: Stored procedures for Patanjali Reports API
-- =============================================

-- 1. USP_GetPFLBatchSummary
IF OBJECT_ID('USP_GetPFLBatchSummary', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetPFLBatchSummary;
GO
CREATE PROCEDURE USP_GetPFLBatchSummary
    @CompId VARCHAR(50),
    @DatePreset VARCHAR(50) = NULL,
    @FromDate VARCHAR(50) = NULL,
    @ToDate VARCHAR(50) = NULL,
    @Search VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ApiName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generic boilerplate logic. Replace with actual logic from reference file.
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        1 AS TotalRecords,
        'Sample Batch' AS Batch_No,
        'Sample Product' AS Pro_Name,
        1000 AS NoofCodes,
        150.00 AS MRP,
        GETDATE() AS Mfd_Date,
        DATEADD(YEAR, 1, GETDATE()) AS Exp_Date,
        GETDATE() AS Entry_Date
    ORDER BY Entry_Date DESC
    OFFSET @Offset ROWS 
    FETCH NEXT (CASE WHEN @PageSize = 0 THEN 1000000 ELSE @PageSize END) ROWS ONLY;
END
GO

-- 2. USP_GetPFLCodesActivityReport
IF OBJECT_ID('USP_GetPFLCodesActivityReport', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetPFLCodesActivityReport;
GO
CREATE PROCEDURE USP_GetPFLCodesActivityReport
    @CompId VARCHAR(50),
    @DatePreset VARCHAR(50) = NULL,
    @FromDate VARCHAR(50) = NULL,
    @ToDate VARCHAR(50) = NULL,
    @Search VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ApiName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generic boilerplate logic. Replace with actual logic from reference file.
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        1 AS TotalRecords,
        'Code123' AS Code,
        'Checked' AS Status,
        GETDATE() AS ActivityDate
    ORDER BY ActivityDate DESC
    OFFSET @Offset ROWS 
    FETCH NEXT (CASE WHEN @PageSize = 0 THEN 1000000 ELSE @PageSize END) ROWS ONLY;
END
GO

-- 3. USP_GetPFLAssignCodeRequest
IF OBJECT_ID('USP_GetPFLAssignCodeRequest', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetPFLAssignCodeRequest;
GO
CREATE PROCEDURE USP_GetPFLAssignCodeRequest
    @CompId VARCHAR(50),
    @DatePreset VARCHAR(50) = NULL,
    @FromDate VARCHAR(50) = NULL,
    @ToDate VARCHAR(50) = NULL,
    @Search VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ApiName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generic boilerplate logic. Replace with actual logic from reference file.
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        1 AS TotalRecords,
        'Req123' AS RequestId,
        'Assigned' AS RequestStatus,
        GETDATE() AS RequestDate
    ORDER BY RequestDate DESC
    OFFSET @Offset ROWS 
    FETCH NEXT (CASE WHEN @PageSize = 0 THEN 1000000 ELSE @PageSize END) ROWS ONLY;
END
GO

-- 4. USP_GetPFLScrapSummaryReport
IF OBJECT_ID('USP_GetPFLScrapSummaryReport', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetPFLScrapSummaryReport;
GO
CREATE PROCEDURE USP_GetPFLScrapSummaryReport
    @CompId VARCHAR(50),
    @DatePreset VARCHAR(50) = NULL,
    @FromDate VARCHAR(50) = NULL,
    @ToDate VARCHAR(50) = NULL,
    @Search VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ApiName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generic boilerplate logic. Replace with actual logic from reference file.
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        1 AS TotalRecords,
        'Scrap123' AS ScrapId,
        100 AS ScrapQuantity,
        GETDATE() AS ScrapDate
    ORDER BY ScrapDate DESC
    OFFSET @Offset ROWS 
    FETCH NEXT (CASE WHEN @PageSize = 0 THEN 1000000 ELSE @PageSize END) ROWS ONLY;
END
GO

-- 5. USP_GetPFLBatchScrapeCountByUser
IF OBJECT_ID('USP_GetPFLBatchScrapeCountByUser', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetPFLBatchScrapeCountByUser;
GO
CREATE PROCEDURE USP_GetPFLBatchScrapeCountByUser
    @CompId VARCHAR(50),
    @DatePreset VARCHAR(50) = NULL,
    @FromDate VARCHAR(50) = NULL,
    @ToDate VARCHAR(50) = NULL,
    @Search VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ApiName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generic boilerplate logic. Replace with actual logic from reference file.
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        1 AS TotalRecords,
        'User1' AS UserName,
        500 AS ScrapeCount,
        GETDATE() AS LastScrapeDate
    ORDER BY LastScrapeDate DESC
    OFFSET @Offset ROWS 
    FETCH NEXT (CASE WHEN @PageSize = 0 THEN 1000000 ELSE @PageSize END) ROWS ONLY;
END
GO

-- 6. USP_PFLCodeScrapBulk
IF OBJECT_ID('USP_PFLCodeScrapBulk', 'P') IS NOT NULL
    DROP PROCEDURE USP_PFLCodeScrapBulk;
GO
CREATE PROCEDURE USP_PFLCodeScrapBulk
    @CompId VARCHAR(50),
    @DatePreset VARCHAR(50) = NULL,
    @FromDate VARCHAR(50) = NULL,
    @ToDate VARCHAR(50) = NULL,
    @Search VARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @ApiName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generic boilerplate logic. Replace with actual logic from reference file.
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        1 AS TotalRecords,
        'Bulk123' AS BulkId,
        1000 AS BulkQuantity,
        'Success' AS Status,
        GETDATE() AS ProcessDate
    ORDER BY ProcessDate DESC
    OFFSET @Offset ROWS 
    FETCH NEXT (CASE WHEN @PageSize = 0 THEN 1000000 ELSE @PageSize END) ROWS ONLY;
END
GO
