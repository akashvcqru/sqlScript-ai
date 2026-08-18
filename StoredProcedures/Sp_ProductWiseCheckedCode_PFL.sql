-- exec [dbo].[Sp_ProductWiseCheckedCode_PFL] 'Comp-1693','ALL'
CREATE PROCEDURE [dbo].[Sp_ProductWiseCheckedCode_PFL]    
@Comp_Id varchar(20),
 @Window NVARCHAR(10)=NULL
AS    
BEGIN    
  SET NOCOUNT ON;

    ------------------------------------------------------
    -- Company start date
    ------------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;
    SELECT @CompanyStartDate = Reg_Date
    FROM Comp_Reg
    WHERE Comp_ID = @Comp_Id AND Status = 1;

    ------------------------------------------------------
    -- Calendar based Date Window
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- Temp product codes
    ------------------------------------------------------
 

    ------------------------------------------------------
    -- Merge data with date filter applied
    ------------------------------------------------------
    DROP TABLE IF EXISTS #MergedData;

    SELECT 
        FE.Pro_Name,
        FE.Is_Success,FE.Status
    INTO #MergedData
    FROM pfl_codecheckData FE
    WHERE FE.Enq_Date >= @StartDate
      AND FE.Enq_Date <  @EndDate
      AND FE.Pro_Name IS NOT NULL
  AND FE.Pro_Name <> 'Not Assigned';

    ------------------------------------------------------
    -- Product wise Top 5
    ------------------------------------------------------
    SELECT TOP 5
        Pro_Name,
        --SUM(CASE WHEN  Is_Success = 1 THEN 1 ELSE 0 END) AS SuccessScans,
        --SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS FailedScans,
        --SUM(CASE WHEN Is_Success = 1 THEN 1 ELSE 0 END)
       -- + SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS TotalScans
	   SUM(CASE WHEN status IN ('Authenticate','Re-Authenticate')  THEN 1 ELSE 0  END) AS SuccessScans,
			SUM(CASE WHEN  Status ='Failed' THEN 1 ELSE 0 END) AS FailedScans,
	   count(1) AS TotalScans
    FROM #MergedData
    GROUP BY Pro_Name
    ORDER BY TotalScans DESC;

    ------------------------------------------------------
    -- Total summary
    ------------------------------------------------------
    SELECT
        --SUM(CASE WHEN  Is_Success = 1 THEN 1 ELSE 0 END) AS TotalSuccessScans,
        --SUM(CASE WHEN Is_Success <> 1 THEN 1 ELSE 0 END) AS TotalFailedScans,
        --SUM(CASE WHEN Is_Success = 1 THEN 1 ELSE 0 END)
		 SUM(CASE WHEN status IN ('Authenticate','Re-Authenticate')  THEN 1 ELSE 0  END) AS TotalSuccessScans,
			SUM(CASE WHEN  Status ='Failed' THEN 1 ELSE 0 END) AS TotalFailedScans,
         count(1) AS GrandTotalScans
    FROM #MergedData;

    ------------------------------------------------------
    -- Cleanup
    ------------------------------------------------------
    DROP TABLE IF EXISTS #MergedData;
    DROP TABLE IF EXISTS #Temp1;
END
