CREATE PROCEDURE [dbo].[USP_Checksoftcodestatus_AI]  
@Code1 int ,  
@Code2 int   
as  
begin  
select s.Isactive,s.isdelete from M_Code m   
inner join tbl_SoftCodegenrate_Details s on s.TrackingId=m.LabelRequestId where Code1=@Code1 and Code2=@Code2  
end
GO
