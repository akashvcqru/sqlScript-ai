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
        SELECT Code1, Code2, Pro_ID, reassignProid, Series_Order, Series_Serial FROM M_Code WHERE @ActualCompId <> 'Comp-1693'
        UNION ALL
        SELECT Code1, Code2, Pro_ID, NULL AS reassignProid, Series_Order, Series_Serial FROM M_Code_PFL WHERE @ActualCompId = 'Comp-1693'
    ) mc
    WHERE (Pro_ID = @Pro_ID OR reassignProid = @Pro_ID)
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
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) ELSE ISNULL(sd.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN PE.Status = 'Authenticate' THEN
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) ELSE ISNULL(BL.Points, 0) END
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
        OUTER APPLY (
            SELECT TOP 1 
                BL.Points,
                BL.Cash
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK) 
            LEFT JOIN M_Consumer mc_user WITH (NOLOCK) 
                ON mc_user.M_Consumerid = BL.M_Consumerid
            WHERE BL.Code1 = PE.Code1V 
              AND BL.Code2 = PE.Code2V
              AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
              AND (
                  PE.MobileNo IS NULL 
                  OR mc_user.MobileNo = PE.MobileNo 
                  OR RIGHT(mc_user.MobileNo, 10) = RIGHT(PE.MobileNo, 10)
                  OR BL.M_Consumerid IS NULL
              )
            ORDER BY 
                CASE WHEN mc_user.MobileNo = PE.MobileNo OR RIGHT(mc_user.MobileNo, 10) = RIGHT(PE.MobileNo, 10) THEN 0 ELSE 1 END ASC,
                ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0) DESC,
                BL.BLoyalty_PointEarnedID DESC
        ) BL
        WHERE PE.Code1V = @RecievedCode1
          AND PE.Code2V = @RecievedCode2
          AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END
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
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(sd.IsCash, 0) ELSE ISNULL(sd.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS AssignPoint,
            CAST(CASE WHEN PE.Is_Success = 1 THEN
                CASE WHEN sd.Service_ID = 'SRV1005' THEN ISNULL(BL.Cash, 0) ELSE ISNULL(BL.Points, 0) END
            ELSE 0 END AS DECIMAL(18,2)) AS WornPoint
        FROM Pro_Enq PE WITH (NOLOCK)
        INNER JOIN M_Code mc WITH (NOLOCK)
            ON mc.Code1 = PE.Received_Code1
           AND mc.Code2 = PE.Received_Code2
        INNER JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = ISNULL(NULLIF(mc.reassignProid, ''), mc.Pro_ID)
        LEFT JOIN #temp1 sd 
            ON sd.Pro_ID = ISNULL(NULLIF(mc.reassignProid, ''), mc.Pro_ID)
           AND CONCAT(
                FORMAT(mc.Series_Order, '000#'),
                FORMAT(mc.Series_Serial, '000#')
               )
               BETWEEN 
               CONCAT(FORMAT(sd.start_order, '000#'), FORMAT(sd.start_series, '000#'))
               AND 
               CONCAT(FORMAT(sd.end_order, '000#'), FORMAT(sd.end_series, '000#'))
        OUTER APPLY (
            SELECT TOP 1 
                BL.Points,
                BL.Cash
            FROM BLoyaltyPointsEarned BL WITH (NOLOCK) 
            LEFT JOIN M_Consumer mc_user WITH (NOLOCK) 
                ON mc_user.M_Consumerid = BL.M_Consumerid
            WHERE BL.Code1 = PE.Received_Code1 
              AND BL.Code2 = PE.Received_Code2
              AND (BL.compid = @ActualCompId OR REPLACE(BL.compid, '-', '') = REPLACE(@ActualCompId, '-', ''))
              AND (
                  PE.MobileNo IS NULL 
                  OR mc_user.MobileNo = PE.MobileNo 
                  OR RIGHT(mc_user.MobileNo, 10) = RIGHT(PE.MobileNo, 10)
                  OR BL.M_Consumerid IS NULL
              )
            ORDER BY 
                CASE WHEN mc_user.MobileNo = PE.MobileNo OR RIGHT(mc_user.MobileNo, 10) = RIGHT(PE.MobileNo, 10) THEN 0 ELSE 1 END ASC,
                ISNULL(BL.Points, 0) + ISNULL(BL.Cash, 0) DESC,
                BL.BLoyalty_PointEarnedID DESC
        ) BL
        WHERE PE.Received_Code1 = @RecievedCode1
          AND PE.Received_Code2 = @RecievedCode2
          AND (pr.Comp_ID = @ActualCompId OR REPLACE(pr.Comp_ID, '-', '') = REPLACE(@ActualCompId, '-', ''));
    END

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
        IF @ActualCompId = 'Comp-1693'
        BEGIN
            SELECT TOP 1
                ISNULL(PE.Code1V, '') + ISNULL(PE.Code2V, '') AS ThirteenDigitCode,
                MS.ServiceName,
                ss.DateFrom AS ServiceAssignDate,
                ss.DateTo AS CodeExpiryDate,
                PE.Pro_Name AS Pro_Name,
                CASE WHEN MC.Use_Count >= 1 THEN 'Used' ELSE 'Un Used' END AS CodeCheckStatus,
                PE.Enq_Date,
                (SELECT COUNT(1) FROM pfl_codecheckData WHERE Code1V = @RecievedCode1 AND Code2V = @RecievedCode2) AS CodeCheckCount,
                CASE WHEN sst.IsActive = 1 AND ss.IsActive = 1 AND ss.IsDelete = 0 AND sst.IsDelete = 0 THEN 'Active' ELSE 'In Active' END AS CodeActiveStatus,
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
                AND CONCAT(
                    FORMAT(mc.Series_Order, '000#'),
                    FORMAT(mc.Series_Serial, '000#')
                )
                BETWEEN 
                CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
                AND 
                CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
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
                ss.DateTo AS CodeExpiryDate,
                pr.Pro_Name AS Pro_Name,
                CASE WHEN MC.Use_Count >= 1 THEN 'Used' ELSE 'Un Used' END AS CodeCheckStatus,
                PE.Enq_Date,
                (SELECT COUNT(1) FROM Pro_Enq WHERE Received_Code1 = @RecievedCode1 AND Received_Code2 = @RecievedCode2) AS CodeCheckCount,
                CASE WHEN sst.IsActive = 1 AND ss.IsActive = 1 AND ss.IsDelete = 0 AND sst.IsDelete = 0 THEN 'Active' ELSE 'In Active' END AS CodeActiveStatus,
                CASE WHEN sst.Points IS NULL OR sst.Points = 0 THEN CAST(sst.IsCash AS SQL_VARIANT) ELSE CAST(sst.Points AS SQL_VARIANT) END AS Points,
                ISNULL(NULLIF(mc.Batch_No, ''), 'Not Assigned') AS Batch_No
            FROM Pro_Enq PE WITH (NOLOCK)
            INNER JOIN M_Code mc WITH (NOLOCK)
                ON mc.Code1 = PE.Received_Code1
               AND mc.Code2 = PE.Received_Code2
            INNER JOIN Pro_Reg pr WITH (NOLOCK)
                ON pr.Pro_ID = ISNULL(NULLIF(mc.reassignProid, ''), mc.Pro_ID)      
            INNER JOIN M_ServiceSubscription ss WITH (NOLOCK)
                ON ss.Pro_ID = pr.Pro_ID
                AND CONCAT(
                    FORMAT(mc.Series_Order, '000#'),
                    FORMAT(mc.Series_Serial, '000#')
                )
                BETWEEN 
                CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#'))
                AND 
                CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
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
