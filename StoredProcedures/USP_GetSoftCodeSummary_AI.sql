USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-08-11
-- Description: Optimized Get Soft Code Summary with pagination, date filters and search
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetSoftCodeSummary_AI]
    @Comp_ID NVARCHAR(50),
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @Search NVARCHAR(100) = NULL,
    @Offset INT = 0,
    @Limit INT = 10,
    @IsExport BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SettingsExist INT = 0;
    IF EXISTS (SELECT 1 FROM M_QRCode_Print_Settings WHERE Comp_ID = @Comp_ID)
    BEGIN
        SET @SettingsExist = 1;
    END

    DECLARE @SearchPattern NVARCHAR(105) = NULL;
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
    BEGIN
        SET @SearchPattern = '%' + LTRIM(RTRIM(@Search)) + '%';
    END

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        ;WITH FilteredBatches AS (
            SELECT 
                SD.Id,
                SD.TrackingId,
                SD.Pro_id,
                SD.Entry_date,
                SD.NOOfLabelRequest,
                SD.MRP,
                SD.Frequency,
                SD.pointsdata,
                B.Pro_Name,
                B.Display_Series,
                B.pro_desc,
                LR.PrintType,
                COUNT(*) OVER() AS TotalRecords
            FROM tbl_SoftCodegenrate_Details SD WITH (NOLOCK)
            INNER JOIN Pro_Reg B WITH (NOLOCK) ON SD.Pro_id = B.Pro_ID
            LEFT JOIN M_Label_Request LR WITH (NOLOCK) ON SD.TrackingId = LR.Tracking_No
            WHERE SD.Comp_id = @Comp_ID
              AND (SD.Isdelete IS NULL OR SD.Isdelete = 0)
              AND (@DateFrom IS NULL OR SD.Entry_date >= @DateFrom)
              AND (@DateTo IS NULL OR SD.Entry_date <= @DateTo)
              AND (@SearchPattern IS NULL OR SD.TrackingId LIKE @SearchPattern OR B.Pro_Name LIKE @SearchPattern OR SD.Pro_id LIKE @SearchPattern OR B.Display_Series LIKE @SearchPattern OR B.pro_desc LIKE @SearchPattern)
        ),
        PaginatedBatches AS (
            SELECT *
            FROM FilteredBatches
            ORDER BY Id DESC
            OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
            FETCH NEXT CASE WHEN @IsExport = 1 THEN 2147483647 ELSE @Limit END ROWS ONLY
        )
        SELECT 
            PB.Id AS ID,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_id) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_id) + '-0000-0000'
            ) AS SerFr,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_id) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_id) + '-0000-0000'
            ) AS SerTo,
            ISNULL(S.Codes, ISNULL(PB.NOOfLabelRequest, 0)) AS Codes,
            PB.Pro_id AS pro_id,
            PB.pro_desc,
            PB.Pro_id + '*' + CONVERT(NVARCHAR, PB.Entry_date, 105) + '*' + ISNULL(PB.TrackingId, '') AS DownFl,
            PB.Pro_Name,
            CAST(PB.Entry_date AS DATE) AS print_date,
            ISNULL(S.IsDispatched, 1) AS IsDispatched,
            CASE WHEN @SettingsExist = 1 AND PB.PrintType = '2' THEN 'QR Code Only' ELSE '13 Digit Code Only' END AS QrCodeType,
            PB.TotalRecords,
            PB.MRP,
            PB.Frequency,
            PB.pointsdata
        FROM PaginatedBatches PB
        OUTER APPLY (
            SELECT 
                MIN(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MinIndex,
                MAX(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MaxIndex,
                COUNT(MC.Row_ID) as Codes,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) as IsDispatched
            FROM M_Code_PFL MC WITH (NOLOCK)
            WHERE MC.LabelRequestId = PB.TrackingId AND MC.Pro_ID = PB.Pro_id AND MC.[Use_Type]='L'
        ) S
        ORDER BY PB.Id DESC;
    END
    ELSE
    BEGIN
        ;WITH FilteredBatches AS (
            SELECT 
                SD.Id,
                SD.TrackingId,
                SD.Pro_id,
                SD.Entry_date,
                SD.NOOfLabelRequest,
                SD.MRP,
                SD.Frequency,
                SD.pointsdata,
                B.Pro_Name,
                B.Display_Series,
                B.pro_desc,
                LR.PrintType,
                COUNT(*) OVER() AS TotalRecords
            FROM tbl_SoftCodegenrate_Details SD WITH (NOLOCK)
            INNER JOIN Pro_Reg B WITH (NOLOCK) ON SD.Pro_id = B.Pro_ID
            LEFT JOIN M_Label_Request LR WITH (NOLOCK) ON SD.TrackingId = LR.Tracking_No
            WHERE SD.Comp_id = @Comp_ID
              AND (SD.Isdelete IS NULL OR SD.Isdelete = 0)
              AND (@DateFrom IS NULL OR SD.Entry_date >= @DateFrom)
              AND (@DateTo IS NULL OR SD.Entry_date <= @DateTo)
              AND (@SearchPattern IS NULL OR SD.TrackingId LIKE @SearchPattern OR B.Pro_Name LIKE @SearchPattern OR SD.Pro_id LIKE @SearchPattern OR B.Display_Series LIKE @SearchPattern OR B.pro_desc LIKE @SearchPattern)
        ),
        PaginatedBatches AS (
            SELECT *
            FROM FilteredBatches
            ORDER BY Id DESC
            OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
            FETCH NEXT CASE WHEN @IsExport = 1 THEN 2147483647 ELSE @Limit END ROWS ONLY
        )
        SELECT 
            PB.Id AS ID,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_id) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_id) + '-0000-0000'
            ) AS SerFr,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_id) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_id) + '-0000-0000'
            ) AS SerTo,
            ISNULL(S.Codes, ISNULL(PB.NOOfLabelRequest, 0)) AS Codes,
            PB.Pro_id AS pro_id,
            PB.pro_desc,
            PB.Pro_id + '*' + CONVERT(NVARCHAR, PB.Entry_date, 105) + '*' + ISNULL(PB.TrackingId, '') AS DownFl,
            PB.Pro_Name,
            CAST(PB.Entry_date AS DATE) AS print_date,
            ISNULL(S.IsDispatched, 1) AS IsDispatched,
            CASE WHEN @SettingsExist = 1 AND PB.PrintType = '2' THEN 'QR Code Only' ELSE '13 Digit Code Only' END AS QrCodeType,
            PB.TotalRecords,
            PB.MRP,
            PB.Frequency,
            PB.pointsdata
        FROM PaginatedBatches PB
        OUTER APPLY (
            SELECT 
                MIN(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MinIndex,
                MAX(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MaxIndex,
                COUNT(MC.Row_ID) as Codes,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) as IsDispatched
            FROM M_Code MC WITH (NOLOCK)
            WHERE MC.LabelRequestId = PB.TrackingId AND MC.Pro_ID = PB.Pro_id AND MC.[Use_Type]='L'
        ) S
        ORDER BY PB.Id DESC;
    END
END
GO
