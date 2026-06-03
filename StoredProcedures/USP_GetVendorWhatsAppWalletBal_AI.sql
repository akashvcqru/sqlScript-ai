/****** Object:  StoredProcedure [dbo].[USP_GetVendorWhatsAppWalletBal_AI]    Script Date: 3/2/2026 12:27:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[USP_GetVendorWhatsAppWalletBal_AI]
(
	@Comp_Id varchar(50)
)
as
begin
	declare @chkflag int=0
	select @chkflag=count(*) from tblWhatsAppWalletBalance where Comp_ID=@Comp_Id

	if @chkflag=0
	begin
		select 0.00 as Balance
	end 
	else
	begin
		select top 1 ISNULL(NewBal, Amount) as Balance from tblWhatsAppWalletBalance 
		where Comp_Id=@Comp_Id order by Id desc
	end
end
GO
