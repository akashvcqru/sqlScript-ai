USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_GetNewUsersAndKYCOverview_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_GetNewUsersAndKYCOverview_AI]
(
    @CompId NVARCHAR(50),
    @datePreset NVARCHAR(20)=NULL
)
AS
BEGIN
     SET NOCOUNT ON;

    DECLARE 
        @Today DATE = CAST(GETDATE() AS DATE),
        @StartDate DATE,
        @EndDate DATE,
        @TotalUsers INT,
        @Bucket1Start INT, @Bucket1End INT,
        @Bucket2Start INT, @Bucket2End INT,
        @Bucket3Start INT,
        @Label1 NVARCHAR(50), @Label2 NVARCHAR(50), @Label3 NVARCHAR(50);

        SET DATEFIRST 1;
        DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

        SET @StartDate =
CASE 
    WHEN @Win = 'TODAY' THEN @Today
    WHEN @Win = 'YESTERDAY' THEN DATEADD(DAY, -1, @Today)
    WHEN @Win = 'WEEK' THEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today)
    WHEN @Win = 'LASTWEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0)
    WHEN @Win = 'MONTH' THEN DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)
    WHEN @Win = 'LASTMONTH' THEN DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1))
    WHEN @Win = 'QUARTER' THEN DATEADD(DAY, -90, @Today)
    WHEN @Win = 'YEAR' THEN DATEFROMPARTS(YEAR(@Today), 1, 1)
    WHEN @Win = 'LASTYEAR' THEN DATEFROMPARTS(YEAR(@Today) - 1, 1, 1)
    ELSE DATEADD(DAY, -7, @Today)
END;

SET @EndDate =
CASE
    WHEN @Win = 'MONTH' THEN DATEADD(DAY, 1, @Today)
    WHEN @Win = 'LASTMONTH' THEN DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1)
    WHEN @Win = 'YEAR' THEN DATEADD(DAY, 1, @Today)
    WHEN @Win = 'LASTYEAR' THEN DATEFROMPARTS(YEAR(@Today), 1, 1)
    ELSE DATEADD(DAY, 1, @Today)
