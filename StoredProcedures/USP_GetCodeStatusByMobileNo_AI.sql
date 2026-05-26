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
    WHERE RIGHT(PE.MobileNo, 10) = @NormalizedMobile
      AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));

    ---------------------------------------------------------
    -- Calculate Summary Counts
    ---------------------------------------------------------
    DECLARE @TotalScans BIGINT = (SELECT COUNT(*) FROM #FinalData);
    DECLARE @SuccessScans BIGINT = (SELECT COUNT(*) FROM #FinalData WHERE CodeStatus = 'Success');
    DECLARE @FailedScans BIGINT = (SELECT COUNT(*) FROM #FinalData WHERE CodeStatus = 'Unsuccess');

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
            @TotalScans AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(@TotalScans * 1.0 / @Limit) AS TotalPages;
    END

    ---------------------------------------------------------
    -- SUMMARY RESULT
    ---------------------------------------------------------
    IF (@Type IS NULL OR @Type = '' OR @Type = 'SUMMARY')
    BEGIN
        SELECT
            @MobileNo AS MobileNo,
            @TotalScans AS TotalScans,
            @SuccessScans AS SuccessScans,
            @FailedScans AS FailedScans;
    END
END
GO
