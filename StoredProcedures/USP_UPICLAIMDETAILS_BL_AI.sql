USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER Procedure [dbo].[USP_UPICLAIMDETAILS_BL_AI]      
@Mobileno varchar(13),      
@compId varchar(20)      
as      
begin      
      
select      
format(Claim_date,'dd MMM yyyy HH:mm tt') as Date,      
Row_id as [Transaction id] ,UPIID as [UPI Id],RequestAmmount as [Total Point] ,RequestAmmount as [Point Value in INR] ,ServiceChagrge as [Deducted Amount] ,Amount as [Total Rupees],       
case when  Isapproved=1 then 'Success'      
when Isapproved=2 then 'Rejected'      
else 'Pending'      
end as Status  ,      aa.Service_ID ,aa.ServiceName,
Isapproved  ,  
PaymentStatus,  
PaymentRemarks  
from ClaimDetails a left join M_Service aa on aa.Service_ID = a.Service_ID where Mobileno=@Mobileno and --Comp_id=@compId

(Comp_id = @compId or (@compId IN ('Comp-1650', 'Comp-1567') and Comp_id IN ('Comp-1650', 'Comp-1567') ) )

--and UPIID is not null       
      
end
