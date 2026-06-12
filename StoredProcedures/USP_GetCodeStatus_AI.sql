SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      AI
-- Create date: 2026-04-02
-- Description: Get code status details and summary for a specific company
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetCodeStatus_AI]
    @RecievedCode1 NVARCHAR(10),
    @RecievedCode2 NVARCHAR(10),
    @Comp_ID NVARCHAR(50), 
    @Type NVARCHAR(20) = NULL ,  -- DETAILS | SUMMARY | NULL
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

    DECLARE @Series_Order INT = 0;
    DECLARE @Series_Serial INT = 0;
    DECLARE @Pro_ID VARCHAR(50) = '';

    IF @ActualCompId = 'Comp-1693'
    BEGIN
        SELECT TOP 1 
            @Pro_ID = Pro_ID, 
            @Series_Order = Series_Order, 
            @Series_Serial = Series_Serial 
        FROM M_Code_PFL 
        WHERE Code1 = @RecievedCode1 AND Code2 = @RecievedCode2;
    END
    ELSE
    BEGIN
        SELECT TOP 1 
            @Pro_ID = Pro_ID, 
            @Series_Order = Series_Order, 
            @Series_Serial = Series_Serial 
        FROM M_Code 
        WHERE Code1 = @RecievedCode1 AND Code2 = @RecievedCode2;
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
    -- Subscription Temp Table
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1;

    WITH RankedTrans AS (
        SELECT 
            sst.SST_Id,
            sst.Points,
            sst.IsCash,
            sst.Frequency,
            ss.Service_ID,
            ss.Pro_ID,
            sst.Entry_Date,
            ROW_NUMBER() OVER (
                PARTITION BY ss.Service_ID 
                ORDER BY sst.Entry_Date DESC, sst.SST_Id DESC
            ) AS rn_service
        FROM M_ServiceSubscriptionTrans sst WITH (NOLOCK)
        INNER JOIN M_ServiceSubscription ss WITH (NOLOCK)
            ON sst.Subscribe_Id = ss.Subscribe_Id
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_id = ss.Pro_ID
        WHERE (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))
          AND sst.IsActive = 1 AND sst.IsDelete = 0
          AND ss.IsActive = 1 AND ss.IsDelete = 0
          AND ss.Pro_ID = @Pro_ID
          AND (ss.start_order IS NULL OR @Series_Order > ss.start_order OR (@Series_Order = ss.start_order AND @Series_Serial >= ss.start_series))
          AND (ss.end_order IS NULL OR @Series_Order < ss.end_order OR (@Series_Order = ss.end_order AND @Series_Serial <= ss.end_series))
    ),
    UniqueServiceTrans AS (
        SELECT * 
        FROM RankedTrans 
        WHERE rn_service = 1
    ),
    FinalRankedTrans AS (
        SELECT 
            Points,
            IsCash,
            Frequency,
            Service_ID,
            ROW_NUMBER() OVER (
                ORDER BY Entry_Date DESC, SST_Id DESC
            ) AS rn_final
        FROM UniqueServiceTrans
    )
    SELECT 
        Points,
        IsCash,
        Frequency,
        Service_ID
    INTO #temp1
    FROM FinalRankedTrans
    WHERE rn_final = 1;

    -------------------------------------------------
    ---------------------------------------------------------
    -- Get ExpireCodeDate & CodeServiceSetingStatus
    ---------------------------------------------------------
    DECLARE @ExpireCodeDate DATETIME = NULL;
    DECLARE @CodeServiceSetingStatus VARCHAR(20) = 'Deactive';

    IF @Pro_ID IS NOT NULL AND @Pro_ID <> ''
    BEGIN
        SELECT TOP 1
            @ExpireCodeDate = ISNULL(sst.DateTo, ss.DateTo),
            @CodeServiceSetingStatus = CASE 
                WHEN ss.IsActive = 1 AND ss.IsAdminVerify = 1 AND ss.IsDelete = 0 
                     AND sst.IsActive = 1 AND sst.IsDelete = 0 
                THEN 'Active' 
                ELSE 'Deactive' 
            END
        FROM M_ServiceSubscription ss WITH (NOLOCK)
        LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK) 
            ON sst.Subscribe_Id = ss.Subscribe_Id
        WHERE ss.Pro_ID = @Pro_ID
          AND (ss.start_order IS NULL OR @Series_Order > ss.start_order OR (@Series_Order = ss.start_order AND @Series_Serial >= ss.start_series))
          AND (ss.end_order IS NULL OR @Series_Order < ss.end_order OR (@Series_Order = ss.end_order AND @Series_Serial <= ss.end_series))
        ORDER BY ss.EntryDate DESC, sst.SST_Id DESC;
    END

    -------------------------------------------------
    -- Code Status Temp
    -------------------------------------------------
    IF OBJECT_ID('tempdb..#CodeStatus') IS NOT NULL DROP TABLE #CodeStatus;

    CREATE TABLE #CodeStatus (
        CodeStatus VARCHAR(20),
        Points DECIMAL(18,2),
        IsCash INT,
        Enq_Date DATETIME,
        UniqueCode VARCHAR(100),
        MobileNo VARCHAR(50),
        Dial_Mode VARCHAR(50),
        ExpireCodeDate DATETIME,
        CodeServiceSetingStatus VARCHAR(20),
        ImageVerified INT,
        Pro_Name NVARCHAR(200),
        Batch_No NVARCHAR(100),
        AssignPoint DECIMAL(18,2) NULL,
        WornPoint DECIMAL(18,2) NULL
    );

    IF @ActualCompId = 'Comp-1693'
    BEGIN
        INSERT INTO #CodeStatus (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, ExpireCodeDate, CodeServiceSetingStatus, ImageVerified, Pro_Name, Batch_No, AssignPoint, WornPoint)
        SELECT
            CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
            CAST(CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 
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
            @ExpireCodeDate AS ExpireCodeDate,
            @CodeServiceSetingStatus AS CodeServiceSetingStatus,
            ISNULL(PE.IsVerified, 0) AS ImageVerified,
            PE.Pro_Name,
            PE.Batch_No,
            CAST(CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) ELSE ISNULL(sd.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) ELSE ISNULL(BL.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS WornPoint
        FROM (
            SELECT 
                Code1V AS Received_Code1,
                Code2V AS Received_Code2,
                CASE WHEN Status = 'Authenticate' THEN 1 WHEN Status = 'Re-Authenticate' THEN 2 ELSE 0 END AS Is_Success,
                Enq_Date,
                MobileNo,
                Dial_Mode,
                IsVerified,
                Pro_Name,
                Batch_No,
                ROW_NUMBER() OVER (
                    PARTITION BY Code1V, Code2V, CASE WHEN Status = 'Authenticate' THEN 1 WHEN Status = 'Re-Authenticate' THEN 2 ELSE 0 END 
                    ORDER BY Enq_Date ASC
                ) AS Success_Rn
            FROM pfl_codecheckData WITH (NOLOCK)
            WHERE Code1V = @RecievedCode1
              AND Code2V = @RecievedCode2
        ) PE
        INNER JOIN M_Code_PFL mc WITH (NOLOCK)
            ON mc.Code1 = PE.Received_Code1
           AND mc.Code2 = PE.Received_Code2
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = mc.Pro_ID
        LEFT JOIN #temp1 sd 
            ON 1 = 1
        LEFT JOIN BLoyaltyPointsEarned BL WITH (NOLOCK) 
            ON BL.Code1 = PE.Received_Code1 
           AND BL.Code2 = PE.Received_Code2
           AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
        WHERE (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END
    ELSE
    BEGIN
        INSERT INTO #CodeStatus (CodeStatus, Points, IsCash, Enq_Date, UniqueCode, MobileNo, Dial_Mode, ExpireCodeDate, CodeServiceSetingStatus, ImageVerified, Pro_Name, Batch_No, AssignPoint, WornPoint)
        SELECT
            CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 'Success' ELSE 'Unsuccess' END AS CodeStatus,
            CAST(CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN 
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
            @ExpireCodeDate AS ExpireCodeDate,
            @CodeServiceSetingStatus AS CodeServiceSetingStatus,
            ISNULL(PE.IsVerified, 0) AS ImageVerified,
            pr.Pro_Name,
            mc.Batch_No,
            CAST(CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) ELSE ISNULL(sd.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN PE.Is_Success = 1 AND PE.Success_Rn <= ISNULL(sd.Frequency, 1) THEN
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) ELSE ISNULL(BL.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS WornPoint
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY Received_Code1, Received_Code2, Is_Success 
                       ORDER BY Enq_Date ASC
                   ) AS Success_Rn
            FROM Pro_Enq WITH (NOLOCK)
            WHERE Received_Code1 = @RecievedCode1
              AND Received_Code2 = @RecievedCode2
        ) PE
        INNER JOIN M_Code mc WITH (NOLOCK)
            ON mc.Code1 = PE.Received_Code1
           AND mc.Code2 = PE.Received_Code2
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = mc.Pro_ID
        LEFT JOIN #temp1 sd 
            ON 1 = 1
        LEFT JOIN BLoyaltyPointsEarned BL WITH (NOLOCK) 
            ON BL.Code1 = PE.Received_Code1 
           AND BL.Code2 = PE.Received_Code2
           AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
        WHERE (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END

    ---------------------------------------------------------
    -- DETAILS RESULT
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
    -- PAGINATION META
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
    -- SUMMARY RESULT
    ---------------------------------------------------------
    IF (@Type IS NULL OR @Type = '' OR @Type = 'SUMMARY')
    BEGIN
        IF @ActualCompId = 'Comp-1693'
        BEGIN
            SELECT TOP 1
                ISNULL(PE.Code1V, '') + ISNULL(PE.Code2V, '') AS ThirteenDigitCode,
                MS.ServiceName,
                ss.DateFrom AS ServiceAssignDate,
                @ExpireCodeDate AS CodeExpiryDate,
                PE.Pro_Name AS Pro_Name,
                CASE WHEN MC.Use_Count >= 1 THEN 'Used' ELSE 'Un Used' END AS CodeCheckStatus,
                PE.Enq_Date,
                (SELECT COUNT(1) FROM pfl_codecheckData WHERE Code1V = @RecievedCode1 AND Code2V = @RecievedCode2) AS CodeCheckCount,
                @CodeServiceSetingStatus AS CodeActiveStatus,
                CASE WHEN sst.Points IS NULL OR sst.Points = 0 THEN CAST(sst.IsCash AS SQL_VARIANT) ELSE CAST(sst.Points AS SQL_VARIANT) END AS Points,
                ISNULL(NULLIF(PE.Batch_No, ''), 'Not Assigned') AS Batch_No
            FROM pfl_codecheckData PE WITH (NOLOCK)
            INNER JOIN M_Code_PFL mc WITH (NOLOCK)
                ON mc.Code1 = PE.Code1V
               AND mc.Code2 = PE.Code2V
            INNER JOIN Pro_Reg pr WITH (NOLOCK)
                ON pr.Pro_ID = mc.Pro_ID      
            INNER JOIN M_ServiceSubscription ss WITH (NOLOCK)
                ON ss.Pro_ID = pr.Pro_ID
                AND (
                    ss.start_order IS NULL OR
                    CONCAT(
                        FORMAT(mc.Series_Order, '000#'),
                        FORMAT(mc.Series_Serial, '000#')
                    )
                    BETWEEN 
                    CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
                    AND 
                    CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
                )
            LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK)
                ON sst.Subscribe_Id = ss.Subscribe_Id
            INNER JOIN M_Service MS WITH (NOLOCK)
                ON MS.Service_ID = ss.Service_ID
            WHERE PE.Code1V = @RecievedCode1
              AND PE.Code2V = @RecievedCode2
              AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))
            ORDER BY PE.Enq_Date DESC;
        END
        ELSE
        BEGIN
            SELECT TOP 1
                ISNULL(PE.Received_Code1, '') + ISNULL(PE.Received_Code2, '') AS ThirteenDigitCode,
                MS.ServiceName,
                ss.DateFrom AS ServiceAssignDate,
                @ExpireCodeDate AS CodeExpiryDate,
                pr.Pro_Name AS Pro_Name,
                CASE WHEN MC.Use_Count >= 1 THEN 'Used' ELSE 'Un Used' END AS CodeCheckStatus,
                PE.Enq_Date,
                (SELECT COUNT(1) FROM Pro_Enq WHERE Received_Code1 = @RecievedCode1 AND Received_Code2 = @RecievedCode2) AS CodeCheckCount,
                @CodeServiceSetingStatus AS CodeActiveStatus,
                CASE WHEN sst.Points IS NULL OR sst.Points = 0 THEN CAST(sst.IsCash AS SQL_VARIANT) ELSE CAST(sst.Points AS SQL_VARIANT) END AS Points,
                ISNULL(NULLIF(mc.Batch_No, ''), 'Not Assigned') AS Batch_No
            FROM Pro_Enq PE WITH (NOLOCK)
            INNER JOIN M_Code mc WITH (NOLOCK)
                ON mc.Code1 = PE.Received_Code1
               AND mc.Code2 = PE.Received_Code2
            INNER JOIN Pro_Reg pr WITH (NOLOCK)
                ON pr.Pro_ID = mc.Pro_ID      
            INNER JOIN M_ServiceSubscription ss WITH (NOLOCK)
                ON ss.Pro_ID = pr.Pro_ID
                AND (
                    ss.start_order IS NULL OR
                    CONCAT(
                        FORMAT(mc.Series_Order, '000#'),
                        FORMAT(mc.Series_Serial, '000#')
                    )
                    BETWEEN 
                    CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
                    AND 
                    CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
                )
            LEFT JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK)
                ON sst.Subscribe_Id = ss.Subscribe_Id
            INNER JOIN M_Service MS WITH (NOLOCK)
                ON MS.Service_ID = ss.Service_ID
            WHERE PE.Received_Code1 = @RecievedCode1
              AND PE.Received_Code2 = @RecievedCode2
              AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''))
            ORDER BY PE.Enq_Date DESC;
        END
    END
END
GO
