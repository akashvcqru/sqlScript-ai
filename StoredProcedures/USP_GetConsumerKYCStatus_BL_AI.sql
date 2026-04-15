SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_GetConsumerKYCStatus_BL_AI]
@MobileNo VARCHAR(15)
AS
BEGIN
SELECT 
	mc.M_Consumerid,
	mc.Vrkabel_User_Type,
	mc.Role_ID,
    mc.panekycStatus,
    mc.aadharkycStatus,
    mc.bankekycStatus,
    mc.UPIKYCSTATUS,
    mc.VRKbl_KYC_status
FROM M_Consumer mc 
WHERE mc.MobileNo = @MobileNo
END
GO
