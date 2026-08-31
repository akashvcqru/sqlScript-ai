USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-05-22
-- Update date: 2026-08-31
-- Description: Get Label Print List with pagination and filters (optimized using M_Label_Request and paginated OUTER APPLY)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetLabelPrintList_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50) = NULL,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @Offset INT = 0,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SettingsExist INT = 0;
    IF EXISTS (SELECT 1 FROM M_QRCode_Print_Settings WHERE Comp_ID = @Comp_ID)
    BEGIN
        SET @SettingsExist = 1;
    END

    -- Normalize empty or zero product ID
    IF @Pro_ID = '' OR @Pro_ID = '0'
        SET @Pro_ID = NULL;

    IF @Comp_ID = 'Comp-1693'
    BEGIN
        ;WITH FilteredBatches AS (
            SELECT 
                LR.Row_ID,
                CAST(LR.Tracking_No AS NVARCHAR(50)) AS Tracking_No,
                LR.Pro_ID,
                LR.Entry_Date,
                LR.Qty,
                LR.PrintType,
                B.Pro_Name,
                B.Display_Product,
                B.Display_Series,
                COUNT(*) OVER() AS TotalRecords
            FROM M_Label_Request LR WITH (NOLOCK)
            INNER JOIN Pro_Reg B WITH (NOLOCK) ON LR.Pro_ID = B.Pro_ID
            WHERE B.Comp_ID = @Comp_ID
              AND LR.Tracking_No IS NOT NULL
              AND (LR.Flag = 1 OR LR.Flag IS NULL)
              AND (@Pro_ID IS NULL OR LR.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR LR.Entry_Date >= CAST(@DateFrom AS DATE))
              AND (@DateTo IS NULL OR LR.Entry_Date < DATEADD(DAY, 1, CAST(@DateTo AS DATE)))
        ),
        PaginatedBatches AS (
            SELECT *
            FROM FilteredBatches
            ORDER BY Entry_Date DESC, Row_ID DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
        )
        SELECT 
            PB.Row_ID AS ID,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_ID) + '-0000-0000'
            ) AS SerFr,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_ID) + '-0000-0000'
            ) AS SerTo,
            ISNULL(S.Codes, ISNULL(PB.Qty, 0)) AS Codes,
            ISNULL(PB.Display_Series, PB.Pro_ID) AS Pro_ID,
            PB.Pro_ID + '*' + CONVERT(NVARCHAR, PB.Entry_Date, 105) + '*' + ISNULL(PB.Tracking_No, '') AS DownFl,
            ISNULL(PB.Display_Product, PB.Pro_Name) AS Pro_Name,
            CAST(PB.Entry_Date AS DATE) AS print_date,
            ISNULL(S.IsDispatched, 0) AS IsDispatched,
            CASE WHEN @SettingsExist = 1 AND PB.PrintType = '2' THEN 'QR Code Only' ELSE '13 Digit Code Only' END AS QrCodeType,
            PB.TotalRecords
        FROM PaginatedBatches PB
        OUTER APPLY (
            SELECT 
                MIN(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MinIndex,
                MAX(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MaxIndex,
                COUNT(MC.Row_ID) as Codes,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) as IsDispatched
            FROM M_Code_PFL MC WITH (NOLOCK)
            WHERE MC.LabelRequestId = PB.Tracking_No AND MC.Pro_ID = PB.Pro_ID
        ) S
        ORDER BY PB.Entry_Date DESC, PB.Row_ID DESC
        OPTION (RECOMPILE);
    END
    ELSE
    BEGIN
        ;WITH FilteredBatches AS (
            SELECT 
                LR.Row_ID,
                CAST(LR.Tracking_No AS NVARCHAR(50)) AS Tracking_No,
                LR.Pro_ID,
                LR.Entry_Date,
                LR.Qty,
                LR.PrintType,
                B.Pro_Name,
                B.Display_Product,
                B.Display_Series,
                COUNT(*) OVER() AS TotalRecords
            FROM M_Label_Request LR WITH (NOLOCK)
            INNER JOIN Pro_Reg B WITH (NOLOCK) ON LR.Pro_ID = B.Pro_ID
            WHERE B.Comp_ID = @Comp_ID
              AND LR.Tracking_No IS NOT NULL
              AND (LR.Flag = 1 OR LR.Flag IS NULL)
              AND (@Pro_ID IS NULL OR LR.Pro_ID = @Pro_ID)
              AND (@DateFrom IS NULL OR LR.Entry_Date >= CAST(@DateFrom AS DATE))
              AND (@DateTo IS NULL OR LR.Entry_Date < DATEADD(DAY, 1, CAST(@DateTo AS DATE)))
        ),
        PaginatedBatches AS (
            SELECT *
            FROM FilteredBatches
            ORDER BY Entry_Date DESC, Row_ID DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
        )
        SELECT 
            PB.Row_ID AS ID,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MinIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_ID) + '-0000-0000'
            ) AS SerFr,
            ISNULL(
                CONVERT(NVARCHAR, PB.Pro_ID) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex / 10000, 0)), 4) + '-' + RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(S.MaxIndex % 10000, 0)), 4),
                CONVERT(NVARCHAR, PB.Pro_ID) + '-0000-0000'
            ) AS SerTo,
            ISNULL(S.Codes, ISNULL(PB.Qty, 0)) AS Codes,
            ISNULL(PB.Display_Series, PB.Pro_ID) AS Pro_ID,
            PB.Pro_ID + '*' + CONVERT(NVARCHAR, PB.Entry_Date, 105) + '*' + ISNULL(PB.Tracking_No, '') AS DownFl,
            ISNULL(PB.Display_Product, PB.Pro_Name) AS Pro_Name,
            CAST(PB.Entry_Date AS DATE) AS print_date,
            ISNULL(S.IsDispatched, 0) AS IsDispatched,
            CASE WHEN @SettingsExist = 1 AND PB.PrintType = '2' THEN 'QR Code Only' ELSE '13 Digit Code Only' END AS QrCodeType,
            PB.TotalRecords
        FROM PaginatedBatches PB
        OUTER APPLY (
            SELECT 
                MIN(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MinIndex,
                MAX(CAST(MC.Series_Order AS BIGINT) * 10000 + CAST(MC.Series_Serial AS BIGINT)) as MaxIndex,
                COUNT(MC.Row_ID) as Codes,
                MAX(CAST(ISNULL(MC.DispatchFlag, 0) AS INT)) as IsDispatched
            FROM M_Code MC WITH (NOLOCK)
            WHERE MC.LabelRequestId = PB.Tracking_No AND MC.Pro_ID = PB.Pro_ID
        ) S
        ORDER BY PB.Entry_Date DESC, PB.Row_ID DESC
        OPTION (RECOMPILE);
    END
END
GO