END;

    ---------------------------
    --  Determine buckets/labels
    ---------------------------
    IF @Win = 'WEEK'
    BEGIN
        SET @Bucket1Start = 0; SET @Bucket1End = 2;
        SET @Bucket2Start = 3; SET @Bucket2End = 7;
        SET @Bucket3Start = 8;
        SET @Label1 = '0-2 Days'; SET @Label2 = '3-7 Days'; SET @Label3 = '>7 Days';
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @Bucket1Start = 0; SET @Bucket1End = 15;
        SET @Bucket2Start = 16; SET @Bucket2End = 30;
        SET @Bucket3Start = 31;
        SET @Label1 = '0-15 Days'; SET @Label2 = '16-30 Days'; SET @Label3 = '>30 Days';
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @Bucket1Start = 0; SET @Bucket1End = 30;
        SET @Bucket2Start = 31; SET @Bucket2End = 60;
        SET @Bucket3Start = 61;
        SET @Label1 = '0-30 Days'; SET @Label2 = '31-60 Days'; SET @Label3 = '>60 Days';
    END
    ELSE IF @Win = 'YEAR' OR @Win = 'LASTYEAR'
    BEGIN
        SET @Bucket1Start = 0; SET @Bucket1End = 90;
        SET @Bucket2Start = 91; SET @Bucket2End = 180;
        SET @Bucket3Start = 181;
        SET @Label1 = '0-3 Months'; SET @Label2 = '3-6 Months'; SET @Label3 = '>6 Months';
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET @Bucket1Start = 0; SET @Bucket1End = 1;
        SET @Bucket2Start = 2; SET @Bucket2End = 4;
        SET @Bucket3Start = 5;
        SET @Label1 = '0-1 Days'; SET @Label2 = '2-4 Days'; SET @Label3 = '5-7 Days';
    END
    ELSE
    BEGIN
        SET @Bucket1Start = 0; SET @Bucket1End = 2;
        SET @Bucket2Start = 3; SET @Bucket2End = 7;
        SET @Bucket3Start = 8;
        SET @Label1 = '0-2 Days'; SET @Label2 = '3-7 Days'; SET @Label3 = '>7 Days';
    END

   SELECT @TotalUsers = COUNT(VC.M_consumerId)
   FROM M_Consumer AS MC WITH (NOLOCK)
   INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId=MC.M_Consumerid
   WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0

    ----------------------------------------------------------------
    -- 4️⃣ SOURCE CTE (FILTERED BY TIMEWINDOW)
    ----------------------------------------------------------------
    ;WITH Source AS
    (
        SELECT
            VC.M_consumerId,
            VC.VRKbl_KYC_status,
            VC.Entry_date
        FROM M_Consumer AS MC WITH (NOLOCK)
        INNER JOIN tbl_Vendorvisekycstatus AS VC WITH (NOLOCK) ON VC.M_consumerId=MC.M_Consumerid
        WHERE VC.Comp_ID = @CompId AND MC.IsDelete=0
          AND CAST(VC.Entry_date AS DATE) BETWEEN @StartDate AND @EndDate
    ),
    ----------------------------------------------------------------
    -- 5️⃣ METRICS BASED PURELY ON TIMEWINDOW
    ----------------------------------------------------------------
    Aggregated AS
    (
        SELECT
            COUNT(M_consumerId) AS NewUsers,
            SUM(CASE WHEN VRKbl_KYC_status = 1 THEN 1 ELSE 0 END) AS KYCApproved,
            SUM(CASE WHEN VRKbl_KYC_status = 2 THEN 1 ELSE 0 END) AS KYCRejected,
            SUM(CASE WHEN VRKbl_KYC_status = 0 OR VRKbl_KYC_status IS NULL THEN 1 ELSE 0 END) AS KYCPending,
            COUNT(M_consumerId) AS TotalRows
        FROM Source 
    ),
    ----------------------------------------------------------------
    -- 6️⃣ PENDING KYC - AGING BUCKETS
    ----------------------------------------------------------------
    PendingAging AS
    (
        SELECT
            SUM(CASE WHEN DATEDIFF(DAY, Entry_date, GETDATE()) BETWEEN @Bucket1Start AND @Bucket1End THEN 1 ELSE 0 END) AS Bucket1Count,
            SUM(CASE WHEN DATEDIFF(DAY, Entry_date, GETDATE()) BETWEEN @Bucket2Start AND @Bucket2End THEN 1 ELSE 0 END) AS Bucket2Count,
            SUM(CASE WHEN DATEDIFF(DAY, Entry_date, GETDATE()) >= @Bucket3Start THEN 1 ELSE 0 END) AS Bucket3Count
        FROM Source
        WHERE VRKbl_KYC_status = 0 OR VRKbl_KYC_status IS NULL
    )
    ----------------------------------------------------------------
    -- 7️⃣ FINAL RESULT
    ----------------------------------------------------------------
    SELECT
        A.NewUsers,
        @TotalUsers AS TotalUsers,
        A.KYCApproved,
        CAST(
            CASE WHEN A.TotalRows = 0 THEN 0
                 ELSE ROUND((A.KYCApproved * 100.0) / A.TotalRows, 2)
            END AS DECIMAL(5,2)
        ) AS KYCApprovedPct,
        A.KYCPending,
        CAST(
            CASE WHEN A.TotalRows = 0 THEN 0
                 ELSE ROUND((A.KYCPending * 100.0) / A.TotalRows, 2)
            END AS DECIMAL(5,2)
        ) AS KYCPendingPct,
        A.KYCRejected,
        CAST(
            CASE WHEN A.TotalRows = 0 THEN 0
                 ELSE ROUND((A.KYCRejected * 100.0) / A.TotalRows, 2)
            END AS DECIMAL(5,2)
        ) AS KYCRejectedPct,
        @Label1 AS Bucket1Label, PA.Bucket1Count,
        @Label2 AS Bucket2Label, PA.Bucket2Count,
        @Label3 AS Bucket3Label, PA.Bucket3Count
    FROM Aggregated A, PendingAging PA;
END
