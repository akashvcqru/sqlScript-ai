CREATE PROCEDURE [dbo].[USP_GetKYCStatus_MAndM_AI] (@ConsumerID INT)  
AS  
BEGIN  
SELECT TOP 1
       IsKycApproved,
       D_Status
FROM
(
    SELECT 
        vc.VRKbl_KYC_status AS IsKycApproved,
        D_Status AS D_Status
    FROM m_dealermaster dm
    right JOIN M_Consumer mc
        ON mc.distributorID = dm.DealerCode
       AND mc.employeeID   = dm.DealerTechnicianId
    INNER JOIN tbl_Vendorvisekycstatus vc
        ON vc.M_consumerId = mc.M_Consumerid
    WHERE vc.M_ConsumerId = @ConsumerID
      AND vc.Comp_id = 'Comp-1152'

    UNION ALL

    SELECT 
        vc.VRKbl_KYC_status AS IsKycApproved,
        D_Status AS D_Status
    FROM m_dealermaster_mahindra_emp dm
    right JOIN M_Consumer mc
        ON mc.distributorID = dm.DealerCode
       AND mc.employeeID   = dm.DealerTechnicianId
    INNER JOIN tbl_Vendorvisekycstatus vc
        ON vc.M_consumerId = mc.M_Consumerid
    WHERE vc.M_ConsumerId = @ConsumerID
      AND vc.Comp_id = 'Comp-1152'
) A;
END
GO
