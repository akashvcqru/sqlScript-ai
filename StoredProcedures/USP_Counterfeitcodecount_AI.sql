SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[USP_Counterfeitcodecount_AI]
(
@M_consumerid int,
@compid varchar(10)=null
)
AS
BEGIN
select count(Pro_Enq.[Received_Code1]) from M_Consumer as mc                                 
inner join Pro_Enq  on Pro_Enq.MobileNo=mc.MobileNo                                
inner join M_code on CAST(M_Code.Code1 as nvarchar(5))=Pro_Enq.Received_Code1 and CAST(M_Code.Code2 as nvarchar(8))=Pro_Enq.Received_Code2                                
inner join Pro_Reg on Pro_Reg.Pro_ID=M_Code.Pro_ID                                
inner join Comp_Reg on Comp_Reg.Comp_ID=Pro_Reg.Comp_ID                                
where Comp_Reg.Comp_ID=@compid and [M_Consumerid]=@M_consumerid   and Is_Success=0  
end
GO
