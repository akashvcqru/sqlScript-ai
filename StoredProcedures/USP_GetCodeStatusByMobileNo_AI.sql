SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-28
-- Description: Get code status details and summary for a specific mobile number
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeStatusByMobileNo_AI]
    @MobileNo NVARCHAR(15),
    @Comp_ID NVARCHAR(50),
    @Type NVARCHAR(20) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- Normalize flags & pagination
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);
    IF (@Page IS NULL OR @Page < 1) SET @Page = 1;
    IF (@Limit IS NULL OR @Limit < 1) SET @Limit = 10;
    IF (@Limit > 500) SET @Limit = 500;

    IF @Type IS NOT NULL
        SET @Type = UPPER(LTRIM(RTRIM(@Type)));

    ---------------------------------------------------------
    -- Normalize Mobile Number
    ---------------------------------------------------------
    DECLARE @NormalizedMobile NVARCHAR(10) = RIGHT(LTRIM(RTRIM(@MobileNo)), 10);

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
    WHERE pr.Comp_ID = @Comp_ID
      AND sst.IsActive = 1 AND sst.IsDelete = 0
      AND ss.IsActive = 1 AND ss.IsDelete = 0;

    ---------------------------------------------------------
    -- Final Data Temp Table
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#FinalData') IS NOT NULL DROP TABLE #FinalData;

    SELECT
        CASE WHEN PE.Is_Success = 1 THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
        CAST(CASE WHEN PE.Is_Success = 1 THEN ISNULL(sd.Points, 0) ELSE 0 END AS DECIMAL(18,2)) AS Points,
        ISNULL(sd.IsCash, 0) AS IsCash,
        PE.Enq_Date,
        ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '') AS UniqueCode,
        PE.MobileNo,
        ISNULL(PE.Dial_Mode, 'Web') AS Dial_Mode,
        pr.Pro_Name
    INTO #FinalData
    FROM Pro_Enq PE
    INNER JOIN M_Code mc 
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
    WHERE RIGHT(PE.MobileNo, 10) = @NormalizedMobile
      AND pr.Comp_ID = @Comp_ID;

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
        SELECT
            @MobileNo AS MobileNo,
            CAST(COUNT(*) AS INT) AS TotalScans,
            CAST(ISNULL(SUM(CASE WHEN CodeStatus = 'Success' THEN 1 ELSE 0 END), 0) AS INT) AS SuccessScans,
            CAST(ISNULL(SUM(CASE WHEN CodeStatus = 'Unsuccess' THEN 1 ELSE 0 END), 0) AS INT) AS FailedScans
        FROM #FinalData;
    END
END
GO
