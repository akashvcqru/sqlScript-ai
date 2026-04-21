USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_dashboarddata_BL_AI]
(    
 @M_consumerid INT,    
 @compid VARCHAR(10) = NULL ,
 @FromDate datetime = null,
 @endDate datetime = null
)    
AS    
BEGIN  
    SET NOCOUNT ON;
    DECLARE @TotalCash DECIMAL(18,2) = 0;
    DECLARE @TotalCodeCheck INT = 0;
    DECLARE @TotalSuccessCheck INT = 0;
    DECLARE @USERTYPE INT = 0;
    DECLARE @FilterDate DATETIME = '1900-08-04 00:00:00.000';

    IF (@compid = 'Comp-1152')
    BEGIN
        SELECT @USERTYPE = Vrkabel_User_Type FROM M_Consumer WHERE M_Consumerid = @M_consumerid;
        IF (@USERTYPE IN (121)) SET @FilterDate = '2024-02-24 00:00:00.000';
        IF (@USERTYPE IN (141,119)) SET @FilterDate = '2022-08-04 00:00:00.000';

        SELECT @TotalCash = ISNULL(SUM(Cash), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate;
        SELECT @TotalSuccessCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate AND Is_Success = 1;
        SELECT @TotalCodeCheck = ISNULL(count(PE_ID), 0) FROM dbo.ConsumerPointsCashDetails WHERE M_Consumerid = @M_consumerid AND comp_id = @compid AND Enq_Date >= @FilterDate;
    END
    ELSE
    BEGIN
        IF @compid = 'Comp-1274'
            SELECT @TotalCash = ISNULL(SUM(Cash), 0) * 1.10 FROM dbo.BLoyaltyPointsEarned WHERE M_Consumerid = @M_consumerid AND compid = @compid;
        ELSE
            SELECT @TotalCash = ISNULL(SUM(Cash), 0) FROM dbo.BLoyaltyPointsEarned WHERE M_Consumerid = @M_consumerid AND (compid = @compid or (@compid IN ('Comp-1650', 'Comp-1567') AND compid IN ('Comp-1650', 'Comp-1567') ) );

        SELECT @TotalSuccessCheck = COUNT(Pro_Enq.Received_Code1)  
        FROM M_Consumer AS mc  
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo  
        INNER JOIN M_Code ON M_Code.Code1 = Pro_Enq.Received_Code1 AND M_Code.Code2 = Pro_Enq.Received_Code2  
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID  
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID  
        WHERE (Comp_Reg.Comp_ID = @compid OR (@compid IN ('Comp-1650', 'Comp-1567') AND Comp_Reg.Comp_ID IN ('Comp-1650', 'Comp-1567') ) ) AND mc.M_Consumerid = @M_consumerid AND Is_Success = 1;

        SELECT @TotalCodeCheck = COUNT(Pro_Enq.Received_Code1)  
        FROM M_Consumer AS mc  
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo  
        INNER JOIN M_Code ON M_Code.Code1 = Pro_Enq.Received_Code1 AND M_Code.Code2 = Pro_Enq.Received_Code2  
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID  
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID  
        WHERE (Comp_Reg.Comp_ID = @compid OR (@compid IN ('Comp-1650', 'Comp-1567') AND Comp_Reg.Comp_ID IN ('Comp-1650', 'Comp-1567') ) ) AND mc.M_Consumerid = @M_consumerid;
    END

    -- Result 0: Total Code Check
    SELECT @TotalCodeCheck as Val;

    -- Result 1: Redeem Points (BPointsTransaction + tblUPITransactionDetails)
    SELECT 
        ISNULL((SELECT SUM(CONVERT(INT, RedeemPoints)) FROM BPointsTransaction WITH (NOLOCK) WHERE RedeemBy = @M_consumerid AND bpstatus <> 'FAILURE'), 0) 
        + ISNULL((SELECT SUM(CONVERT(INT, Amount)) FROM tblUPITransactionDetails WHERE M_Consumerid = @M_consumerid AND Comp_Id = @compid AND Status = 'Success' AND LEN(Code1) > 1 AND LEN(Code2) > 6), 0) as Val;

    -- Result 2: Total Success Check
    SELECT @TotalSuccessCheck as Val;

    -- Result 3: Total Cash
    SELECT @TotalCash as Val;

    -- Result 4: Transferred Cash
    SELECT ISNULL(SUM(CONVERT(INT, Amount)), 0) as Val
    FROM Transactions WITH (NOLOCK)
    WHERE M_CounserID = @M_consumerid AND Issuccess = 1 AND TransactionDate >= @FilterDate AND CompId = SUBSTRING(@compid, CHARINDEX('-', @compid) + 1, LEN(@compid))
      AND (@FromDate IS NULL OR TransactionDate >= @FromDate) AND (@endDate IS NULL OR TransactionDate <= @endDate);
END;
