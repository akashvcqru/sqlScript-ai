/****** Object:  StoredProcedure [dbo].[USP_AddWhatsAppWalletTransaction_AI]    Script Date: 3/2/2026 12:27:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[USP_AddWhatsAppWalletTransaction_AI]
(
	@Comp_Id varchar(50),
	@Amount decimal(18,2),
	@Type varchar(10), -- 'Cr' or 'Dr'
	@Remarks varchar(255),
	@PaymentGatewayTxnId varchar(100) = null,
	@Status varchar(20) = 'Success'
)
as
begin
	declare @oldBal decimal(18,2) = 0.00
	declare @newBal decimal(18,2) = 0.00
	
	-- Get the last balance for this company
	select top 1 @oldBal = ISNULL(NewBal, 0.00) 
	from tblWhatsAppWalletBalance 
	where Comp_Id = @Comp_Id 
	order by Id desc
	
	if @Type = 'Cr'
	begin
		set @newBal = @oldBal + @Amount
	end
	else
	begin
		set @newBal = @oldBal - @Amount
	end
	
	-- Insert transaction details into tblWhatsAppWalletBalance
	insert into tblWhatsAppWalletBalance (
		Comp_Id, OldBal, NewBal, Amount, Cr_Dr_Type, ReqDate, Updated_date, Remarks, PaymentGatewayTxnId, Status
	) values (
		@Comp_Id, @oldBal, @newBal, @Amount, @Type, GETDATE(), GETDATE(), @Remarks, @PaymentGatewayTxnId, @Status
	)
	
	select SCOPE_IDENTITY() as TransactionId, @newBal as NewBalance
end
GO
