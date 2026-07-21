USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetPFLBatchSummary]    Script Date: 7/21/2026 11:18:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_GetPFLBatchSummary]
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
