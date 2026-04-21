USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[Sp_ProductWiseCheckedCode]    Script Date: 4/7/2026 12:36:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [dbo].[Sp_ProductWiseCheckedCode] 'Comp-1599','quarter'
CREATE OR ALTER PROCEDURE [dbo].[Sp_ProductWiseCheckedCode]    
@Comp_Id varchar(20),
 @Window NVARCHAR(10)=NULL
AS    
BEGIN    
  SET NOCOUNT ON;

  DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = Reg_Date FROM Comp_Reg WITH (NOLOCK) WHERE Comp_ID = @Comp_Id AND Status = 1;

	--DECLARE @CompanyProductIDs VARCHAR(MAX);
   --SELECT @CompanyProductIDs = STRING_AGG(QUOTENAME(Pro_ID, ''''), ',') FROM Pro_Reg WITH (NOLOCK) WHERE Comp_ID = @Compid;


     DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(10) = UPPER(ISNULL(@Window, ''));

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

    -- 1️⃣ Filter Pro_Enq and compute FullCode
    SELECT 
        PE.Received_Code1,
        PE.Received_Code2,
        CAST(PE.Received_Code1 AS NVARCHAR(50)) + CAST(PE.Received_Code2 AS NVARCHAR(50)) AS FullCode,
        PE.Is_Success,
        PE.Comp_ID,
        PE.Enq_Date
    INTO #FilteredEnq
    --FROM Pro_Enq PE WITH (NOLOCK)
	FROM (select * from Pro_Enq WITH (NOLOCK)  where enq_date>=@StartDate) PE   
    WHERE PE.Comp_ID = @Comp_Id
      AND PE.Enq_Date >= @StartDate;

    -- 2️⃣ Join with M_Code and Pro_Reg, store in temp table
    SELECT 
        PR.Pro_Name,
        FE.Is_Success,
        MC.Use_Count
    INTO #MergedData
    FROM #FilteredEnq FE
    --INNER JOIN M_Code MC
	INNER JOIN (select * from M_Code WITH (NOLOCK) where pro_id in (SELECT Pro_ID from Pro_Reg PR WITH (NOLOCK) where PR.Comp_ID = @Comp_Id) and Gen_Date>=@CompanyStartDate) MC 
        ON FE.FullCode = CAST(MC.Code1 AS NVARCHAR(50)) + CAST(MC.Code2 AS NVARCHAR(50))
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
