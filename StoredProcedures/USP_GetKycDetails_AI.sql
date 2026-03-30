SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[USP_GetKycDetails_AI]                                  
(                                  
@MobileNo nvarchar(15)                                  
)                                  
as                                  
begin                                  
SELECT mc.ConsumerName,                                  
mc.MobileNo,                                  
mc.pancard_number,                                  
mc.adharpancard_status,                                  
mc.adharpancard_remark,                                  
mc.adhaar_number,                                  
mc.bank_account_number,                                  
mc.bank_name,                                  
mc.bank_ifsc_code,                                  
mc.bank_status,                                  
mc.bank_remark,                                  
mc.vpa_id,                                  
mc.upi_status,                                  
mc.upi_remark,                                  
mc.GST_Number,                                  
mc.GST_Status,                                  
mc.GST_Remark,                                  
mc.Is_Update_Profile,                                  
mc.Role_ID,                                  
mc.M_Consumerid,                                  
(SELECT Top 1 StateName FROM State_Master where stateid = mc.state) as StateName,                                  
mc.city,                                  
mc.pin_code,                                  
mc.address,                                  
mc.pan_card_name,                                  
mc.pan_dob,                                  
mc.bank_account_holder_name as beneficiary_name,                                  
mc.Vrkabel_User_Type as Retailer_Type,                     
tds.One94HApplicable as TDS_Applicable,              
mc.pancard_image,              
mc.adharcard_image,              
mc.passbook_image,              
mc.adharcard_back_image,            
mc.Gender,            
mc.DOB,          
mc.NomineeName,          
mc.NomineeMobile,          
mc.NomineeRelation,          
mc.Email ,      
mc.ShopName,      
mc.Firm_Name,      
mc.Experience,    
mc.Kyc_status as user_kyc_status,    
mc.ShopAddress,    
mc.p_pincode, mc.p_address,     
(select TOP 1 StateName from State_Master where stateid=mc.p_state) as p_StateName,    
mc.p_city,      
mc.Business_Card,    
mc.Shop_Outside_Comp,    
mc.Shop_Inside_Comp,    
mc.Profile_Date_Update,    
mc.District,    
mc.Is_Profile_Updated,
mc.Vrkabel_User_Type
FROM M_Consumer mc                                  
left join tbl_TDSReport tds on mc.MobileNo=tds.MobileNo              
WHERE mc.MobileNo=@MobileNo                                  
                                  
end
GO
