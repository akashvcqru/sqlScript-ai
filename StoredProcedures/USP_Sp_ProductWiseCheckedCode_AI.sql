USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[Sp_ProductWiseCheckedCode]    Script Date: 4/7/2026 12:36:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [dbo].[Sp_ProductWiseCheckedCode] 'Comp-1599','quarter'
CREATE OR ALTER PROCEDURE [dbo].[USP_Sp_ProductWiseCheckedCode_AI]    
@Comp_Id varchar(20),
 @datePreset NVARCHAR(20)=NULL
AS    
BEGIN    
  SET NOCOUNT ON;

  DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = Reg_Date FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = @Comp_Id AND Status = 1;

	--DECLARE @CompanyProductIDs VARCHAR(MAX);
   --SELECT @CompanyProductIDs = STRING_AGG(QUOTENAME(Pro_ID, ''''), ',') FROM Pro_Reg WITH (NOLOCK) WHERE Comp_ID = @Compid;


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
        SET @EndDate   = DATEADD(DAY, 1, @Today); -- till today only
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE =
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);

        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today); -- till today only
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE =
            DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);

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
        -- Default = current month till today
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    -- 1️⃣ Filter Pro_Enq
    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        PE.Is_Success,
        PE.Comp_ID,
        PE.Enq_Date
    INTO #FilteredEnq
    FROM (
        SELECT pe.Received_Code1, pe.Received_Code2, pe.Is_Success, pe.Comp_ID, pe.Enq_Date
        FROM Pro_Enq pe WITH (NOLOCK)
        LEFT JOIN (
            SELECT Code1, Code2, Pro_ID FROM M_Code WITH (NOLOCK) 
            WHERE @Comp_Id <> 'Comp-1693' 
              AND Pro_ID IN (SELECT Pro_ID FROM Pro_Reg PR WITH (NOLOCK) WHERE PR.Comp_ID = @Comp_Id)
            UNION ALL
            SELECT Code1, Code2, Pro_ID FROM M_Code_PFL WITH (NOLOCK) 
            WHERE @Comp_Id = 'Comp-1693' 
              AND Pro_ID IN (SELECT Pro_ID FROM Pro_Reg PR WITH (NOLOCK) WHERE PR.Comp_ID = @Comp_Id)
        ) mc ON mc.Code1 = TRY_CAST(LTRIM(RTRIM(pe.Received_Code1)) AS NUMERIC(18,0))
            AND mc.Code2 = TRY_CAST(LTRIM(RTRIM(pe.Received_Code2)) AS NUMERIC(18,0))
        WHERE pe.Enq_Date >= @StartDate AND pe.Enq_Date < @EndDate
          AND (pe.Comp_ID = @Comp_Id OR (ISNULL(pe.Comp_ID, '') = '' AND mc.Code1 IS NOT NULL))
    ) PE;

    -- 2️⃣ Join with M_Code and Pro_Reg, store in temp table
    SELECT 
        PR.Pro_Name,
        FE.Is_Success,
        MC.Use_Count
    INTO #MergedData
    FROM #FilteredEnq FE
    --INNER JOIN M_Code MC
	INNER JOIN (
	    SELECT Code1, Code2, Pro_ID, Use_Count FROM M_Code WITH (NOLOCK) 
	    WHERE @Comp_Id <> 'Comp-1693' 
	      AND Pro_ID IN (SELECT Pro_ID FROM Pro_Reg PR WITH (NOLOCK) WHERE PR.Comp_ID = @Comp_Id) 
	    UNION ALL
	    SELECT Code1, Code2, Pro_ID, Use_Count FROM M_Code_PFL WITH (NOLOCK) 
	    WHERE @Comp_Id = 'Comp-1693' 
	      AND Pro_ID IN (SELECT Pro_ID FROM Pro_Reg PR WITH (NOLOCK) WHERE PR.Comp_ID = @Comp_Id)
	) MC 
        ON MC.Code1 = TRY_CAST(LTRIM(RTRIM(FE.Received_Code1)) AS NUMERIC(18,0))
       AND MC.Code2 = TRY_CAST(LTRIM(RTRIM(FE.Received_Code2)) AS NUMERIC(18,0))
    INNER JOIN Pro_Reg PR WITH (NOLOCK)
        ON PR.Pro_ID = MC.Pro_ID
       AND PR.Comp_ID = @Comp_Id;

    -- 3️⃣ Product-wise Top 5
    SELECT TOP 5
        Pro_Name,
        SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS SuccessScans,
        SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS FailedScans,
        SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END)
        + SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS TotalScans
    FROM #MergedData
    GROUP BY Pro_Name
    ORDER BY TotalScans DESC;

    -- 4️⃣ Total summary
    SELECT
        SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END) AS TotalSuccessScans,
        SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS TotalFailedScans,
        SUM(CASE WHEN Use_Count = 1 AND Is_Success = 1 THEN 1 ELSE 0 END)
        + SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS GrandTotalScans
    FROM #MergedData;

    -- 5️⃣ Clean up temp tables
    DROP TABLE IF EXISTS #FilteredEnq;
    DROP TABLE IF EXISTS #MergedData;

END
GO
