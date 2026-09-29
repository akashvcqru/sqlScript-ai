-- Migration: 20260929_Optimize_SP_Admin_GetCodesActivityReport_AI.sql
-- Purpose: Optimize SP_Admin_GetCodesActivityReport_AI and remove ServiceName & Points from response keys.

USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_Admin_GetCodesActivityReport_AI]    Script Date: 9/29/2026 3:55:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Admin_GetCodesActivityReport_AI]
    @Comp_Id          VARCHAR(50)   = NULL,
    @datePreset       NVARCHAR(50)  = 'TODAY', -- Today (default), Week (7 days)
    @FromDate         DATE          = NULL,
    @ToDate           DATE          = NULL,
    @CodeStatusFilter NVARCHAR(50)  = NULL,    -- Verified, Already Scanned, Invalid
    @DialModeFilter   NVARCHAR(50)  = NULL,    -- Website, BL_APP, etc.
    @Search           NVARCHAR(100) = NULL,
    @Page             INT           = 1,
    @Limit            INT           = 10,
    @IsExport         BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------
    -- 0. CLEAN / NORMALIZE INPUTS
    ----------------------------------------------------
    SET @Comp_Id = NULLIF(LTRIM(RTRIM(@Comp_Id)), '');
    IF (UPPER(@Comp_Id) = 'ALL') SET @Comp_Id = NULL;

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    IF LTRIM(RTRIM(ISNULL(@Search, ''))) = '' OR @Search = 'null' SET @Search = NULL;
    IF LTRIM(RTRIM(ISNULL(@CodeStatusFilter, ''))) = '' OR @CodeStatusFilter = 'null' OR UPPER(@CodeStatusFilter) = 'ALL' SET @CodeStatusFilter = NULL;
    IF LTRIM(RTRIM(ISNULL(@DialModeFilter, ''))) = '' OR @DialModeFilter = 'null' OR UPPER(@DialModeFilter) = 'ALL' SET @DialModeFilter = NULL;

    DECLARE @SearchMobile NVARCHAR(30) = NULL;
    IF @Search IS NOT NULL
    BEGIN
        DECLARE @CleanSearchDigits NVARCHAR(100) = REPLACE(REPLACE(REPLACE(REPLACE(@Search, '+', ''), '-', ''), ' ', ''), '(', '');
        SET @CleanSearchDigits = REPLACE(@CleanSearchDigits, ')', '');
        IF @CleanSearchDigits NOT LIKE '%[^0-9]%' AND LEN(@CleanSearchDigits) >= 10
        BEGIN
            SET @SearchMobile = RIGHT(@CleanSearchDigits, 10);
        END
    END

    ----------------------------------------------------
    -- 1. DATE RANGE CALCULATION (Latest records / 1 week cap)
    ----------------------------------------------------
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate   DATETIME;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE IF (@FromDate IS NOT NULL)
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = DATEADD(DAY, -7, CAST(@ToDate AS DATETIME));
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATETIME));
    END
    ELSE
    BEGIN
        DECLARE @NormPreset NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, 'TODAY'))));
        IF (@NormPreset = '' OR @NormPreset = 'NULL') SET @NormPreset = 'TODAY';

        IF (@NormPreset = 'TODAY' OR @NormPreset = '1 TODAY')
        BEGIN
            SET @StartDate = CAST(GETDATE() AS DATE);
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = 'LASTDAY' OR @NormPreset = 'YESTERDAY' OR @NormPreset = '1 YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
            SET @EndDate   = CAST(GETDATE() AS DATE);
        END
        ELSE IF (@NormPreset = 'WEEK' OR @NormPreset = '1 WEEK' OR @NormPreset = 'CURRENTWEEK' 
                 OR @NormPreset = '7DAYS' OR @NormPreset = '7 DAYS' OR @NormPreset = 'LAST7DAYS' OR @NormPreset = 'LAST 7 DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE IF (@NormPreset = 'LASTWEEK' OR @NormPreset = 'PREVIOUSWEEK' OR @NormPreset = 'PREVWEEK')
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
            SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
        END
        ELSE IF (@NormPreset = 'MONTH' OR @NormPreset = '1 MONTH' OR @NormPreset = 'CURRENTMONTH'
                 OR @NormPreset = '30DAYS' OR @NormPreset = '30 DAYS' OR @NormPreset = 'LAST30DAYS' OR @NormPreset = 'LAST 30 DAYS')
        BEGIN
            SET @StartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
        ELSE
        BEGIN
            -- Default fallback: Latest 1 week (7 days)
            SET @StartDate = DATEADD(DAY, -7, CAST(GETDATE() AS DATE));
            SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        END
    END

    ----------------------------------------------------
    -- 2. FETCH MATCHING ENQUIRIES DIRECTLY FROM PRO_ENQ
    ----------------------------------------------------
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;

    SELECT 
        PE.Row_ID,
        PE.Comp_ID,
        PE.MobileNo,
        PE.Received_Code1,
        PE.Received_Code2,
        PE.Enq_Date,
        PE.Dial_Mode,
        PE.Is_Success,
        PE.SST_ID,
        PE.Latitude,
        PE.Longitude
    INTO #Enq
    FROM dbo.Pro_Enq PE WITH (NOLOCK)
    WHERE PE.Enq_Date >= @StartDate
      AND PE.Enq_Date <  @EndDate
      AND (@Comp_Id IS NULL OR PE.Comp_ID = @Comp_Id)
      AND (@DialModeFilter IS NULL OR PE.Dial_Mode = @DialModeFilter)
      AND (
          @CodeStatusFilter IS NULL
          OR (@CodeStatusFilter = 'Verified' AND (PE.Is_Success = '1' OR PE.Is_Success = 1))
          OR (@CodeStatusFilter IN ('Already Scanned', 'Already Verified') AND (PE.Is_Success = '2' OR PE.Is_Success = 2))
          OR (@CodeStatusFilter = 'Invalid' AND PE.Is_Success NOT IN ('1', '2', 1, 2))
      )
      AND (
          @Search IS NULL 
          OR PE.MobileNo LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND PE.MobileNo LIKE '%' + @SearchMobile + '%')
          OR (PE.Received_Code1 + PE.Received_Code2) LIKE '%' + @Search + '%'
          OR (@SearchMobile IS NOT NULL AND (PE.Received_Code1 + PE.Received_Code2) LIKE '%' + @SearchMobile + '%')
          OR PE.Comp_ID LIKE '%' + @Search + '%'
      );

    ----------------------------------------------------
    -- 3. TOTAL RECORDS (Result Set 1)
    ----------------------------------------------------
    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(1) FROM #Enq;

    SELECT @TotalRecords AS TotalRecords;

    ----------------------------------------------------
    -- 4. PAGINATED DATA (Result Set 2)
    ----------------------------------------------------
    SELECT 
        ISNULL(E.Comp_ID, '') AS CompanyId,
        ISNULL(CR.Comp_Name, ISNULL(E.Comp_ID, '')) AS CompanyName,
        ISNULL(E.MobileNo, '') AS MobileNo,
        (ISNULL(E.Received_Code1, '') + ISNULL(E.Received_Code2, '')) AS UniqueCode,
        PR.Pro_Name AS Pro_Name,
        E.Enq_Date AS Enq_Date,
        ISNULL(E.Dial_Mode, '') AS Dial_Mode,
        CASE 
            WHEN E.Is_Success = 1 OR E.Is_Success = '1' THEN 'Verified'
            WHEN E.Is_Success = 2 OR E.Is_Success = '2' THEN 'Already Scanned'
            ELSE 'Invalid'
        END AS Result,
        ISNULL(E.Latitude, '') AS Latitude,
        ISNULL(E.Longitude, '') AS Longitude
    FROM (
        SELECT *
        FROM #Enq
        ORDER BY Enq_Date DESC
        OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS
        FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @Limit END ROWS ONLY
    ) E
    LEFT JOIN dbo.Comp_Reg CR WITH (NOLOCK) 
        ON CR.Comp_ID = E.Comp_ID
    LEFT JOIN dbo.M_ServiceSubscriptionTrans SST WITH (NOLOCK) 
        ON SST.SST_Id = E.SST_ID
    LEFT JOIN dbo.M_ServiceSubscription SS WITH (NOLOCK) 
        ON SS.Subscribe_Id = SST.Subscribe_Id
    LEFT JOIN dbo.Pro_Reg PR WITH (NOLOCK) 
        ON PR.Pro_ID = SS.Pro_ID
    ORDER BY E.Enq_Date DESC;

    -- Cleanup
    IF OBJECT_ID('tempdb..#Enq') IS NOT NULL DROP TABLE #Enq;
END;
GO
