SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-28
-- Description: Get code status details and summary for a specific serial number
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeStatusBySerialNumber_AI]
    @Pro_ID VARCHAR(6),
    @Series_Order INT,
    @Series_Serial INT,
    @Comp_ID NVARCHAR(50),
    @Type NVARCHAR(20) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(50) = @Comp_ID;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_ID)
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_ID;
    END

    ---------------------------------------------------------
    -- Normalize flags & pagination
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);
    IF (@Page IS NULL OR @Page < 1) SET @Page = 1;
    IF (@Limit IS NULL OR @Limit < 1) SET @Limit = 10;
    IF (@Limit > 500) SET @Limit = 500;

    IF @Type IS NOT NULL
        SET @Type = UPPER(LTRIM(RTRIM(@Type)));

    DECLARE @RecievedCode1 NVARCHAR(10);
    DECLARE @RecievedCode2 NVARCHAR(10);

    SELECT 
        @RecievedCode1 = Code1, 
        @RecievedCode2 = Code2 
    FROM (
        SELECT Code1, Code2, Pro_ID, Series_Order, Series_Serial FROM M_Code WHERE @ActualCompId <> 'Comp-1693'
        UNION ALL
        SELECT Code1, Code2, Pro_ID, Series_Order, Series_Serial FROM M_Code_PFL WHERE @ActualCompId = 'Comp-1693'
    ) mc
    WHERE Pro_ID = @Pro_ID 
      AND Series_Order = @Series_Order 
      AND Series_Serial = @Series_Serial;

    ---------------------------------------------------------
    -- Subscription Temp Table
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1;

    SELECT 
        sst.SST_Id,
        sst.Points,
        sst.IsCash,
        ss.Pro_ID,
        ss.start_order,
        ss.start_series,
        ss.end_order,
        ss.end_series
    INTO #temp1
    FROM M_ServiceSubscriptionTrans sst
    INNER JOIN M_ServiceSubscription ss 
        ON sst.Subscribe_Id = ss.Subscribe_Id
    INNER JOIN Pro_Reg pr 
        ON pr.Pro_id = ss.Pro_ID
    WHERE (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))
      AND sst.IsActive = 1 AND sst.IsDelete = 0
      AND ss.IsActive = 1 AND ss.IsDelete = 0;

    ---------------------------------------------------------
    -- Final Data Temp Table
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalData') IS NOT NULL DROP TABLE #FinalData;

    SELECT
        CASE WHEN PE.Is_Success = 1 THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
        CAST(CASE WHEN PE.Is_Success = 1 THEN CASE WHEN sd.Points IS NULL OR sd.Points = 0 THEN ISNULL(sd.IsCash, 0) ELSE sd.Points END ELSE 0 END AS DECIMAL(18,2)) AS Points,
        ISNULL(sd.IsCash, 0) AS IsCash,
        PE.Enq_Date,
        ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '') AS UniqueCode,
        PE.MobileNo,
        ISNULL(PE.Dial_Mode, 'Web') AS Dial_Mode,
        pr.Pro_Name
    INTO #FinalData
    FROM Pro_Enq PE
    INNER JOIN (
        SELECT Pro_ID, Code1, Code2, Series_Order, Series_Serial, Use_Count FROM M_Code WHERE @ActualCompId <> 'Comp-1693'
        UNION ALL
        SELECT Pro_ID, Code1, Code2, Series_Order, Series_Serial, Use_Count FROM M_Code_PFL WHERE @ActualCompId = 'Comp-1693'
    ) mc 
        ON mc.Code1 = PE.Received_Code1
       AND mc.Code2 = PE.Received_Code2
    INNER JOIN Pro_Reg pr 
        ON pr.Pro_ID = mc.Pro_ID
    LEFT JOIN #temp1 sd 
        ON sd.Pro_ID = mc.Pro_Id
       AND CONCAT(
            FORMAT(mc.Series_Order, '000#'),
            FORMAT(mc.Series_Serial, '000#')
           )
           BETWEEN 
           CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#'))
           AND 
           CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
    WHERE PE.Received_Code1 = @RecievedCode1
      AND PE.Received_Code2 = @RecievedCode2
      AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));

    ---------------------------------------------------------
    -- DETAILS RESULT
    ---------------------------------------------------------
    IF (@Type IS NULL OR @Type = '' OR @Type = 'DETAILS')
    BEGIN
        IF (@IsExport = 1)
        BEGIN
            SELECT *
            FROM #FinalData
            ORDER BY Enq_Date DESC;
        END
        ELSE
        BEGIN
            DECLARE @Offset INT = (@Page - 1) * @Limit;

            SELECT *
            FROM #FinalData
            ORDER BY Enq_Date DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
        END
    END

    ---------------------------------------------------------
    -- META RESULT
    ---------------------------------------------------------
    IF (@IsExport = 0 AND (@Type IS NULL OR @Type = '' OR @Type = 'DETAILS'))
    BEGIN
        SELECT
            COUNT(*) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(*) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData;
    END

    ---------------------------------------------------------
    -- SUMMARY RESULT
    ---------------------------------------------------------
    IF (@Type IS NULL OR @Type = '' OR @Type = 'SUMMARY')
    BEGIN
        SELECT TOP 1
            ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '') AS ThirteenDigitCode,
            MS.ServiceName,
            ss.DateFrom AS ServiceAssignDate,
            ss.DateTo AS CodeExpiryDate,
            pr.Pro_Name,
            CASE WHEN MC.Use_Count >= 1 THEN 'Used' ELSE 'Un Used' END AS CodeCheckStatus,
            PE.Enq_Date,
            (SELECT COUNT(1) FROM Pro_Enq WHERE Received_Code1 = @RecievedCode1 AND Received_Code2 = @RecievedCode2) AS CodeCheckCount,
            CASE WHEN sst.IsActive = 1 AND ss.IsActive = 1 AND ss.IsDelete = 0 AND sst.IsDelete = 0 THEN 'Active' ELSE 'In Active' END AS CodeActiveStatus,
            CASE WHEN sst.Points IS NULL OR sst.Points = 0 THEN CAST(sst.IsCash AS SQL_VARIANT) ELSE CAST(sst.Points AS SQL_VARIANT) END AS Points
        FROM Pro_Enq PE
        INNER JOIN (
            SELECT Pro_ID, Code1, Code2, Series_Order, Series_Serial, Use_Count FROM M_Code WHERE @ActualCompId <> 'Comp-1693'
            UNION ALL
            SELECT Pro_ID, Code1, Code2, Series_Order, Series_Serial, Use_Count FROM M_Code_PFL WHERE @ActualCompId = 'Comp-1693'
        ) mc 
            ON mc.Code1 = PE.Received_Code1
           AND mc.Code2 = PE.Received_Code2
        INNER JOIN Pro_Reg pr 
            ON pr.Pro_ID = mc.Pro_ID      
        INNER JOIN M_ServiceSubscription ss 
            ON ss.Pro_ID = pr.Pro_ID
            AND CONCAT(
                FORMAT(mc.Series_Order, '000#'),
                FORMAT(mc.Series_Serial, '000#')
            )
            BETWEEN 
            CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
            AND 
            CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
        LEFT JOIN M_ServiceSubscriptionTrans sst
            ON sst.Subscribe_Id = ss.Subscribe_Id
        INNER JOIN M_Service MS 
            ON MS.Service_ID = ss.Service_ID
        WHERE PE.Received_Code1 = @RecievedCode1
          AND PE.Received_Code2 = @RecievedCode2
          AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))       
        ORDER BY PE.Enq_Date DESC;
    END
END
GO
