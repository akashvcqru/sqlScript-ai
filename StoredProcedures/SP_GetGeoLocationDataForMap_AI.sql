SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Exec [dbo].[SP_GetGeoLocationDataForMap_AI] 'Comp-1152','SRV1005','Today',null,null
ALTER PROCEDURE [dbo].[SP_GetGeoLocationDataForMap_AI]
    @Comp_Id NVARCHAR(15),	
	@ServiceID nvarchar(20)=NULL,
     @datePreset NVARCHAR(20) = NULL,   -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTERMONTH, QUARTER
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
	
AS
BEGIN
   SET NOCOUNT ON;

    -- DEFAULT SERVICE
    SET @ServiceID = 'SRV1018'

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
        SET @datePreset = UPPER(@datePreset);

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
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @ToDate));
    END
    ELSE IF (@datePreset IS NOT NULL)
    BEGIN
        SET DATEFIRST 1; -- Monday

        IF (@datePreset = 'TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@datePreset = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(SECOND, -1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@datePreset = 'WEEK') -- Current week (Mon → Today)
        BEGIN
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@datePreset = 'LASTWEEK') -- Previous full week
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0));
        END
        ELSE IF (@datePreset = 'MONTH') -- Current month
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@datePreset = 'LASTMONTH') -- Previous month
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1,
                                DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0));
        END
        ELSE IF (@datePreset = 'QUARTER') -- Previous quarter
        BEGIN
            SET @StartDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(SECOND, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0));
        END
        ELSE IF (@datePreset = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate   = GETDATE();
        END
        ELSE IF (@datePreset = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate   = DATEADD(SECOND, -1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1));
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
            G.Latitude,
            G.Longitude,
            G.MobileNo,
            G.Enq_Date,
            CONCAT(G.Code1, G.Code2) AS UniqueCode,
            G.DisplayName,
            CASE 
                WHEN P.Is_Success = 1 THEN 'Authenticate'
                WHEN P.Is_Success = 2 THEN 'Re-Authenticate'
                ELSE 'Invalid'
            END AS UniqueCodeStatus
        FROM GeoLocationData G WITH (NOLOCK)
        INNER JOIN Pro_Enq P WITH (NOLOCK)
            ON P.Received_Code1 = G.Code1 
           AND P.Received_Code2 = G.Code2
        INNER JOIN M_Code MC WITH (NOLOCK)
            ON MC.Code1 = G.Code1 
           AND MC.Code2 = G.Code2
        WHERE
            G.Comp_Id = @Comp_Id
            AND MC.Pro_ID IN (SELECT Pro_ID FROM Pro_Reg WHERE Pro_Name LIKE 'AC_%')
            AND (@StartDate IS NULL OR G.Enq_Date >= @StartDate)
            AND (@EndDate   IS NULL OR G.Enq_Date <= @EndDate);
    END
    ELSE IF (@Comp_Id = 'Comp-1152' AND @ServiceID <> 'SRV1018') -- Bloyalty
    BEGIN
        ;WITH CTE AS
        (
            SELECT  
                G.Latitude,
                G.Longitude,
                G.MobileNo,
                G.Enq_Date,
                CONCAT(G.Code1, G.Code2) AS UniqueCode,
                G.DisplayName,
                P.Is_Success,
                ROW_NUMBER() OVER
                (
                    PARTITION BY CONCAT(G.Code1, G.Code2)
                    ORDER BY G.Enq_Date
                ) AS rn
            FROM GeoLocationData G WITH (NOLOCK)
            INNER JOIN ConsumerPointsCashDetails P WITH (NOLOCK)
                ON P.Code1 = G.Code1
               AND P.Code2 = G.Code2
            WHERE
                G.Comp_Id = @Comp_Id
                AND P.Cash > 0
                AND (@StartDate IS NULL OR G.Enq_Date >= @StartDate)
                AND (@EndDate   IS NULL OR G.Enq_Date <= @EndDate)
        )
        SELECT
            Latitude,
            Longitude,
            MobileNo,
            Enq_Date,
            UniqueCode,
            DisplayName,
            CASE
                WHEN Is_Success = 0 THEN 'Invalid'
                WHEN rn = 1 THEN 'Authenticate'
                ELSE 'Re-Authenticate'
            END AS UniqueCodeStatus
        FROM CTE;
    END
    ELSE
    BEGIN
        SELECT  
            G.Latitude,
            G.Longitude,
            G.MobileNo,
            G.Enq_Date,
            CONCAT(G.Code1, G.Code2) AS UniqueCode,
            G.DisplayName,
            CASE 
                WHEN P.Is_Success = 1 THEN 'Authenticate'
                WHEN P.Is_Success = 2 THEN 'Re-Authenticate'
                ELSE 'Invalid'
            END AS UniqueCodeStatus
        FROM GeoLocationData G WITH (NOLOCK)
        INNER JOIN Pro_Enq P WITH (NOLOCK)
            ON P.Received_Code1 = G.Code1
           AND P.Received_Code2 = G.Code2
        WHERE
            G.Comp_Id = @Comp_Id
            AND (@StartDate IS NULL OR G.Enq_Date >= @StartDate)
            AND (@EndDate   IS NULL OR G.Enq_Date <= @EndDate);
    END
END
GO
