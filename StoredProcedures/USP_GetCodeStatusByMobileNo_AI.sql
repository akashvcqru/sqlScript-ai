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
        WornPoint DECIMAL(18,2) NULL,
        Result VARCHAR(50) NULL
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
        -- 1. Enquiries
        IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

        SELECT 
            PE.Received_Code1,
            PE.Received_Code2,
            PE.Enq_Date,
            PE.Dial_Mode,
            PE.Is_Success,
            PE.MobileNo,
            PE.Latitude,
            PE.Longitude,
            PE.IsVerified,
            M.Row_ID AS M_Codeid,
            M.Series_Order,
            M.Series_Serial,
            M.Batch_No
        INTO #Enq
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_code M WITH (NOLOCK)
            ON PE.Received_Code1 = CAST(M.code1 AS VARCHAR(50))
           AND PE.Received_Code2 = CAST(M.Code2 AS VARCHAR(50))
        INNER JOIN Pro_Reg PR WITH (NOLOCK)
            ON PR.Pro_ID = M.Pro_ID
        WHERE (PR.Comp_ID = @ActualCompId OR REPLACE(PR.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))
          AND RIGHT(PE.MobileNo, 10) = @NormalizedMobile;

        IF OBJECT_ID('tempdb..#Codes') IS NOT NULL DROP TABLE #Codes;
        SELECT DISTINCT Received_Code1, Received_Code2 INTO #Codes FROM #Enq;

        IF OBJECT_ID('tempdb..#MCode') IS NOT NULL DROP TABLE #MCode;
        SELECT 
            MCd.Code1, MCd.Code2, MCd.Pro_ID, MCd.Series_Order, MCd.Series_Serial, MCd.Row_ID AS M_Codeid, MCd.Batch_No
        INTO #MCode
        FROM M_Code MCd WITH (NOLOCK)
        INNER JOIN #Codes C ON MCd.Code1 = C.Received_Code1 AND MCd.Code2 = C.Received_Code2;

        IF OBJECT_ID('tempdb..#Pro') IS NOT NULL DROP TABLE #Pro;
        SELECT Pro_ID, Pro_Name INTO #Pro FROM Pro_Reg WITH (NOLOCK) WHERE (Comp_ID = @ActualCompId OR REPLACE(Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));

        DECLARE @Multiplier DECIMAL(18,2) = 1.00;
        SELECT TOP 1 @Multiplier = 1.00 + (ISNULL(TRY_CAST(calculation_value AS DECIMAL(18,2)), 0.00) / 100.0) 
        FROM loyalty_calculation WITH (NOLOCK)
        WHERE (comp_id = @ActualCompId OR REPLACE(comp_id, '-', '') = REPLACE(@ActualCompId, '-', '')) AND isactive = 1 AND isdelete = 0;

        IF OBJECT_ID('tempdb..#Points') IS NOT NULL DROP TABLE #Points;
        SELECT
            MC.M_Codeid,
            MAX(CAST(
                CASE 
                    WHEN @ActualCompId = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2))) AS Points,
            MAX(CAST(
                CASE 
                    WHEN @ActualCompId = 'Comp-1274' THEN ISNULL(TRY_CAST(BL.Cash AS DECIMAL(18,2)), 0.00) * 1.10
                    WHEN BL.Cash IS NOT NULL AND TRY_CAST(BL.Cash AS DECIMAL(18,2)) > 0 THEN TRY_CAST(BL.Cash AS DECIMAL(18,2)) * @Multiplier
                    ELSE ISNULL(TRY_CAST(BL.Points AS DECIMAL(18,2)), 0.00)
                END 
            AS DECIMAL(18,2))) AS WornPoint
        INTO #Points
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN BuiltLoyaltyMCodeCheck BMC WITH (NOLOCK) ON BL.BuildLoyaltyOrReferralMCodeCheckid = BMC.Pkid
        INNER JOIN M_Consumer_M_Code MC WITH (NOLOCK) ON BMC.M_Consumer_MCOdeid = MC.M_Consumer_MCodeid
        INNER JOIN #MCode M WITH (NOLOCK) ON MC.M_Codeid = M.M_Codeid
        INNER JOIN Pro_Reg PR WITH (NOLOCK) ON M.Pro_ID = PR.Pro_ID
        WHERE BL.compid = @ActualCompId OR BL.compid IS NULL
        GROUP BY MC.M_Codeid;

        IF OBJECT_ID('tempdb..#CodeConfigPoints') IS NOT NULL DROP TABLE #CodeConfigPoints;
        WITH RankedConfig AS (
            SELECT 
                MC.M_Codeid, SS.Service_ID, SST.Frequency,
                CAST(CASE WHEN SST.Points IS NULL OR SST.Points = 0 THEN ISNULL(SST.IsCash, 0) ELSE SST.Points END AS DECIMAL(18,2)) AS ConfigPoints,
                CAST(CASE WHEN SS.Service_ID = 'SRV1005' THEN ISNULL(SST.IsCash, 0) ELSE ISNULL(SST.Points, 0) END AS DECIMAL(18,2)) AS AssignPoint,
                ROW_NUMBER() OVER (PARTITION BY MC.M_Codeid, SS.Service_ID ORDER BY SST.Entry_Date DESC, SST.SST_Id DESC) AS rn_service,
                SST.Entry_Date, SST.SST_Id
            FROM #MCode MC
            INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = MC.Pro_ID
            INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
            WHERE (SS.Comp_ID = @ActualCompId OR REPLACE(SS.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))
              AND SS.IsActive = 1 AND SS.IsDelete = 0 AND SST.IsActive = 1 AND SST.IsDelete = 0
              AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
              AND (MC.Series_Order > SS.start_order OR (MC.Series_Order = SS.start_order AND MC.Series_Serial >= SS.start_series))
              AND (MC.Series_Order < SS.end_order OR (MC.Series_Order = SS.end_order AND MC.Series_Serial <= SS.end_series))
        ),
        UniqueServiceConfig AS ( SELECT * FROM RankedConfig WHERE rn_service = 1 ),
        FinalRankedConfig AS (
            SELECT M_Codeid, Frequency, ConfigPoints, AssignPoint,
                ROW_NUMBER() OVER (PARTITION BY M_Codeid ORDER BY Entry_Date DESC, SST_Id DESC) AS rn_final
            FROM UniqueServiceConfig
        )
        SELECT M_Codeid, Frequency, ConfigPoints, AssignPoint INTO #CodeConfigPoints FROM FinalRankedConfig WHERE rn_final = 1;

        -- Insert Scan Enquiries
        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint, Result)
        SELECT 
            CASE 
                WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN 'Success'
                ELSE 'Unsuccess'
            END AS CodeStatus,
            CASE 
                WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN 
                    CASE WHEN ISNULL(P.Points, 0) > 0 THEN P.Points ELSE ISNULL(CP.ConfigPoints, 0) END
                ELSE 0 
            END AS Points,
            0 AS IsCash,
            E.Enq_Date,
            (E.Received_Code1 + E.Received_Code2) AS UniqueCode,
            MC.MobileNo,
            E.Dial_Mode,
            PR.Pro_Name,
            MCd.Batch_No,
            ISNULL(E.IsVerified, 0) AS ImageVerified,
            CASE WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN ISNULL(CP.AssignPoint, 0) ELSE 0 END AS AssignPoint,
            CASE WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN 
                CASE WHEN ISNULL(P.WornPoint, 0) > 0 THEN P.WornPoint ELSE ISNULL(CP.ConfigPoints, 0) END
            ELSE 0 END AS WornPoint,
            CASE 
                WHEN E.Is_Success = 1 AND E.rn <= ISNULL(CP.Frequency, 1) THEN 'Verified'
                WHEN E.Is_Success = 2 OR (E.Is_Success = 1 AND E.rn > ISNULL(CP.Frequency, 1)) THEN 'Already Scanned'
                ELSE 'Invalid'
            END AS Result
        FROM
        (
            SELECT *,
                   CASE WHEN Is_Success = 1 
                        THEN ROW_NUMBER() OVER (PARTITION BY Received_Code1, Received_Code2, Is_Success ORDER BY Enq_Date)
                        ELSE 1 END AS rn
            FROM #Enq
        ) E
        LEFT JOIN M_Consumer MC WITH (NOLOCK) ON MC.MobileNo = E.MobileNo AND MC.IsDelete = '0'
        LEFT JOIN #Points P ON P.M_Codeid = E.M_Codeid
        LEFT JOIN #MCode MCd ON MCd.M_Codeid = E.M_Codeid
        LEFT JOIN #Pro PR ON PR.Pro_ID = MCd.Pro_ID
        LEFT JOIN #CodeConfigPoints CP ON CP.M_Codeid = E.M_Codeid
        WHERE (E.Is_Success != 1 OR E.rn <= ISNULL(CP.Frequency, 1));

        -- Insert Referrals
        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint, Result)
        SELECT 
            'Success' AS CodeStatus,
            0 AS Points,
            0 AS IsCash,
            BL.UpdateDate AS Enq_Date,
            '' AS UniqueCode,
            MC.MobileNo,
            '' AS Dial_Mode,
            'Referral Bonus' AS Pro_Name,
            '' AS Batch_No,
            0 AS ImageVerified,
            0 AS AssignPoint,
            0 AS WornPoint,
            'Referral Point' AS Result
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
        WHERE (LOWER(BL.ServiceName) = 'refral' OR LOWER(BL.ServiceName) = 'referral')
          AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          AND BL.Code1 IS NULL
          AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
          AND RIGHT(MC.MobileNo, 10) = @NormalizedMobile;

        -- Insert Other Earn Points
        INSERT INTO #FinalData (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, Pro_Name, Batch_No, ImageVerified, AssignPoint, WornPoint, Result)
        SELECT 
            'Success' AS CodeStatus,
            SUM(CAST(CASE WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier ELSE ISNULL(BL.Points, 0) END AS DECIMAL(18,2))) AS Points,
            0 AS IsCash,
            BL.UpdateDate AS Enq_Date,
            '' AS UniqueCode,
            MC.MobileNo,
            '' AS Dial_Mode,
            ISNULL(NULLIF(BL.ServiceName, ''), 'Bonus Point') AS Pro_Name,
            '' AS Batch_No,
            0 AS ImageVerified,
            0 AS AssignPoint,
            SUM(CAST(CASE WHEN BL.Cash IS NOT NULL AND BL.Cash > 0 THEN BL.Cash * @Multiplier ELSE ISNULL(BL.Points, 0) END AS DECIMAL(18,2))) AS WornPoint,
            CASE 
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%kyc%' THEN 'KYC Point'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%invoice%' THEN 'Invoice Point'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%refral%' OR LOWER(ISNULL(BL.ServiceName, '')) LIKE '%referral%' THEN 'Referral Point'
                WHEN LOWER(ISNULL(BL.ServiceName, '')) LIKE '%bonus%' THEN 'Bonus Point'
                WHEN LTRIM(RTRIM(ISNULL(BL.ServiceName, ''))) <> '' THEN BL.ServiceName + ' Point'
                ELSE 'Bonus Point'
            END AS Result
        FROM BLoyaltyPointsEarned BL WITH (NOLOCK)
        INNER JOIN M_Consumer MC ON BL.M_Consumerid = MC.M_Consumerid AND MC.IsDelete = 0
        WHERE (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
          AND BL.BuildLoyaltyOrReferralMCodeCheckid IS NULL
          AND LOWER(ISNULL(BL.ServiceName, '')) NOT IN ('refral', 'referral')
          AND RIGHT(MC.MobileNo, 10) = @NormalizedMobile
        GROUP BY BL.M_Consumerid, MC.MobileNo, BL.UpdateDate, BL.ServiceName;
    END

    ---------------------------------------------------------
    -- Calculate Summary Counts
    ---------------------------------------------------------
    DECLARE @TotalScans BIGINT = (SELECT COUNT(*) FROM #FinalData);
    DECLARE @SuccessScans BIGINT = (SELECT COUNT(*) FROM #FinalData WHERE Result = 'Verified' OR (CodeStatus = 'Success' AND UniqueCode <> ''));
    DECLARE @FailedScans BIGINT = (SELECT COUNT(*) FROM #FinalData WHERE CodeStatus = 'Unsuccess' OR Result IN ('Already Scanned', 'Invalid'));

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
