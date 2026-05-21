
USE [Vcqru]
GO

/****** Object:  StoredProcedure [dbo].[PROC_appGetUserDetails_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[PROC_appGetUserDetails_AI] 	
   @User_ID nvarchar(50)    
AS
BEGIN
select @User_ID=right(@User_ID,10)
			SELECT top 1 mc.*,replace(pr.[Profile_img],'"','') [Profile_img] FROM [M_Consumer] mc left join [Profile_images] pr on pr.m_consumerid=mc.m_consumerid WHERE[MobileNo] like '%'+@User_ID and IsDelete=0 order by entry_Date desc
END
GO

/****** Object:  StoredProcedure [dbo].[USP_dashboarddata_BL_AI] ******/
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
DECLARE @TotalCash DECIMAL(18,2) = 0;
DECLARE @TotalCodeCheck INT = 0;
DECLARE @TotalSuccessCheck INT = 0;
DECLARE @USERTYPE INT = 0;
DECLARE @FilterDate DATETIME = '1900-08-04 00:00:00.000';

    IF (@compid = 'Comp-1152')
    BEGIN
	 select @USERTYPE = Vrkabel_User_Type from M_Consumer where M_Consumerid = @M_consumerid
	 IF (@USERTYPE IN (121))
        SET @FilterDate = '2024-02-24 00:00:00.000'; --SBU
	 IF (@USERTYPE IN (141,119))
     SET @FilterDate = '2022-08-04 00:00:00.000'; --others
        SELECT @TotalCash = ISNULL(SUM(Cash), 0)
        FROM dbo.ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_consumerid
          AND comp_id = @compid and Enq_Date >= @FilterDate
    END
    ELSE
    BEGIN
	IF @CompId='Comp-1274'
	BEGIN  
		  SELECT @TotalCash = ISNULL(SUM(Cash),0) * 1.10
			FROM dbo.BLoyaltyPointsEarned
			WHERE M_Consumerid = @M_consumerid
			AND compid = @compid;
	END
	ELSE
	BEGIN
        SELECT @TotalCash = ISNULL(SUM(Cash), 0)
        FROM dbo.BLoyaltyPointsEarned
        WHERE M_Consumerid = @M_consumerid
          AND (compid = @compid or (@compid IN ('Comp-1650', 'Comp-1567') and compid IN ('Comp-1650', 'Comp-1567') ) );
	END
    END

	IF (@compid = 'Comp-1152')
    BEGIN
        SELECT @TotalSuccessCheck = ISNULL(count(PE_ID), 0)
        FROM dbo.ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_consumerid
          AND comp_id = @compid and Enq_Date >= @FilterDate AND Is_Success = 1 ;;
    END
    ELSE
    BEGIN
        SELECT @TotalSuccessCheck = COUNT(Pro_Enq.Received_Code1)  
        FROM M_Consumer AS mc  
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo  
        INNER JOIN M_Code ON M_Code.Code1 = Pro_Enq.Received_Code1  
                           AND M_Code.Code2 = Pro_Enq.Received_Code2  
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID  
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID  
    WHERE (Comp_Reg.Comp_ID = @compid    or (@compid IN ('Comp-1650', 'Comp-1567') and Comp_Reg.Comp_ID IN ('Comp-1650', 'Comp-1567') )  )
          AND mc.M_Consumerid = @M_consumerid  
          AND Is_Success = 1 
    END

	IF (@compid = 'Comp-1152')
    BEGIN
        SELECT @TotalCodeCheck = ISNULL(count(PE_ID), 0)
        FROM dbo.ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_consumerid
          AND comp_id = @compid and Enq_Date >= @FilterDate ;;
    END
    ELSE
    BEGIN
        SELECT @TotalCodeCheck = COUNT(Pro_Enq.Received_Code1)  
        FROM M_Consumer AS mc  
        INNER JOIN Pro_Enq ON Pro_Enq.MobileNo = mc.MobileNo  
        INNER JOIN M_Code ON M_Code.Code1 = Pro_Enq.Received_Code1  
                           AND M_Code.Code2 = Pro_Enq.Received_Code2  
        INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID  
        INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID  
    WHERE (Comp_Reg.Comp_ID = @compid    or (@compid IN ('Comp-1650', 'Comp-1567') and Comp_Reg.Comp_ID IN ('Comp-1650', 'Comp-1567') )  )
         AND mc.M_Consumerid = @M_consumerid  
    END

      select @TotalCodeCheck 
    UNION ALL  
	  SELECT 
    ISNULL((
        SELECT SUM(CONVERT(INT, RedeemPoints))
        FROM BPointsTransaction WITH (NOLOCK)
        WHERE RedeemBy = @M_consumerid AND bpstatus <> 'FAILURE'
    ), 0) 
    +
    ISNULL((
        SELECT SUM(CONVERT(INT, Amount))
        FROM tblUPITransactionDetails
        WHERE M_Consumerid = @M_consumerid AND Comp_Id = @compid AND Status = 'Success' and LEN(Code1)>1 and LEN(Code2)>6
    ), 0) 
    UNION ALL  
       select @TotalSuccessCheck  
    UNION ALL  
	SELECT @TotalCash
	UNION ALL  
	  SELECT ISNULL(SUM(CONVERT(INT, Amount)), 0)
    FROM Transactions WITH (NOLOCK)
    WHERE M_CounserID = @M_consumerid
      AND Issuccess = 1
	  and TransactionDate >=  @FilterDate
      AND CompId = SUBSTRING(@compid, CHARINDEX('-', @compid) + 1, LEN(@compid))
	  AND (
        @FromDate IS NULL 
             OR TransactionDate >= @FromDate
             )
         AND (
               @endDate IS NULL 
               OR TransactionDate <= @endDate
             );
