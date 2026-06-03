USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec USP_GetHighestCounterfeitActivities_AI 'Comp-1599','QUARTER'
CREATE OR ALTER PROCEDURE [dbo].[USP_GetHighestCounterfeitActivities_AI]
(
    @Comp_Id VARCHAR(20),
    @datePreset  NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Date Window
    ------------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YESTERDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'WEEK'
    BEGIN
        SET DATEFIRST 1; -- Monday
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
        SET @EndDate   = @ThisMonthStart;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTYEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today), 1, 1);
    END
    ELSE IF @Win = 'ALL'
    BEGIN
        SET @StartDate = '19000101';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    ------------------------------------------------------
    -- 1. Build ValidStates (Geo + latest matching Pro_Enq per row)
    ------------------------------------------------------
    ;WITH GeoApply AS
    (
        SELECT
            G.Comp_Id AS G_Comp_Id,
            P.Comp_Id AS P_Comp_Id,
            G.MobileNo AS G_MobileNo,
            P.MobileNo AS P_MobileNo,
            LEFT(G.Latitude,6) AS G_Latitude,
            LEFT(G.Longitude,6) AS G_Longitude,
            LEFT(P.Latitude,6) AS P_Latitude,
            LEFT(P.Longitude,6) AS P_Longitude,
            P.Is_Success,
            G.Code1 AS G_Code1,
            P.Received_Code1 AS P_Code1,
            G.Code2 AS G_Code2,
            P.Received_Code2 AS P_Code2,
            G.Postcode,
            G.State,
            G.City,
            G.StateDistrict,
            G.Town,
            G.Suburb,
            G.Enq_Date,
            ROW_NUMBER() OVER
            (
                PARTITION BY RIGHT(G.MobileNo,10), Code1, Code2, G.Enq_Date
                ORDER BY G.Enq_Date DESC
            ) AS rn
        FROM GeoLocationData G WITH (NOLOCK)
        OUTER APPLY
        (
            SELECT TOP 1 *
            FROM Pro_Enq P WITH (NOLOCK)
            WHERE P.Comp_Id = G.Comp_Id
              AND P.Received_Code1 = G.Code1
              AND P.Received_Code2 = G.Code2
              AND P.MobileNo = G.MobileNo
              AND P.Enq_Date >= @StartDate
        ) P
        WHERE 
            G.Comp_Id = @Comp_Id
            AND G.Enq_Date >= @StartDate
            AND ISNULL(G.State,'') <> ''
            AND LEN(LTRIM(RTRIM(G.State))) >= 2
    ),
    ValidStates AS
    (
        SELECT *
        FROM GeoApply
        WHERE rn = 1
    ),

    ------------------------------------------------------
    -- 2. Build ValidScans
    ------------------------------------------------------
    ValidScans AS
    (
        SELECT
            MobileNo = RIGHT(pe.MobileNo,10),
            pe.Is_Success,
            mc.Use_Count,
            ROW_NUMBER() OVER
            (
                PARTITION BY RIGHT(pe.MobileNo,10)
                ORDER BY pe.Enq_Date DESC
            ) AS rn
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_Code mc 
            ON pe.Received_Code1 = CAST(mc.Code1 AS NVARCHAR(20)) 
           AND pe.Received_Code2 = CAST(mc.Code2 AS NVARCHAR(20))
        INNER JOIN Pro_Reg pr 
            ON pr.Pro_ID = mc.Pro_ID
           AND pr.Comp_ID = @Comp_Id
        WHERE pe.Comp_ID = @Comp_Id
          AND pe.Enq_Date >= @StartDate
          AND @Comp_Id <> 'Comp-1693'

        UNION ALL

        SELECT
            MobileNo = RIGHT(pe.MobileNo,10),
            pe.Is_Success,
            mc.Use_Count,
            ROW_NUMBER() OVER
            (
                PARTITION BY RIGHT(pe.MobileNo,10)
                ORDER BY pe.Enq_Date DESC
            ) AS rn
        FROM Pro_Enq pe WITH (NOLOCK)
        INNER JOIN M_Code_PFL mc 
            ON pe.Received_Code1 = CAST(mc.Code1 AS NVARCHAR(20)) 
           AND pe.Received_Code2 = CAST(mc.Code2 AS NVARCHAR(20))
        INNER JOIN Pro_Reg pr 
            ON pr.Pro_ID = mc.Pro_ID
           AND pr.Comp_ID = @Comp_Id
        WHERE pe.Comp_ID = @Comp_Id
          AND pe.Enq_Date >= @StartDate
          AND @Comp_Id = 'Comp-1693'
    ),
    CleanScans AS
    (
        SELECT MobileNo, Is_Success, Use_Count
        FROM ValidScans
        WHERE rn = 1
    )

    ------------------------------------------------------
    -- 3. Final Aggregation
    ------------------------------------------------------
    SELECT
        CASE 
            WHEN LEN(LTRIM(RTRIM(VS.State))) < 3 THEN 'NA'
            ELSE VS.State
        END AS StateName,
        SUM(CASE WHEN S.Use_Count = 1 AND S.Is_Success = 1 THEN 1 ELSE 0 END) AS SuccessScans,
        SUM(CASE WHEN S.Is_Success <> 1 THEN 1 ELSE 0 END) AS FailedScans,
        COUNT(*) AS TotalScans
    FROM ValidStates VS
    LEFT JOIN CleanScans S
        ON RIGHT(VS.P_MobileNo,10) = S.MobileNo
    GROUP BY VS.State
    ORDER BY VS.State;
END
GO
