SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[USP_CountnotificationBL_AI]
(
@Mobileno nvarchar(20)
)
as
begin
	select count(pe.received_code1) from M_Consumer mc                                 
	inner join Pro_Enq pe  on right(pe.MobileNo,10)=right(mc.MobileNo,10)                                
	inner join (select row_id,code1,code2,pro_id from M_code where use_count>0) code on 
	CAST(code.Code1 as varchar)=pe.Received_Code1 and CAST(code.Code2 as varchar)=pe.Received_Code2                                
	inner join Pro_Reg pr on pr.Pro_ID=code.Pro_ID                                
	inner join Comp_Reg cr on cr.Comp_ID=pr.Comp_ID                                
	where cr.Comp_ID<>'Comp-1400' and pe.Is_Success=1 and mc.IsDelete=0 and right(mc.MobileNo,10)=right(@Mobileno,10)  
End
GO
