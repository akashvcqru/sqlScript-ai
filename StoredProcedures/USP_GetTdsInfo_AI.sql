USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetTdsInfo_AI]    Script Date: 5/12/2026 6:33:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[USP_GetTdsInfo_AI]
(
    @M_Consumerid VARCHAR(50),
    @Comp_ID VARCHAR(50),
    @fyStart INT,
    @fyEnd INT
)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @startDate DATETIME = DATEFROMPARTS(@fyStart, 4, 1);
    DECLARE @endDate DATETIME = DATETIMEFROMPARTS(@fyEnd, 3, 31, 23, 59, 59, 999);
    DECLARE @mobileNo VARCHAR(20);
    DECLARE @compIdNumeric VARCHAR(20) = SUBSTRING(@Comp_ID, CHARINDEX('-', @Comp_ID) + 1, LEN(@Comp_ID));

    -- Get Mobile Number
    SELECT TOP 1 @mobileNo = MobileNo
    FROM m_consumer 
    WHERE M_Consumerid = @M_Consumerid 
    ORDER BY M_Consumerid DESC;
    
    DECLARE @EarnAmountFY DECIMAL(18,2) = 0;
    DECLARE @TdsAmountFY DECIMAL(18,2) = 0;
    DECLARE @TotalCash DECIMAL(18,2) = 0;
    DECLARE @TotalPoints DECIMAL(18,2) = 0;
    DECLARE @TransferredCash DECIMAL(18,2) = 0;

    -- 1. Total Points (Logic from USP_Consumerpoint_AI)
    IF (@Comp_ID = 'Comp-1152')
    BEGIN
        SELECT @TotalPoints = COALESCE(SUM(CAST(cash AS INT)), 0)
        FROM ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_Consumerid and Enq_Date >='2022-08-04 00:00:00.000';
    END
    ELSE
    BEGIN
        SELECT @TotalPoints = COALESCE(SUM(CAST(bp.Points AS INT)), 0) 
             + COALESCE(CAST(SUM(CASE WHEN @Comp_ID = 'Comp-1841' THEN bp.extraAmount ELSE 0 END) AS INT), 0)  
             + COALESCE(
                   (SELECT COALESCE(SUM(CAST(bp2.Points AS INT)), 0)
                    FROM BLoyaltyPointsEarned bp2
                    WHERE bp2.M_Consumerid = @M_Consumerid AND bp2.compid = @Comp_ID AND bp2.ServiceName in ('Referral','KYCRewards','Supervisor','InvoiceBenifit','InvoiceRewards')
                   ), 0
               )
        FROM BLoyaltyPointsEarned bp
        INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
        INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
        WHERE bp.M_Consumerid = @M_Consumerid 
          AND (ms.Comp_ID = @Comp_ID OR (@Comp_ID IN ('Comp-1650', 'Comp-1567') AND ms.Comp_ID IN ('Comp-1650', 'Comp-1567') ));
    END

    -- 2. EarnAmountFY and TdsAmountFY and TotalCash
    IF (@Comp_ID = 'Comp-1152')
    BEGIN
        SELECT @EarnAmountFY = ISNULL(SUM(Amount), 0) 
        FROM Transactions 
        WHERE M_CounserID = @M_Consumerid AND Issuccess = 1 AND CompId = @compIdNumeric AND TransactionDate BETWEEN @startDate AND @endDate;

        SELECT @TdsAmountFY = ISNULL(SUM(tdsAmount), 0),
               @TotalCash = ISNULL(SUM(amount_won), 0)
        FROM TBL_M_Star_Codeverification 
        WHERE Mobile_Number =   @mobileNo 
          AND Comp_id = @Comp_ID AND payStatus = 1 AND enquiry_date BETWEEN @startDate AND @endDate;
    END
    ELSE
    BEGIN
        SELECT @EarnAmountFY = ISNULL(SUM(Amount), 0), @TdsAmountFY = ISNULL(SUM(tdsAmount), 0) 
        FROM tblUPITransactionDetails 
        WHERE M_Consumerid = @M_Consumerid AND status = 'Success' AND Comp_id = @Comp_ID AND ReqDate BETWEEN @startDate AND @endDate;
        
        IF @Comp_ID = 'Comp-1274'
            SELECT @TotalCash = ISNULL(SUM(Cash), 0) * 1.10 FROM dbo.BLoyaltyPointsEarned WHERE M_Consumerid = @M_Consumerid AND compid = @Comp_ID;
        ELSE
            SELECT @TotalCash = ISNULL(SUM(Cash), 0) FROM dbo.BLoyaltyPointsEarned WHERE M_Consumerid = @M_Consumerid AND (compid = @Comp_ID or (@Comp_ID IN ('Comp-1650', 'Comp-1567') AND compid IN ('Comp-1650', 'Comp-1567') ) );
    END

    SET @TransferredCash = @TotalCash - @TdsAmountFY;

    -- 3. Pan Status/Number
    DECLARE @PanNumber VARCHAR(50), @PanStatus VARCHAR(50);
    SELECT TOP 1 @PanNumber = Pancard_number, 
                 @PanStatus = CASE WHEN (LEN(PanCard_Number) > 5 OR LEN(pan_card_file) > 10) THEN 'Available' ELSE 'Not Available' END 
    FROM M_Consumer 
    WHERE M_Consumerid = @M_Consumerid;
    
    -- Overwrite with verified status if exists
    IF EXISTS (SELECT 1 FROM tblKycPanDataDetails WHERE M_ConsumerId = @M_Consumerid AND IsPanVerify = '1' AND Status = '1')
    BEGIN
        SELECT TOP 1 @PanNumber = PanCardNumber, @PanStatus = 'Available' 
        FROM tblKycPanDataDetails WHERE M_ConsumerId = @M_Consumerid AND IsPanVerify = '1' AND Status = '1';
    END

    -- 4. Notification and Type
    DECLARE @TdsNotification NVARCHAR(MAX) = 'NA', @TdsType VARCHAR(20) = 'NA';
    SELECT @TdsNotification = ISNULL(tds_description, 'NA'), 
           @TdsType = CASE WHEN tds_status=0 THEN 'Not Aplicable' WHEN tds_status =1 THEN 'Enable' ELSE 'Disable' END 
    FROM set_tds WHERE Comp_id = @Comp_ID;


    -- Result 1: Summary info
    SELECT 
        CAST(@EarnAmountFY AS VARCHAR) AS reedemPoint,
        CAST(@TdsAmountFY AS VARCHAR) AS tdsAmount,
        CAST(@TotalCash AS VARCHAR) AS totalCash,
        CAST(@TransferredCash AS VARCHAR) AS transferredCash,
        CAST(@TotalPoints AS VARCHAR) AS totalPoint,
        @TdsNotification AS TdsNotification,
        @TdsType AS TdsType,
        @PanStatus AS PanStatus,
        @PanNumber AS PanNumber;

    -- Result 2: Certificates
    SELECT img_path FROM tds_certificate WHERE M_Consumerid = @M_Consumerid AND Comp_ID = @Comp_ID;

	--select @Comp_ID,@startDate,@endDate
    -- Result 3: History
	IF (@Comp_ID = 'Comp-1152')
    BEGIN
        SELECT  ID AS TransactionId,
        CAST((amount_won ) AS DECIMAL(18,2)) AS TotalAmount,
         TdsAmount,
        amount_won AS GrossAmount,
        Status AS TransactionStatus,  
		CAST(
        (CAST(TdsAmount AS DECIMAL(18,2)) * 100.0) / 
        NULLIF(CAST(amount_won AS DECIMAL(18,2)), 0)
        AS DECIMAL(18,2)
    ) AS tdsper,
       -- tdsper,
        CONVERT(VARCHAR, enquiry_date, 120) AS TransactionDate
        FROM TBL_M_Star_Codeverification 
        WHERE  Mobile_Number =  @mobileNo
          AND Comp_id = @Comp_ID and payStatus = '1'
          AND enquiry_date BETWEEN @startDate AND @endDate
    END
    ELSE
    BEGIN
         SELECT
        OrderId AS TransactionId,
        CAST((Amount) AS DECIMAL(18,2)) AS TotalAmount,
         TdsAmount,
        Points_Val AS GrossAmount,
        Status AS TransactionStatus,
        tdsper,
        CONVERT(VARCHAR, ReqDate, 120) AS TransactionDate
    FROM tblUPITransactionDetails
    WHERE M_ConsumerId = @M_Consumerid AND Comp_ID = @Comp_ID AND CAST(ReqDate AS DATE) BETWEEN @startDate AND @endDate
    ORDER BY ReqDate DESC;
    END
    --SELECT
    --    OrderId AS TransactionId,
    --    CAST((Amount ) AS DECIMAL(18,2)) AS TotalAmount,
    --     TdsAmount,
    --    Points_Val AS GrossAmount,
    --    Status AS TransactionStatus,
    --    tdsper,
    --    CONVERT(VARCHAR, ReqDate, 120) AS TransactionDate
    --FROM tblUPITransactionDetails
    --WHERE M_ConsumerId = @M_Consumerid AND Comp_ID = @Comp_ID AND CAST(ReqDate AS DATE) BETWEEN @startDate AND @endDate
    --ORDER BY ReqDate DESC;
END;


