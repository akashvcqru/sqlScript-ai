SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Updated:     2026-09-17 (Shrunk & Aligned with SP_BL_GetCodesActivityReport_AI frequency logic)
-- Description: Get code status details and summary for a specific company with strict frequency enforcement
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeStatus_AI]
    @RecievedCode1 NVARCHAR(10),
    @RecievedCode2 NVARCHAR(10),
    @Comp_ID NVARCHAR(50), 
    @Type NVARCHAR(20) = NULL,  -- DETAILS | SUMMARY | NULL
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1. SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(50) = @Comp_ID;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_ID)
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_ID;
    END

    ---------------------------------------------------------
    -- 2. Normalize flags & pagination
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);
    IF (@Page IS NULL OR @Page < 1) SET @Page = 1;
    IF (@Limit IS NULL OR @Limit < 1) SET @Limit = 10;
    IF (@Limit > 500) SET @Limit = 500;

    IF @Type IS NOT NULL
        SET @Type = UPPER(LTRIM(RTRIM(@Type)));

    ---------------------------------------------------------
    -- 3. Code & Product Info (Unified Standard + PFL)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeInfo') IS NOT NULL DROP TABLE #CodeInfo;

    SELECT 
        mc.Code1,
        mc.Code2,
        pr.Pro_ID,
        pr.Pro_Name,
        mc.Series_Order,
        mc.Series_Serial,
        ISNULL(NULLIF(mc.Batch_No, ''), 'Not Assigned') AS Batch_No,
        ISNULL(mc.Use_Count, 0) AS Use_Count
    INTO #CodeInfo
    FROM (
        SELECT 
            Code1, Code2, 
            CASE WHEN @ActualCompId = 'Comp-1693' THEN Pro_ID ELSE ISNULL(NULLIF(reassignProid, ''), Pro_ID) END AS Pro_ID,
            Series_Order, Series_Serial, Batch_No, ISNULL(Use_Count, 0) AS Use_Count
        FROM M_Code WITH (NOLOCK) 
        WHERE @ActualCompId <> 'Comp-1693' AND Code1 = @RecievedCode1 AND Code2 = @RecievedCode2
        UNION ALL
        SELECT 
            Code1, Code2, Pro_ID, Series_Order, Series_Serial, Batch_No, ISNULL(Use_Count, 0) AS Use_Count
        FROM M_Code_PFL WITH (NOLOCK) 
        WHERE @ActualCompId = 'Comp-1693' AND Code1 = @RecievedCode1 AND Code2 = @RecievedCode2
    ) mc
    INNER JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mc.Pro_ID
    WHERE (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));

    ---------------------------------------------------------
    -- 4. Subscription Temp Table (Aggregated across active services)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1;

    ;WITH RankedTrans AS (
        SELECT 
            ISNULL(sst.Points, 0) AS Points,
            ISNULL(sst.IsCash, 0) AS IsCash,
            ISNULL(sst.Frequency, 1) AS Frequency,
            ss.Service_ID,
            ms.ServiceName,
            ss.DateFrom,
            ISNULL(sst.DateTo, ss.DateTo) AS DateTo,
            ROW_NUMBER() OVER (
                PARTITION BY ss.Service_ID 
                ORDER BY sst.Entry_Date DESC, sst.SST_Id DESC
            ) AS rn_service
        FROM #CodeInfo ci
        INNER JOIN M_ServiceSubscription ss WITH (NOLOCK) ON ss.Pro_ID = ci.Pro_ID
        LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) 
            ON sst.Subscribe_Id = ss.Subscribe_Id AND sst.IsActive = 1 AND sst.IsDelete = 0
        INNER JOIN M_Service ms WITH (NOLOCK) ON ms.Service_ID = ss.Service_ID
        WHERE ss.IsActive = 1 AND ss.IsDelete = 0
          AND (ss.start_order IS NULL OR ci.Series_Order > ss.start_order OR (ci.Series_Order = ss.start_order AND ci.Series_Serial >= ss.start_series))
          AND (ss.end_order IS NULL OR ci.Series_Order < ss.end_order OR (ci.Series_Order = ss.end_order AND ci.Series_Serial <= ss.end_series))
    )
    SELECT 
        MAX(CASE WHEN Service_ID = 'SRV1001' OR Points > 0 THEN ISNULL(Points, 0) ELSE 0 END) AS Points,
        MAX(CASE WHEN Service_ID IN ('SRV1028', 'SRV1005', 'SRV1029') OR IsCash > 0 THEN ISNULL(IsCash, 0) ELSE 0 END) AS IsCash,
        ISNULL(MAX(Frequency), 1) AS Frequency,
        STRING_AGG(Service_ID, ', ') AS Service_ID,
        STRING_AGG(ServiceName, ' + ') AS ServiceName,
        MIN(DateFrom) AS ServiceAssignDate,
        MAX(DateTo) AS ExpireCodeDate,
        CASE WHEN COUNT(1) > 0 THEN 'Active' ELSE 'Deactive' END AS CodeServiceSetingStatus
    INTO #temp1
    FROM RankedTrans
    WHERE rn_service = 1;

    ---------------------------------------------------------
    -- 5. Raw Enquiries with Scan Ranking (Unified Standard + PFL)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#RawEnq') IS NOT NULL DROP TABLE #RawEnq;

    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        PE.Enq_Date,
        PE.MobileNo,
        ISNULL(PE.Dial_Mode, 'Web') AS Dial_Mode,
        ISNULL(PE.IsVerified, 0) AS ImageVerified,
        PE.Is_Success,
        ROW_NUMBER() OVER (
            PARTITION BY PE.Received_Code1, PE.Received_Code2, PE.Is_Success 
            ORDER BY PE.Enq_Date ASC
        ) AS Success_Rn
    INTO #RawEnq
    FROM (
        SELECT 
            Received_Code1, Received_Code2, Enq_Date, MobileNo, Dial_Mode, IsVerified, Is_Success
        FROM Pro_Enq WITH (NOLOCK)
        WHERE @ActualCompId <> 'Comp-1693' AND Received_Code1 = @RecievedCode1 AND Received_Code2 = @RecievedCode2
        UNION ALL
        SELECT 
            Code1V AS Received_Code1, Code2V AS Received_Code2, Enq_Date, MobileNo, Dial_Mode, IsVerified,
            CASE WHEN Status = 'Authenticate' THEN 1 WHEN Status = 'Re-Authenticate' THEN 2 ELSE 0 END AS Is_Success
        FROM pfl_codecheckData WITH (NOLOCK)
        WHERE @ActualCompId = 'Comp-1693' AND Code1V = @RecievedCode1 AND Code2V = @RecievedCode2
    ) PE;

    ---------------------------------------------------------
    -- 6. Code Status Details with Strict Frequency Logic
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeStatus') IS NOT NULL DROP TABLE #CodeStatus;

    SELECT
        CASE 
            WHEN CHARINDEX('SRV1018', ISNULL(sd.Service_ID, '')) > 0 THEN
                CASE 
                    WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 'Authenticate'
                    WHEN PE.Is_Success = 2 OR (PE.Is_Success = 1 AND PE.Success_Rn > ISNULL(sd.Frequency, 1)) THEN 'Re-Authenticate'
                    ELSE 'Unsuccess'
                END
            ELSE
                CASE 
                    WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 'Success' 
                    ELSE 'Unsuccess' 
                END
        END AS CodeStatus,
        CAST(
            CASE 
                WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 
                    CASE 
                        WHEN ISNULL(BL.WornCash, 0) > 0 THEN BL.WornCash
                        WHEN ISNULL(BL.WornPoints, 0) > 0 THEN BL.WornPoints
                        WHEN ISNULL(sd.Points, 0) > 0 THEN sd.Points
                        ELSE ISNULL(sd.IsCash, 0)
                    END
                ELSE 0 
            END AS DECIMAL(18,2)
        ) AS Points,
        ISNULL(sd.IsCash, 0) AS IsCash,
        PE.Enq_Date,
        ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '') AS UniqueCode,
        PE.MobileNo,
        PE.Dial_Mode,
        sd.ExpireCodeDate,
        ISNULL(sd.CodeServiceSetingStatus, 'Deactive') AS CodeServiceSetingStatus,
        PE.ImageVerified,
        ci.Pro_Name,
        ci.Batch_No,
        CAST(
            CASE 
                WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN
                    CASE 
                        WHEN ISNULL(BL.WornCash, 0) > 0 THEN ISNULL(sd.IsCash, BL.WornCash)
                        WHEN ISNULL(BL.WornPoints, 0) > 0 THEN ISNULL(sd.Points, BL.WornPoints)
                        WHEN ISNULL(sd.Points, 0) > 0 THEN sd.Points
                        ELSE ISNULL(sd.IsCash, 0)
                    END
                ELSE 0 
            END AS DECIMAL(18,2)
        ) AS AssignPoint,
        CAST(
            CASE 
                WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN
                    CASE 
                        WHEN ISNULL(BL.WornCash, 0) > 0 THEN BL.WornCash
                        WHEN ISNULL(BL.WornPoints, 0) > 0 THEN BL.WornPoints
                        ELSE 0
                    END
                ELSE 0 
            END AS DECIMAL(18,2)
        ) AS WornPoint
    INTO #CodeStatus
    FROM #RawEnq PE
    CROSS JOIN #CodeInfo ci
    LEFT JOIN #temp1 sd ON 1 = 1
    OUTER APPLY (
        SELECT 
            ISNULL(SUM(BL.Points), 0) AS WornPoints,
            ISNULL(SUM(BL.Cash), 0)   AS WornCash
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK) 
        LEFT JOIN M_Consumer mc_user WITH (NOLOCK) ON mc_user.M_Consumerid = BL.M_Consumerid
        WHERE BL.Code1 = PE.Received_Code1 
          AND BL.Code2 = PE.Received_Code2
          AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
          AND (
              PE.MobileNo IS NULL 
              OR mc_user.MobileNo = PE.MobileNo 
              OR RIGHT(mc_user.MobileNo, 10) = RIGHT(PE.MobileNo, 10)
              OR BL.M_Consumerid IS NULL
          )
    ) BL;

    ---------------------------------------------------------
    -- 7. DETAILS RESULT
    ---------------------------------------------------------
    IF (@Type IS NULL OR @Type = '' OR @Type = 'DETAILS')
    BEGIN
        IF (@IsExport = 1)
        BEGIN
            SELECT *
            FROM #CodeStatus
            ORDER BY Enq_Date DESC;
        END
        ELSE
        BEGIN
            DECLARE @Offset INT = (@Page - 1) * @Limit;

            SELECT *
            FROM #CodeStatus
            ORDER BY Enq_Date DESC
            OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
        END
    END

    ---------------------------------------------------------
    -- 8. PAGINATION META
    ---------------------------------------------------------
    IF (@IsExport = 0 AND (@Type IS NULL OR @Type = '' OR @Type = 'DETAILS'))
    BEGIN
        SELECT
            COUNT(1) AS TotalRecords,
            @Page  AS CurrentPage,
            @Limit AS [Limit],
            CAST(CEILING(COUNT(1) * 1.0 / @Limit) AS INT) AS TotalPages
        FROM #CodeStatus;
    END

    ---------------------------------------------------------
    -- 9. SUMMARY RESULT
    ---------------------------------------------------------
    IF (@Type IS NULL OR @Type = '' OR @Type = 'SUMMARY')
    BEGIN
        SELECT TOP 1
            CONCAT(ci.Code1, ci.Code2) AS ThirteenDigitCode,
            ISNULL(sd.ServiceName, 'Build Loyalty') AS ServiceName,
            sd.Service_ID AS Service_ID,
            sd.ServiceAssignDate AS ServiceAssignDate,
            sd.ExpireCodeDate AS CodeExpiryDate,
            ci.Pro_Name AS Pro_Name,
            CASE WHEN ci.Use_Count >= 1 THEN 'Used' ELSE 'Un Used' END AS CodeCheckStatus,
            (SELECT MAX(Enq_Date) FROM #RawEnq) AS Enq_Date,
            (SELECT COUNT(1) FROM #RawEnq) AS CodeCheckCount,
            ISNULL(sd.CodeServiceSetingStatus, 'Deactive') AS CodeActiveStatus,
            CASE 
                WHEN ISNULL(sd.Points, 0) > 0 THEN CAST(sd.Points AS SQL_VARIANT) 
                ELSE CAST(ISNULL(sd.IsCash, 0) AS SQL_VARIANT) 
            END AS Points,
            ci.Batch_No AS Batch_No
        FROM #CodeInfo ci
        LEFT JOIN #temp1 sd ON 1 = 1;
    END
END
GO
