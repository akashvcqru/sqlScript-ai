USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_BL_FailedTransactions_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_BL_FailedTransactions_AI]
(
    @CompId NVARCHAR(50),
    @TimeWindow NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATE, @EndDate DATE;
    SET @EndDate = CAST(GETDATE() AS DATE);
    SET DATEFIRST 1;

    -- Determine StartDate based on TimeWindow
    SET @StartDate = CASE 
                        WHEN UPPER(@TimeWindow) = 'TODAY' THEN CAST(GETDATE() AS DATE)
                        WHEN UPPER(@TimeWindow) = 'YESTERDAY' THEN DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
                        WHEN UPPER(@TimeWindow) = 'WEEK' THEN DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate)
                        WHEN UPPER(@TimeWindow) = 'LASTWEEK' THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0)
                        WHEN UPPER(@TimeWindow) = 'MONTH' THEN DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1)
                        WHEN UPPER(@TimeWindow) = 'QUARTER' THEN DATEADD(DAY, -90, @EndDate)
                        ELSE DATEADD(DAY, -7, @EndDate)
                     END;

    ---------------------------------------------------------
    -- 2️⃣ Create Temp Table
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#DedupUPI') IS NOT NULL DROP TABLE #DedupUPI;

    SELECT
        UPI.ID AS TicketID,
        UPI.Comp_ID,
        UPI.Points_Val,
        UPI.Amount,
        UPI.tdsAmount,
        UPI.tdsper,
        UPI.ConsumerName,
        UPI.MobileNo,
        UPI.UPI_Id,
        UPI.Status,
        UPI.Code1,
        UPI.Code2,
        UPI.ConsumerEmailId,
        UPI.ReqDate,
        UPI.Remarks,
        UPI.OrderId,
		UPI.M_Consumerid,
        ROW_NUMBER() OVER
        (
            PARTITION BY UPI.OrderId
            ORDER BY UPI.ReqDate DESC
        ) AS rn
    INTO #DedupUPI
    FROM tblUPITransactionDetails UPI WITH (NOLOCK)
    INNER JOIN ClaimDetails CD WITH (NOLOCK)
        ON CD.Mobileno = UPI.MobileNo
    WHERE
        UPI.Comp_ID = @CompId
        AND UPI.Status = 'Failed'
        AND UPI.Remarks IS NOT NULL
        AND CAST(UPI.ReqDate AS DATE) BETWEEN @StartDate AND @EndDate;

    ---------------------------------------------------------
    -- 3️⃣ SUMMARY
    ---------------------------------------------------------
    SELECT 
        COUNT(CASE WHEN Status = 'Failed' AND rn = 1 THEN 1 END) AS TotalFailedTransactions,
        COUNT(CASE WHEN Status = 'PendingResolution' AND rn = 1 THEN 1 END) AS PendingResolution,
        COUNT(CASE WHEN Status = 'AutoResolved' AND rn = 1 THEN 1 END) AS AutoResolved,
        ISNULL(SUM(CASE WHEN Status = 'Failed' AND rn = 1 THEN Amount END), 0) AS ValueAtRisk
    FROM #DedupUPI;

	---------------------------------------------------------
    -- 4️⃣ DETAIL
    ---------------------------------------------------------
    SELECT
        TicketID,
         Amount,
        tdsAmount,
        tdsper,
		M_Consumerid,
        ConsumerName,
        MobileNo,
        UPI_Id,
        Status,
        Code1,
        Code2,
        ConsumerEmailId,
        ReqDate,
        Remarks
    FROM #DedupUPI
    WHERE rn = 1
    ORDER BY ReqDate DESC;
END
