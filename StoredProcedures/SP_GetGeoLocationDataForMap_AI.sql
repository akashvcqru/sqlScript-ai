SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[SP_GetGeoLocationDataForMap_AI] 'Comp-1555',null,'MONTH',null,null,'Web'
ALTER PROCEDURE [dbo].[SP_GetGeoLocationDataForMap_AI]
    @Comp_Id VARCHAR(50),	
    @ServiceID VARCHAR(50) = NULL,
    @datePreset VARCHAR(50) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTERMONTH, QUARTER, YEAR, LASTYEAR, ALL
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @Dial_Mode VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize ServiceID
    IF (
           @ServiceID IS NULL
        OR LTRIM(RTRIM(@ServiceID)) = ''
        OR LOWER(LTRIM(RTRIM(@ServiceID))) = 'null'
    )
        SET @ServiceID = NULL;

    -- Normalize Dial_Mode
    IF (
           @Dial_Mode IS NULL
        OR LTRIM(RTRIM(@Dial_Mode)) = ''
        OR LOWER(LTRIM(RTRIM(@Dial_Mode))) = 'null'
        OR LOWER(LTRIM(RTRIM(@Dial_Mode))) = 'all'
    )
        SET @Dial_Mode = NULL;

    DECLARE @CleanDialMode VARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@Dial_Mode, ''))));
    IF @CleanDialMode = '' SET @CleanDialMode = NULL;

    ---------------------------------------------------------
    -- Normalize datePreset (NULL = ALL DATA)
    ---------------------------------------------------------
    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    ---------------------------------------------------------
    -- Date Range Calculation
    ---------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = ISNULL(Reg_Date, '2015-01-01') FROM Comp_Reg WHERE Comp_ID = @Comp_Id AND Status = 1;

    DECLARE @StartDate DATETIME = NULL;
    DECLARE @EndDate   DATETIME = NULL;

    -- Explicit date range has highest priority
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE IF (@datePreset IS NOT NULL)
    BEGIN
        SET DATEFIRST 1; -- Monday

        IF (@datePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTDAY' OR @datePreset = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@datePreset = 'WEEK') -- Current week (Mon → Today)
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTWEEK') -- Previous full week
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'MONTH') -- Current month
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTMONTH') -- Previous month
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'QUARTER') -- Previous quarter
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
        END
        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        END
        ELSE IF (@datePreset = 'ALL')
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END
    
    IF (@StartDate IS NULL AND @EndDate IS NULL)
    BEGIN
        -- ALL DATA fallback
        SET @StartDate = CAST(@CompanyStartDate AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END

    ---------------------------------------------------------
    -- FINAL RESULT
    ---------------------------------------------------------
    IF (@Comp_Id = 'Comp-1152' AND @ServiceID = 'SRV1018') -- AC
    BEGIN
        SELECT  
            COALESCE(NULLIF(LTRIM(RTRIM(G.Latitude)), ''), P.Latitude) AS Latitude,
            COALESCE(NULLIF(LTRIM(RTRIM(G.Longitude)), ''), P.Longitude) AS Longitude,
            P.MobileNo,
            P.Enq_Date,
            CONCAT(P.Received_Code1, P.Received_Code2) AS UniqueCode,
            CASE 
                WHEN P.Is_Success = '1' THEN 'Authenticate'
                WHEN P.Is_Success = '2' THEN 'Re-Authenticate'
                ELSE 'Invalid'
            END AS UniqueCodeStatus,
            P.Dial_Mode
        FROM Pro_Enq P WITH (NOLOCK)
        INNER JOIN M_Code MC WITH (NOLOCK)
            ON MC.Code1 = P.Received_Code1 
           AND MC.Code2 = P.Received_Code2
        LEFT JOIN GeoLocationData G WITH (NOLOCK)
            ON G.Code1 = P.Received_Code1 
           AND G.Code2 = P.Received_Code2
           AND G.Comp_Id = P.Comp_ID
        WHERE
            P.Comp_Id = @Comp_Id
            AND MC.Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WITH (NOLOCK) WHERE Pro_Name LIKE 'AC_%')
            AND (
                (P.Latitude IS NOT NULL AND LTRIM(RTRIM(P.Latitude)) NOT IN ('', '0', '0.0', 'undefined', 'null'))
                OR
                (G.Latitude IS NOT NULL AND LTRIM(RTRIM(G.Latitude)) NOT IN ('', '0', '0.0', 'undefined', 'null'))
            )
            AND (
                @CleanDialMode IS NULL
                OR (
                    CASE 
                        WHEN @CleanDialMode = 'QR CODE' AND (UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%QR%' OR UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%SCAN%') THEN 1
                        WHEN @CleanDialMode = 'WEB' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%WEB%' THEN 1
                        WHEN @CleanDialMode = 'SMS' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%SMS%' THEN 1
                        WHEN @CleanDialMode = 'APP' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%APP%' THEN 1
                        WHEN @CleanDialMode = 'IVR' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%IVR%' THEN 1
                        WHEN @CleanDialMode = 'WHATSAPP' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%WHATSAPP%' THEN 1
                        ELSE 0
                    END = 1
                )
            )
            AND (@StartDate IS NULL OR P.Enq_Date >= @StartDate)
            AND (@EndDate   IS NULL OR P.Enq_Date <  @EndDate);
    END
    ELSE IF (@Comp_Id = 'Comp-1152' AND @ServiceID IS NOT NULL AND @ServiceID <> 'SRV1018') -- Bloyalty
    BEGIN
        ;WITH CTE AS
        (
            SELECT  
                COALESCE(NULLIF(LTRIM(RTRIM(G.Latitude)), ''), P.Latitude) AS Latitude,
                COALESCE(NULLIF(LTRIM(RTRIM(G.Longitude)), ''), P.Longitude) AS Longitude,
                P.MobileNo,
                P.Enq_Date,
                CONCAT(P.Received_Code1, P.Received_Code2) AS UniqueCode,
                P.Is_Success,
                P.Dial_Mode,
                ROW_NUMBER() OVER
                (
                    PARTITION BY CONCAT(P.Received_Code1, P.Received_Code2)
                    ORDER BY P.Enq_Date
                ) AS rn
            FROM Pro_Enq P WITH (NOLOCK)
            INNER JOIN ConsumerPointsCashDetails C WITH (NOLOCK)
                ON C.Code1 = P.Received_Code1
               AND C.Code2 = P.Received_Code2
            LEFT JOIN GeoLocationData G WITH (NOLOCK)
                ON G.Code1 = P.Received_Code1
               AND G.Code2 = P.Received_Code2
               AND G.Comp_Id = P.Comp_ID
            WHERE
                P.Comp_Id = @Comp_Id
                AND C.Cash > 0
                AND (
                    (P.Latitude IS NOT NULL AND LTRIM(RTRIM(P.Latitude)) NOT IN ('', '0', '0.0', 'undefined', 'null'))
                    OR
                    (G.Latitude IS NOT NULL AND LTRIM(RTRIM(G.Latitude)) NOT IN ('', '0', '0.0', 'undefined', 'null'))
                )
                AND (
                    @CleanDialMode IS NULL
                    OR (
                        CASE 
                            WHEN @CleanDialMode = 'QR CODE' AND (UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%QR%' OR UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%SCAN%') THEN 1
                            WHEN @CleanDialMode = 'WEB' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%WEB%' THEN 1
                            WHEN @CleanDialMode = 'SMS' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%SMS%' THEN 1
                            WHEN @CleanDialMode = 'APP' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%APP%' THEN 1
                            WHEN @CleanDialMode = 'IVR' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%IVR%' THEN 1
                            WHEN @CleanDialMode = 'WHATSAPP' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%WHATSAPP%' THEN 1
                            ELSE 0
                        END = 1
                    )
                )
                AND (@StartDate IS NULL OR P.Enq_Date >= @StartDate)
                AND (@EndDate   IS NULL OR P.Enq_Date <  @EndDate)
        )
        SELECT
            Latitude,
            Longitude,
            MobileNo,
            Enq_Date,
            UniqueCode,
            CASE
                WHEN Is_Success = '0' THEN 'Invalid'
                WHEN rn = 1 THEN 'Authenticate'
                ELSE 'Re-Authenticate'
            END AS UniqueCodeStatus,
            Dial_Mode
        FROM CTE;
    END
    ELSE
    BEGIN
        SELECT  
            COALESCE(NULLIF(LTRIM(RTRIM(G.Latitude)), ''), P.Latitude) AS Latitude,
            COALESCE(NULLIF(LTRIM(RTRIM(G.Longitude)), ''), P.Longitude) AS Longitude,
            P.MobileNo,
            P.Enq_Date,
            CONCAT(P.Received_Code1, P.Received_Code2) AS UniqueCode,
            CASE 
                WHEN P.Is_Success = '1' THEN 'Authenticate'
                WHEN P.Is_Success = '2' THEN 'Re-Authenticate'
                ELSE 'Invalid'
            END AS UniqueCodeStatus,
            P.Dial_Mode
        FROM Pro_Enq P WITH (NOLOCK)
        LEFT JOIN GeoLocationData G WITH (NOLOCK)
            ON G.Code1 = P.Received_Code1
           AND G.Code2 = P.Received_Code2
           AND G.Comp_Id = P.Comp_ID
        WHERE
            P.Comp_Id = @Comp_Id
            AND (
                (P.Latitude IS NOT NULL AND LTRIM(RTRIM(P.Latitude)) NOT IN ('', '0', '0.0', 'undefined', 'null'))
                OR
                (G.Latitude IS NOT NULL AND LTRIM(RTRIM(G.Latitude)) NOT IN ('', '0', '0.0', 'undefined', 'null'))
            )
            AND (
                @CleanDialMode IS NULL
                OR (
                    CASE 
                        WHEN @CleanDialMode = 'QR CODE' AND (UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%QR%' OR UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%SCAN%') THEN 1
                        WHEN @CleanDialMode = 'WEB' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%WEB%' THEN 1
                        WHEN @CleanDialMode = 'SMS' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%SMS%' THEN 1
                        WHEN @CleanDialMode = 'APP' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%APP%' THEN 1
                        WHEN @CleanDialMode = 'IVR' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%IVR%' THEN 1
                        WHEN @CleanDialMode = 'WHATSAPP' AND UPPER(ISNULL(P.Dial_Mode, '')) LIKE '%WHATSAPP%' THEN 1
                        ELSE 0
                    END = 1
                )
            )
            AND (@StartDate IS NULL OR P.Enq_Date >= @StartDate)
            AND (@EndDate   IS NULL OR P.Enq_Date <  @EndDate);
    END
END
GO
