SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_GetConsumerKYCStatus_BL_AI]
@MobileNo VARCHAR(15)
AS
BEGIN
SELECT 
    mc.Kyc_status AS user_kyc_status,
    mc.bank_status,
    mc.upi_status,
    mc.GST_Status,
    mc.adharpancard_status,
    mc.adharpancard_remark,
    mc.bank_remark,
    mc.upi_remark,
    mc.GST_Remark,
	mc.Is_Update_Profile,
	mc.M_Consumerid,
	mc.Vrkabel_User_Type,
	mc.Role_ID
FROM M_Consumer mc 
WHERE mc.MobileNo = @MobileNo
END
GO
