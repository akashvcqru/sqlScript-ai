SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_GetConsumerKYCStatus_BL_AI]
@MobileNo VARCHAR(15)
AS
BEGIN
SET NOCOUNT ON;
SELECT 
	mc.M_Consumerid,
	mc.Vrkabel_User_Type,
	mc.Role_ID,
    CASE WHEN CAST(mc.panekycStatus AS NVARCHAR(50)) = '1' OR CAST(mc.panekycStatus AS NVARCHAR(50)) = 'Online' THEN '1' ELSE '0' END AS panekycStatus,
    CASE WHEN CAST(mc.aadharkycStatus AS NVARCHAR(50)) = '1' OR CAST(mc.aadharkycStatus AS NVARCHAR(50)) = 'Online' THEN '1' ELSE '0' END AS aadharkycStatus,
    CASE WHEN CAST(mc.bankekycStatus AS NVARCHAR(50)) = '1' OR CAST(mc.bankekycStatus AS NVARCHAR(50)) = 'Online' THEN '1' ELSE '0' END AS bankekycStatus,
    CASE WHEN CAST(mc.UPIKYCSTATUS AS NVARCHAR(50)) = '1' OR CAST(mc.UPIKYCSTATUS AS NVARCHAR(50)) = 'Online' THEN '1' ELSE '0' END AS UPIKYCSTATUS,
    ISNULL(vc.VRKbl_KYC_status, ISNULL(mc.VRKbl_KYC_status, '0')) AS VRKbl_KYC_status,
    '0' AS Manual_KYC_Status
FROM M_Consumer mc 
LEFT JOIN tbl_Vendorvisekycstatus vc ON vc.M_consumerId = mc.M_Consumerid 
WHERE RIGHT(mc.MobileNo, 10) = RIGHT(@MobileNo, 10) AND mc.IsDelete = 0
END
GO
