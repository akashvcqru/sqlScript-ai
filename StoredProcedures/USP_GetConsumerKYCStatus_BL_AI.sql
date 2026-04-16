SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_GetConsumerKYCStatus_BL_AI]
@MobileNo VARCHAR(15)
AS
BEGIN
SELECT 
	mc.M_Consumerid,
	mc.Vrkabel_User_Type,
	mc.Role_ID,
    ISNULL(mc.panekycStatus, '0') AS panekycStatus,
    ISNULL(mc.aadharkycStatus, '0') AS aadharkycStatus,
    ISNULL(mc.bankekycStatus, '0') AS bankekycStatus,
    ISNULL(mc.UPIKYCSTATUS, 0) AS UPIKYCSTATUS,
    ISNULL(vc.VRKbl_KYC_status, ISNULL(mc.VRKbl_KYC_status, 0)) AS VRKbl_KYC_status,
    '0' AS Manual_KYC_Status
FROM M_Consumer mc 
left join tbl_Vendorvisekycstatus vc on vc.M_consumerId = mc.M_Consumerid 
WHERE mc.MobileNo = @MobileNo
END
GO
