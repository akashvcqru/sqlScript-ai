USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER proc [dbo].[USP_GetAllUsersByCompany_AI]    
@Comp_id nvarchar(100)    
as    
begin    
SELECT     
m.M_consumerId,m.User_ID,ConsumerName,M.MobileNo, v.EmailId as email, v.IsActive,v.usercity as City,v.userstate as state,v.userpin as PinCode,v.Entry_date,v.Vrkabel_User_Type,u.User_Type,v.Outlet_name as OutletName,v.Owner_name as OwnerName,v.Segmanet_name as Segment ,v.Branddetails as Brand  , 
dcl.total_credit_limit,dsd.deposit_amount,
m.dob, m.gender, m.gst_number, m.pancard_number, m.pan_card_file, m.FirmName, m.Shop_address, m.aadharNumber, m.aadharFile, m.aadharback, m.employeeID, m.distributorID, m.UPIId, m.sur_name, m.Address, m.Per_Address, m.ReferralCode,
v.userupi, v.shop_file, v.Dealer_M_consumerid, m.Created_by, m.Comp_ID
FROM M_consumer M     
INNER JOIN tbl_Vendorvisekycstatus v on m.M_Consumerid=v.M_consumerId    
inner join User_Type u on u.Row_ID=v.Vrkabel_User_Type    
LEFT JOIN( SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY M_Consumerid ORDER BY last_updated_at DESC) AS rn
    FROM dealer_credit_limits
) AS t
WHERE t.rn = 1)
 dcl ON dcl.M_consumerid = m.M_Consumerid
LEFT JOIN (SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY M_Consumerid ORDER BY last_updated_at DESC) AS rn
    FROM dealer_security_deposits
) AS t
WHERE t.rn = 1) dsd ON dsd.M_consumerid = m.M_Consumerid
where v.Comp_id=@Comp_id
ORDER BY v.Entry_date DESC
end
GO
