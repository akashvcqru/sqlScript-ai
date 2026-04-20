USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER proc [dbo].[USP_PROFILEDEATILS_BL_AI]    
@MobileNo varchar(20),    
@Comp_Id varchar(20)    
as    
begin    
    
 select m.M_Consumerid,User_ID,ConsumerName,Email,m.MobileNo,city as City,PinCode as PinCode,v.Entry_Date,m.IsActive    
 ,m.IsDelete as IsDeleted,Address,Per_Address,ReferralCode,IsSharedReferralCode,employeeID,distributorID    
 ,aadharNumber,aadharFile,aadharback,aadharUploadedate,aadharUploadedBy,Aadhar_source,village    
 ,district,state,country,Role_Id,Created_by,m.Comp_id,SellerName,token,MStarId,Inox_User_Type  ,  m.employeeID AS [TechMasterId/MStarId/SBU], m.distributorID as DealerCode
 ,cin_number,ref_cin_number,designation,dob,gender,sur_name,communication_status    
 ,business_status,house_number,land_mark,owner_number,shop_name,pancard_number,gst_number,pan_card_file    
 ,v.shop_file,Other_Role,  
 pic.Profile_img as profile_image,  
 isnull(v.VRKbl_KYC_status,0)VRKbl_KYC_status,Additional,remark,isnull(panekycStatus,0)panekycStatus,isnull(aadharkycStatus,0)aadharkycStatus    
 ,isnull(bankekycStatus,0)bankekycStatus,PanHolderName,AadharHolderName,m.UPIId,Shop_address,FirmName,Agegroup    
 ,Pancard_Status,Aadhar_Status,Passbook_Status,Ekyc_status,Location,AddressProof    
 ,UpiidImage,UPIKYCSTATUS,teslapayoutmode,Selfie_image,

CASE 
    WHEN u.User_Type IS NULL THEN '' 
    ELSE u.User_Type 
END AS User_Type
,
        CASE 
            WHEN u.User_Type IS not NULL THEN u.User_Type 
            WHEN k.User_Type IS not NULL THEN k.User_Type 
            WHEN m.Other_Role IS not NULL THEN m.Other_Role
            ELSE ''
        END
 AS Vrkabel_User_Type

 from M_Consumer m    
 left join tbl_Vendorvisekycstatus v on v.M_consumerId=m.M_Consumerid
 left join User_Type u on v.Vrkabel_User_Type=u.Row_ID    
 left join User_Type k on m.Vrkabel_User_Type=k.Row_ID    
 left join Profile_images pic on pic.m_consumerid=m.M_Consumerid  
 where m.mobileno=@MobileNo and (m.IsDelete IS NULL OR m.IsDelete <> 1)    
 end 
