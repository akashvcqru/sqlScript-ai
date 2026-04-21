/****** Object:  StoredProcedure [dbo].[GetUPIpayoutRportBL_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetUPIpayoutRportBL_AI]
(
      @Compid        NVARCHAR(50),
      @FromDate      DATE = NULL,
      @ToDate        DATE = NULL,
      @Window        NVARCHAR(20) = NULL,
      @StatusFilter  NVARCHAR(30) = NULL,   -- Success / Pending / Failed
      @MobileNo      NVARCHAR(20) = NULL,
      @Page          INT = NULL,
      @Limit         INT = NULL,
      @IsExport      BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #FinalData;

    -------------------------------------------------
    -- Company start date
    -------------------------------------------------
    DECLARE @CompanyStartDate DATETIME;

    SELECT @CompanyStartDate = Reg_Date
    FROM Comp_Reg
    WHERE Comp_ID = @Compid AND Status = 1;

    -------------------------------------------------
    -- Pagination defaults (only used when IsExport = 0)
    -------------------------------------------------
    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    -------------------------------------------------
    -- Date window logic
    -------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@Window,''));

    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(DAY,1,@ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'YESTERDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY,-1,@Today);
            SET @EndDate   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY,1-DATEPART(WEEKDAY,@Today),@Today);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'LASTWEEK'
        BEGIN
            SET DATEFIRST 1;
            DECLARE @ThisWeekStart DATE =
                DATEADD(DAY,1-DATEPART(WEEKDAY,@Today),@Today);

            SET @StartDate = DATEADD(DAY,-7,@ThisWeekStart);
            SET @EndDate   = @ThisWeekStart;
        END
        ELSE IF @Win = 'MONTH'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE IF @Win = 'LASTMONTH'
        BEGIN
            DECLARE @ThisMonthStart DATE =
                DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1);

            SET @StartDate = DATEADD(MONTH,-1,@ThisMonthStart);
            SET @EndDate   = @ThisMonthStart;
        END
        ELSE IF @Win = 'QUARTER'
        BEGIN
            SET @StartDate = DATEADD(DAY,-90,@Today);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
        ELSE
        BEGIN
            SET @StartDate = CAST(@CompanyStartDate AS DATE);
            SET @EndDate   = DATEADD(DAY,1,@Today);
        END
    END

    -------------------------------------------------
    -- Final dataset
    -------------------------------------------------
    SELECT
        m.ConsumerName,
        m.MobileNo,
        p.Code1,
        p.Code2,
        p.UPI_Id,

        ISNULL(w.OldBal,0) AS OldBal,

        CASE 
            WHEN @Compid = 'Comp-1727'
                THEN p.Amount + ISNULL(p.tdsAmount,0)
            ELSE p.Amount
        END AS Amount,

        CASE 
            WHEN @Compid = 'Comp-1727'
                THEN p.Amount
            ELSE (p.Amount - ISNULL(p.tdsAmount,0))
        END AS FinalPayment,

        p.tdsAmount,
        p.tdsper,
        p.TCharge_Amount AS ChargedAmount,
        p.GstAmount,

        ISNULL(w.NewBal,0) AS NewBal,

        p.OrderId,
        p.Status AS BankStatus,

        CASE  
            WHEN p.Remarks IN (
                'Insufficient Wallet Balance',
                'Insufficient wallet balance for debit'
            )
            THEN 'Error: IP001, please try after some time or connect with your account manager.'
            ELSE p.Remarks  
        END AS BankRemark,

        p.ReqDate,
        p.FinalStatus,

        CASE   
            WHEN ISNULL(p.Code1,'') = '' 
             AND ISNULL(p.Code2,'') = '' 
             AND p.Status = 'Success'
                THEN 'Claimed'
            ELSE p.FinalRemarks  
        END AS FinalRemark
    INTO #FinalData
    FROM tblUPITransactionDetails p
    INNER JOIN M_Consumer m 
        ON m.M_Consumerid = p.M_Consumerid
    LEFT JOIN (
        SELECT PayrefId,
               MAX(OldBal) AS OldBal,
               MAX(NewBal) AS NewBal
        FROM tblCashWalletBalance
        WHERE Service_ID IN ('SRV1029','SRV1001')
        GROUP BY PayrefId
    ) w ON w.PayrefId = p.Id
    WHERE p.Comp_Id = @Compid
      AND p.ReqDate >= @StartDate
      AND p.ReqDate <  @EndDate
      AND (@MobileNo IS NULL OR p.MobileNo LIKE '%' + @MobileNo + '%')
      AND p.Code1 NOT IN ('76106','28480','63762')
      AND p.Code2 NOT IN ('53123003','81708028','45063737');

    -------------------------------------------------
    -- Output
    -------------------------------------------------
    IF @IsExport = 1
    BEGIN
        -- Export mode: all rows, no pagination
        SELECT *
        FROM #FinalData
        WHERE (@StatusFilter IS NULL OR BankStatus = @StatusFilter)
        ORDER BY ReqDate DESC;
    END
    ELSE
    BEGIN
        -- API mode: paginated result
        SELECT *
        FROM #FinalData
        WHERE (@StatusFilter IS NULL OR BankStatus = @StatusFilter)
        ORDER BY ReqDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Pagination info
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM #FinalData
        WHERE (@StatusFilter IS NULL OR BankStatus = @StatusFilter);
    END
END
GO
