USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER proc [dbo].[USP_UserHyraricyList]      
@Comp_id nvarchar(100)      
as      
begin      
SELECT       
m.M_consumerId,m.User_ID,v.EmailId as Email, v.Name as  ConsumerName,M.MobileNo,v.usercity as  City,v.userstate as state,v.userpin as PinCode,
v.Entry_date,v.Vrkabel_User_Type,u.User_Type,v.Outlet_name as OutletName,v.Owner_name as  OwnerName,
v.Segmanet_name as Segment ,v.Branddetails as Brand   ,dcl.total_credit_limit, dcl.current_credit_limit,dsd.deposit_amount into #KycTest
FROM M_consumer M       
INNER JOIN tbl_Vendorvisekycstatus v on m.M_Consumerid=v.M_consumerId      
inner join User_Type u on u.Row_ID=v.Vrkabel_User_Type    
left JOIN (SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY M_Consumerid ORDER BY last_updated_at DESC) AS rn FROM dealer_credit_limits) AS RankedLimits WHERE rn = 1)dcl ON dcl.M_consumerid = m.M_Consumerid
LEFT JOIN (SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY M_Consumerid ORDER BY last_updated_at DESC) AS rn FROM dealer_security_deposits) AS RankedLimits1 WHERE rn = 1) dsd ON dsd.M_consumerid = m.M_Consumerid
where v.Comp_id=@Comp_id   order by v.Entry_date desc ;

  WITH RankedKyc AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY MobileNo ORDER BY Entry_date DESC) AS rn
        FROM #KycTest
    )
    SELECT *
    FROM RankedKyc
    WHERE rn = 1;

    DROP TABLE #KycTest;
end
GO
