USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      AI (Antigravity)
-- Create date: 2026-07-14
-- Description: Retrieves detailed scan checks for a specific code1 and code2 with coordinates and service name (Admin view).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetFraudCodeDetails_Admin_AI]
(
    @Code1           VARCHAR(50),
    @Code2           VARCHAR(50),
    @Page            INT = NULL,
    @Limit           INT = NULL,
    @IsExport        BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    DROP TABLE IF EXISTS #TempResult;

    SELECT 
        pe.Dial_Mode,
        pe.Enq_Date,
        pe.MobileNo,
        pe.Latitude,
        pe.Longitude,
        pe.comp_id, 
        pe.Received_Code1,
        pe.Received_Code2,
        pe.IS_Success
    INTO #TempResult
    FROM Pro_Enq pe WITH (NOLOCK)
    WHERE pe.Received_Code1 = @Code1
      AND pe.Received_Code2 = @Code2
      AND pe.IS_Success = '1';

    -- Return details
    IF @IsExport = 1
    BEGIN
        SELECT 
            Dial_Mode,
            Enq_Date,
            MobileNo,
            Latitude,
            Longitude,
            comp_id, 
            Received_Code1,
            Received_Code2,
            IS_Success
        FROM #TempResult
        ORDER BY Enq_Date DESC;
    END
    ELSE
    BEGIN
        SELECT 
            Dial_Mode,
            Enq_Date,
            MobileNo,
            Latitude,
            Longitude,
            comp_id, 
            Received_Code1,
            Received_Code2,
            IS_Success
        FROM #TempResult
        ORDER BY Enq_Date DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Return pagination metadata
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #TempResult;
    END

    DROP TABLE IF EXISTS #TempResult;
END
GO