END;  
GO

/****** Object:  StoredProcedure [dbo].[USP_Consumerpoint_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER procedure [dbo].[USP_Consumerpoint_AI]
@CompId varchar(50),
@M_Consumerid varchar(50)
as
begin
IF (@CompId = 'Comp-1152')
    BEGIN
        select  COALESCE(SUM(CAST(cash AS INT)), 0) as TotalPoints
        FROM ConsumerPointsCashDetails
        WHERE M_Consumerid = @M_Consumerid
	 return
    END
SELECT COALESCE(SUM(CAST(bp.Points AS INT)), 0) 
 + COALESCE(CAST(SUM(CASE WHEN @CompId = 'Comp-1841' THEN bp.extraAmount ELSE 0 END) AS INT), 0)  
      + COALESCE(
           (SELECT COALESCE(SUM(CAST(bp2.Points AS INT)), 0)
            FROM BLoyaltyPointsEarned bp2
            WHERE bp2.M_Consumerid = @M_Consumerid AND bp2.compid = @CompId AND bp2.ServiceName in ('Referral','KYCRewards','Supervisor')
           ), 0
       ) AS TotalPoints
FROM BLoyaltyPointsEarned bp
INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
WHERE bp.M_Consumerid = @M_Consumerid AND (ms.Comp_ID = @CompId or (@compid IN ('Comp-1650', 'Comp-1567') and ms.Comp_ID IN ('Comp-1650', 'Comp-1567') ));
end
GO

/****** Object:  StoredProcedure [dbo].[USP_Counterfeitcodecount_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER procedure [dbo].[USP_Counterfeitcodecount_AI]  
(  
@M_Consumerid int,  
@Comp_id varchar(10)
)  
AS  
begin  
select cast(pe.Received_Code1 as int) Received_Code1,cast(pe.Received_Code2 as int) Received_Code2,Is_Success into #pro from   pro_enq pe inner join m_consumer m on pe.[MobileNo] = m.[MobileNo]  where m.M_Consumerid=@M_Consumerid  
select count(pe.received_code1) as codes  
from  #pro pe   
inner join M_Code mc on mc.code1=pe.received_code1 and mc.code2=pe.received_code2  
inner join pro_reg pr on pr.pro_id=mc.pro_id  
inner join m_servicesubscription ms on ms.pro_id=pr.pro_id and ms.comp_id=pr.comp_id where ms.Service_ID='SRV1018'
and ms.Comp_ID=@Comp_id
union all  
select count(pe.received_code1)  
from  #pro pe   
inner join M_Code mc on mc.code1=pe.received_code1 and mc.code2=pe.received_code2  
inner join pro_reg pr on pr.pro_id=mc.pro_id  
inner join m_servicesubscription ms on ms.pro_id=pr.pro_id and ms.comp_id=pr.comp_id 
where ms.Service_ID='SRV1018' and pe.Is_Success=1  
and ms.Comp_ID=@Comp_id
end
GO
