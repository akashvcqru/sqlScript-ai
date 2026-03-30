/****** Object:  StoredProcedure [dbo].[Proc_GetProductDtsByCode1andcode2_AI]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Proc_GetProductDtsByCode1andcode2_AI] (@code1 numeric(5,0), @code2 numeric(8,0), @url nvarchar(500))
as
begin
	SELECT   T_Pro.WarrantyDurationMonth ,Comp_Reg.Comp_Name,  m_code.Pro_ID+'-'+ 
		 convert(varchar,(case when len(convert(nvarchar,M_Code.Series_Order)) = 1 
		 then '0'+ convert(nvarchar,M_Code.Series_Order) else 
		 convert(nvarchar,M_Code.Series_Order) end))+'-'+
		 convert(varchar,(case when len(convert(varchar,M_Code.Series_Serial)) = 1 then '00' 
		 +convert(varchar,M_Code.Series_Serial)  
		 when len(convert(varchar,M_Code.Series_Serial)) = 2 then '0' 
		 +convert(varchar,M_Code.Series_Serial) 
		 else convert(varchar,M_Code.Series_Serial) end )) as series, 
		 Prod.Pro_Name 
		 ,isnull(Pro_Reg.Comments,'') as Comments,m_code.Pro_ID,
		 T_Pro.MRP,convert(nvarchar,T_Pro.Mfd_Date,103) as Mfd_Date, T_Pro.Mfd_Date AS mfg_date,convert(nvarchar,isnull(T_Pro.Exp_Date,''),103) as Exp_Date,
		 T_Pro.Batch_No, M_Code.Code1,M_Code.Code2,M_Code.Row_ID,
		 T_Pro.Exp_Date AS exp_date1,
		 @url + substring(Pro_Reg.Comp_ID,6,4) + '/' + substring(Pro_Reg.Comp_ID,6,4) + '.mp3' as Company_Sound_File,
	   @url+ substring(Pro_Reg.Comp_ID,6,4) + '/' + ltrim(rtrim(T_Pro.Pro_ID)) + '/' + ltrim(rtrim(T_Pro.Pro_ID)) + '.mp3' as Product_Sound_File,
		@url+ substring(Pro_Reg.Comp_ID,6,4) + '/' + ltrim(rtrim(T_Pro.Pro_ID)) + '/' + convert(nvarchar,T_Pro.Row_ID) + '/' + convert(nvarchar,T_Pro.Row_ID) + '_E.wav' as comment_english,
		@url+ substring(Pro_Reg.Comp_ID,6,4) + '/' + ltrim(rtrim(T_Pro.Pro_ID)) + '/' + convert(nvarchar,T_Pro.Row_ID) + '/' + convert(nvarchar,T_Pro.Row_ID) + '_H.wav' as comment_hindi
		FROM T_Pro with (nolock) INNER JOIN M_Code with (nolock) ON T_Pro.Row_ID =  ISNULL(M_Code.Batch_No, '133') INNER JOIN
		 Pro_Reg with (nolock) ON ltrim(rtrim(T_Pro.Pro_ID)) = Pro_Reg.Pro_ID 
		 INNER JOIN Comp_Reg ON Pro_Reg.Comp_ID = Comp_Reg.Comp_ID
		 inner join Pro_Reg Prod on Prod.Pro_ID = M_Code.Pro_ID
		 where  M_Code.Code1 = @code1 and M_Code.Code2 = @code2 
end
GO
