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
        ss.end_series,
        ss.Service_ID
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

    CREATE TABLE #FinalData (
        CodeStatus VARCHAR(20),
        Points DECIMAL(18,2),
        IsCash INT,
        Enq_Date DATETIME,
        UniqueCode VARCHAR(100),
        MobileNo VARCHAR(50),
        Dial_Mode VARCHAR(50),
        Pro_Name NVARCHAR(200),
        Batch_No NVARCHAR(100),
        ImageVerified INT,
        AssignPoint DECIMAL(18,2) NULL,
        WornPoint DECIMAL(18,2) NULL
    );

    IF @ActualCompId = 'Comp-1693'
    BEGIN
        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint)
        SELECT
            CASE WHEN PE.Status = 'Authenticate' THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
            CAST(CASE WHEN PE.Status = 'Authenticate' THEN 
                CASE 
                    WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0)
                    ELSE CASE WHEN sd.Points IS NULL OR sd.Points = 0 THEN ISNULL(sd.IsCash, 0) ELSE sd.Points END
                END
            ELSE 0 END AS DECIMAL(18,2)) AS Points,
            ISNULL(sd.IsCash, 0) AS IsCash,
            PE.Enq_Date,
            ISNULL(PE.Code1V, '') + ISNULL(PE.Code2V, '') AS UniqueCode,
            PE.MobileNo,
            ISNULL(PE.Dial_Mode, 'Web') AS Dial_Mode,
            PE.Pro_Name,
            PE.Batch_No,
            ISNULL(PE.IsVerified, 0) AS ImageVerified,
            CAST(CASE WHEN PE.Status = 'Authenticate' THEN
                CASE 
                    WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) 
                    ELSE CASE WHEN sd.Points IS NULL OR sd.Points = 0 THEN ISNULL(sd.IsCash, 0) ELSE sd.Points END
                END
            ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN PE.Status = 'Authenticate' THEN
                CASE 
                    WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) 
                    ELSE CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END
                END
            ELSE 0 END AS DECIMAL(18,2)) AS WornPoint
        FROM pfl_codecheckData PE WITH (NOLOCK)
        INNER JOIN M_Code_PFL mc WITH (NOLOCK)
            ON mc.Code1 = PE.Code1V
           AND mc.Code2 = PE.Code2V
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
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
        LEFT JOIN M_Consumer mc_c WITH (NOLOCK) ON RIGHT(mc_c.MobileNo, 10) = RIGHT(PE.MobileNo, 10) AND mc_c.IsDelete = 0
        LEFT JOIN BLoyaltyPointsEarned BL WITH (NOLOCK) 
            ON BL.Code1 = PE.Code1V 
           AND BL.Code2 = PE.Code2V
           AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', '') OR BL.compid IS NULL)
           AND BL.M_Consumerid = mc_c.M_Consumerid
        WHERE RIGHT(PE.MobileNo, 10) = @NormalizedMobile
          AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END
    ELSE IF @ActualCompId = 'Comp-1152'
    BEGIN
        DECLARE @IsSBUTeam INT = 0;
        IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_ID AND SubCompTypeType = 'SBUTEAM')
        BEGIN
            SET @IsSBUTeam = 1;
        END

        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint)
        SELECT 
            CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint
        FROM (
            SELECT
                CASE WHEN pc.Is_Success = 1 THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
                CAST(CASE WHEN pc.Is_Success = 1 THEN 
                    CASE 
                        WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0)
                        ELSE CASE WHEN pc.Points IS NULL OR pc.Points = 0 THEN ISNULL(pc.Cash, 0) ELSE pc.Points END
                    END
                ELSE 0 END AS DECIMAL(18,2)) AS Points,
                ISNULL(pc.Cash, 0) AS IsCash,
                pc.Enq_Date,
                ISNULL(pc.Code1, '') + ISNULL(pc.Code2, '') AS UniqueCode,
                pc.MobileNo,
                ISNULL(pc.Dial_Mode, 'Web') AS Dial_Mode,
                ISNULL(NULLIF(pc.Pro_Name, ''), pr.Pro_Name) AS Pro_Name,
                mcd.Batch_No,
                0 AS ImageVerified,
                CAST(CASE WHEN pc.Is_Success = 1 THEN
                    CASE 
                        WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) 
                        ELSE CASE WHEN sd.Points IS NULL OR sd.Points = 0 THEN ISNULL(sd.IsCash, 0) ELSE sd.Points END
                    END
                ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
                CAST(CASE WHEN pc.Is_Success = 1 THEN
                    CASE 
                        WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) 
                        ELSE CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END
                    END
                ELSE 0 END AS DECIMAL(18,2)) AS WornPoint,
                ROW_NUMBER() OVER (
                    PARTITION BY pc.Code1, pc.Code2
                    ORDER BY pc.Enq_Date DESC
                ) AS rn
            FROM dbo.ConsumerPointsCashDetails pc WITH (NOLOCK)
            LEFT JOIN dbo.UserData_MHCroneJob mc WITH (NOLOCK) ON mc.m_consumerid = pc.m_consumerid
            LEFT JOIN dbo.M_Code mcd WITH (NOLOCK) ON mcd.Code1 = pc.Code1 AND mcd.Code2 = pc.Code2
            LEFT JOIN dbo.Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = mcd.Pro_ID
            LEFT JOIN #temp1 sd 
                ON sd.Pro_ID = mcd.Pro_Id
               AND CONCAT(
                    FORMAT(mcd.Series_Order, '000#'),
                    FORMAT(mcd.Series_Serial, '000#')
                   )
                   BETWEEN 
                   CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#'))
                   AND 
                   CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
            LEFT JOIN BLoyaltyPointsEarned BL WITH (NOLOCK) 
                ON BL.Code1 = pc.Code1 
               AND BL.Code2 = pc.Code2
               AND (BL.compid = @ActualCompId OR BL.compid IS NULL)
               AND BL.M_Consumerid = pc.m_consumerid
            WHERE RIGHT(pc.MobileNo, 10) = @NormalizedMobile
              AND pc.Comp_Id = @ActualCompId
              AND (
                  (@IsSBUTeam = 0 AND (pc.distributedid <> 'SBUTEAM' OR pc.distributedid IS NULL) AND (mc.DealerCode <> 'SBUTEAM' OR mc.DealerCode IS NULL)) OR
                  (@IsSBUTeam = 1 AND (pc.distributedid = 'SBUTEAM' OR mc.DealerCode = 'SBUTEAM'))
              )
        ) x
        WHERE x.rn = 1;
    END
    -- (ELSE OTHER COMPANIES)
    ELSE
    BEGIN
        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint)
        SELECT
            CASE WHEN PE.Is_Success = 1 THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
            CAST(CASE WHEN PE.Is_Success = 1 THEN 
                CASE 
                    WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0)
                    ELSE CASE WHEN sd.Points IS NULL OR sd.Points = 0 THEN ISNULL(sd.IsCash, 0) ELSE sd.Points END
                END
            ELSE 0 END AS DECIMAL(18,2)) AS Points,
            ISNULL(sd.IsCash, 0) AS IsCash,
            PE.Enq_Date,
            ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '') AS UniqueCode,
            PE.MobileNo,
            ISNULL(PE.Dial_Mode, 'Web') AS Dial_Mode,
            pr.Pro_Name,
            mc.Batch_No,
            ISNULL(PE.IsVerified, 0) AS ImageVerified,
            CAST(CASE WHEN PE.Is_Success = 1 THEN
                CASE 
                    WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) 
                    ELSE CASE WHEN sd.Points IS NULL OR sd.Points = 0 THEN ISNULL(sd.IsCash, 0) ELSE sd.Points END
                END
            ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN PE.Is_Success = 1 THEN
                CASE 
                    WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) 
                    ELSE CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END
                END
            ELSE 0 END AS DECIMAL(18,2)) AS WornPoint
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code mc WITH (NOLOCK)
            ON mc.Code1 = PE.Received_Code1
           AND mc.Code2 = PE.Received_Code2
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
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
        LEFT JOIN M_Consumer mc_c WITH (NOLOCK) ON RIGHT(mc_c.MobileNo, 10) = RIGHT(PE.MobileNo, 10) AND mc_c.IsDelete = 0
        LEFT JOIN BLoyaltyPointsEarned BL WITH (NOLOCK) 
            ON BL.Code1 = PE.Received_Code1 
           AND BL.Code2 = PE.Received_Code2
           AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', '') OR BL.compid IS NULL)
           AND BL.M_Consumerid = mc_c.M_Consumerid
        WHERE RIGHT(PE.MobileNo, 10) = @NormalizedMobile
          AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END

    ---------------------------------------------------------
    -- INSERT REFERRAL RECORDS
    ---------------------------------------------------------
    DECLARE @TargetConsumerid INT = NULL;
    SELECT TOP 1 @TargetConsumerid = M_Consumerid FROM M_Consumer WHERE RIGHT(MobileNo, 10) = @NormalizedMobile AND IsDelete = 0 ORDER BY M_Consumerid DESC;

    IF @TargetConsumerid IS NOT NULL
    BEGIN
        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint)
        SELECT 
            'Referral' AS CodeStatus,
            CAST(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS DECIMAL(18,2)) AS Points,
            CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN 1 ELSE 0 END AS IsCash,
            BL.UpdateDate AS Enq_Date,
            ISNULL(BL.Code1, '') + ISNULL(BL.Code2, '') AS UniqueCode,
            ISNULL(MC.MobileNo, '') AS MobileNo, -- Scanned by referred user
            'Referral' AS Dial_Mode,
            ISNULL(PR.Pro_Name, 'Referral Bonus') AS Pro_Name,
            '' AS Batch_No,
            0 AS ImageVerified,
            CAST(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN BL.Points IS NULL OR BL.Points = 0 THEN ISNULL(BL.Cash, 0) ELSE BL.Points END AS DECIMAL(18,2)) AS WornPoint
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        LEFT JOIN M_Consumer MC ON BL.refranceM_Consumerid = MC.M_Consumerid
        LEFT JOIN M_Code MCD ON MCD.Code1 = BL.Code1 AND MCD.Code2 = BL.Code2
        LEFT JOIN Pro_Reg PR ON PR.Pro_ID = MCD.Pro_ID
        WHERE BL.M_Consumerid = @TargetConsumerid
          AND (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
          AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END

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
