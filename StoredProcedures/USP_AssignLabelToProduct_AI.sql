-- =============================================
-- Author:      AI
-- Create date: 2026-03-16
-- Update date: 2026-03-16 - Added listing and filtering support
-- Description: Get product details for label assignment (Detail or List)
-- =============================================
ALTER PROCEDURE [dbo].[USP_GetAssignLabelToProduct_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50) = NULL,
    @Pro_Name NVARCHAR(200) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Pro_ID IS NOT NULL AND @Pro_ID <> ''
    BEGIN
        -- SINGLE PRODUCT DETAIL MODE (Original behavior)
        
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
        -- PRODUCT LIST MODE
        
        -- Default Date range logic if needed, but here we'll just use the filters
        DECLARE @CalculatedToDate DATETIME = ISNULL(DATEADD(day, 1, @ToDate), '9999-12-31');

        SELECT 
            pr.Pro_ID,
            pr.Pro_Name,
            pr.BatchSize,
            pr.Pro_Entry_Date,
            (
                SELECT COUNT(mc.Pro_ID) 
                FROM M_Code mc 
                WHERE mc.Pro_ID = pr.Pro_ID 
                  AND (mc.ScrapeFlag IS NULL OR mc.ScrapeFlag = 0)
                  AND mc.Print_Status = 1
                  AND mc.Batch_No IS NULL
                  AND mc.DispatchFlag = 1
                  AND mc.ReceiveFlag = 1
            ) AS AvailableCodes,
            CASE 
                WHEN EXISTS (
                    SELECT 1 
                    FROM M_ServiceSubscription ss 
                    WHERE ss.Service_ID = 'SRV1018' 
                      AND ss.Pro_ID = pr.Pro_ID 
                      AND GETDATE() BETWEEN ss.DateFrom AND ss.DateTo
                ) THEN 1 
                ELSE 0 
            END AS IsCounterFittingServiceActive
        FROM Pro_Reg pr
        WHERE pr.Comp_ID = @Comp_ID
          AND (@Pro_Name IS NULL OR pr.Pro_Name LIKE '%' + @Pro_Name + '%')
          AND (@FromDate IS NULL OR pr.Pro_Entry_Date >= @FromDate)
          AND (pr.Pro_Entry_Date < @CalculatedToDate)
        ORDER BY pr.Pro_Entry_Date DESC;
    END
END
GO
