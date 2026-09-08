USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-09-08
-- Description: Get Vendor Soft Code Print History for Admin View / Drill-down
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetVendorSoftCodePrintHistory_AI]
    @Comp_ID NVARCHAR(50) = NULL,
    @Search NVARCHAR(100) = NULL,
    @Offset INT = 0,
    @Limit INT = 10,
    @IsExport BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SearchPattern NVARCHAR(105) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
    BEGIN
        SET @SearchPattern = '%' + LTRIM(RTRIM(@Search)) + '%';
    END

    -- Total Count (only if not exporting)
    IF @IsExport = 0
    BEGIN
        SELECT COUNT(1) AS TotalRecords
        FROM tbl_SoftCodegenrate_Details SD WITH (NOLOCK)
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON SD.Pro_id = PR.Pro_ID
        LEFT JOIN Comp_Reg CR WITH (NOLOCK) ON ISNULL(SD.Comp_id, PR.Comp_ID) = CR.Comp_ID
        WHERE (@Comp_ID IS NULL OR SD.Comp_id = @Comp_ID OR PR.Comp_ID = @Comp_ID)
          AND (SD.Isdelete IS NULL OR SD.Isdelete = 0)
          AND (@SearchPattern IS NULL 
               OR SD.Comp_id LIKE @SearchPattern 
               OR CR.Comp_Name LIKE @SearchPattern 
               OR PR.Pro_Name LIKE @SearchPattern 
               OR SD.Pro_id LIKE @SearchPattern 
               OR SD.TrackingId LIKE @SearchPattern);
    END

    -- Paged Data Query
    SELECT 
        ISNULL(SD.Comp_id, PR.Comp_ID) AS Comp_ID,
        CR.Comp_Name AS CompName,
        SD.TrackingId,
        SD.Pro_id AS Pro_ID,
        PR.Pro_Name,
        ISNULL(SD.NOOfLabelRequest, 0) AS CodesPrinted,
        SD.MRP,
        SD.Frequency,
        SD.ProductRange,
        SD.ProductQTY,
        SD.Entry_date AS PrintDate,
        CASE WHEN LR.PrintType = '2' THEN 'QR Code Only' ELSE '13 Digit Code Only' END AS QrCodeType
    FROM tbl_SoftCodegenrate_Details SD WITH (NOLOCK)
    INNER JOIN Pro_Reg PR WITH (NOLOCK) ON SD.Pro_id = PR.Pro_ID
    LEFT JOIN Comp_Reg CR WITH (NOLOCK) ON ISNULL(SD.Comp_id, PR.Comp_ID) = CR.Comp_ID
    LEFT JOIN M_Label_Request LR WITH (NOLOCK) ON SD.TrackingId = LR.Tracking_No
    WHERE (@Comp_ID IS NULL OR SD.Comp_id = @Comp_ID OR PR.Comp_ID = @Comp_ID)
      AND (SD.Isdelete IS NULL OR SD.Isdelete = 0)
      AND (@SearchPattern IS NULL 
           OR SD.Comp_id LIKE @SearchPattern 
           OR CR.Comp_Name LIKE @SearchPattern 
           OR PR.Pro_Name LIKE @SearchPattern 
           OR SD.Pro_id LIKE @SearchPattern 
           OR SD.TrackingId LIKE @SearchPattern)
    ORDER BY SD.Id DESC
    OFFSET (CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END) ROWS
    FETCH NEXT (CASE WHEN @IsExport = 1 THEN 100000000 ELSE @Limit END) ROWS ONLY;
END
GO
