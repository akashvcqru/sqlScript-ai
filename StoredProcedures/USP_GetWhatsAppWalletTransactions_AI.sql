/****** Object:  StoredProcedure [dbo].[USP_GetWhatsAppWalletTransactions_AI]    Script Date: 3/2/2026 12:27:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[USP_GetWhatsAppWalletTransactions_AI]
(
	@Comp_Id varchar(50)
)
as
begin
	select 
		Id, 
		Comp_Id, 
		OldBal, 
		NewBal, 
		Amount, 
		Cr_Dr_Type as CrDrType, 
		ReqDate as TransactionDate, 
		Remarks, 
		PaymentGatewayTxnId, 
		Status
	from tblWhatsAppWalletBalance
	where Comp_Id = @Comp_Id
	order by Id desc
end
GO
