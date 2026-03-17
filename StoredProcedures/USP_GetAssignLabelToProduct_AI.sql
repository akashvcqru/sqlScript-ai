-- =============================================
-- Author:      AI
-- Create date: 2026-03-16
-- Update date: 2026-03-16 - Renamed and ensuring name consistency
-- Description: Get product details for label assignment (Detail or List)
-- =============================================
CREATE PROCEDURE [dbo].[USP_GetAssignLabelToProduct_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50) = NULL,
    @Pro_Name NVARCHAR(200) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Row_ID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Row_ID IS NOT NULL
    BEGIN
        -- BATCH DETAIL MODE
        SELECT 
            t.Pro_ID,
            pr.Pro_Name,
            pr.BatchSize,
            t.Batch_No AS BatchNo,
            t.MRP,
            CONVERT(VARCHAR, t.Mfd_Date, 105) AS MfdDate,
            CONVERT(VARCHAR, t.Exp_Date, 105) AS ExpDate,
            t.WarrantyDurationMonth AS Warranty,
            t.Comments,
            t.Row_ID AS RowId,
            (SELECT COUNT(Row_ID) FROM M_Code WHERE Batch_No = CONVERT(VARCHAR, t.Row_ID)) AS NoofCodes
        FROM T_Pro t
        INNER JOIN Pro_Reg pr ON t.Pro_ID = pr.Pro_ID
        WHERE t.Row_ID = @Row_ID AND pr.Comp_ID = @Comp_ID;

        -- Check for Counter Fitting Service (SRV1018)
        IF EXISTS (
            SELECT 1 
            FROM M_ServiceSubscription 
            WHERE Service_ID = 'SRV1018' 
              AND Pro_ID = (SELECT Pro_ID FROM T_Pro WHERE Row_ID = @Row_ID)
              AND GETDATE() BETWEEN DateFrom AND DateTo
        )
            SELECT 1 AS IsCounterFittingServiceActive;
        ELSE
            SELECT 0 AS IsCounterFittingServiceActive;
    END
    ELSE IF @Pro_ID IS NOT NULL AND @Pro_ID <> ''
    BEGIN
        -- SINGLE PRODUCT DETAIL MODE (For NEW assignment)
        
        -- 1. Get Product Name and BatchSize
        SELECT 
            Pro_Name,
            BatchSize
        FROM Pro_Reg 
        WHERE Comp_ID = @Comp_ID AND Pro_ID = @Pro_ID;

        -- 2. Get Available Codes Count
        SELECT COUNT(Pro_ID) AS AvailableCodes
        FROM M_Code
        WHERE Pro_ID = @Pro_ID 
          AND (ScrapeFlag IS NULL OR ScrapeFlag = 0)
          AND Print_Status = 1
          AND Batch_No IS NULL
          AND DispatchFlag = 1
          AND ReceiveFlag = 1;

        -- 3. Check for Counter Fitting Service (SRV1018)
        IF EXISTS (
            SELECT 1 
            FROM M_ServiceSubscription 
            WHERE Service_ID = 'SRV1018' 
              AND Pro_ID = @Pro_ID 
              AND GETDATE() BETWEEN DateFrom AND DateTo
        )
            SELECT 1 AS IsCounterFittingServiceActive;
        ELSE
            SELECT 0 AS IsCounterFittingServiceActive;
    END
    ELSE
    BEGIN
        -- BATCH LIST MODE (Instead of just product list)
        
        DECLARE @CalculatedToDate DATETIME = ISNULL(DATEADD(day, 1, @ToDate), '9999-12-31');

        SELECT 
            t.Pro_ID,
            pr.Pro_Name,
            pr.BatchSize,
            t.Entry_Date AS EntryDate,
            t.Batch_No AS BatchNo,
            t.MRP,
            CONVERT(VARCHAR, t.Mfd_Date, 105) AS MfdDate,
            CONVERT(VARCHAR, t.Exp_Date, 105) AS ExpDate,
            t.WarrantyDurationMonth AS Warranty,
            t.Comments,
            t.Row_ID AS RowId,
            (SELECT COUNT(mc.Row_ID) FROM M_Code mc WHERE mc.Batch_No = CONVERT(VARCHAR, t.Row_ID)) AS NoofCodes,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM M_ServiceSubscription ss 
                    WHERE ss.Service_ID = 'SRV1018' 
                      AND ss.Pro_ID = t.Pro_ID 
                      AND GETDATE() BETWEEN ss.DateFrom AND ss.DateTo
                ) THEN 1 
                ELSE 0 
            END AS IsCounterFittingServiceActive
        FROM T_Pro t
        INNER JOIN Pro_Reg pr ON t.Pro_ID = pr.Pro_ID
        WHERE pr.Comp_ID = @Comp_ID
          AND (@Pro_Name IS NULL OR pr.Pro_Name LIKE '%' + @Pro_Name + '%')
          AND (@FromDate IS NULL OR t.Entry_Date >= @FromDate)
          AND (t.Entry_Date < @CalculatedToDate)
        ORDER BY t.Entry_Date DESC;
    END
END
GO
