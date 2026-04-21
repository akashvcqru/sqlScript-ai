USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_GetReferralDetails_BL_AI]    Script Date: 4/1/2026 9:16:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_GetReferralDetails_BL_AI]    
    @M_Consumerid INT,    
    @Comp_ID VARCHAR(50)    
AS    
BEGIN    
    SELECT     
        mc.ConsumerName,    
        mc.Entry_Date,    
        'Success' AS [Status],
		bl.Points AS Points
    FROM     
        M_Consumer mc
		INNER JOIN (SELECT M_Consumerid, Points FROM BLoyaltyPointsEarned WHERE ServiceName = 'Referral') bl ON bl.M_Consumerid = mc.M_Consumerid
    WHERE     
        mc.MobileNo IN (    
            SELECT     
                r.ReferralMobileNo     
            FROM     
                tbl_Vendorvisekycstatus vc    
            INNER JOIN     
                tbl_Referral r ON vc.Referral_Code = r.ref_code   
            WHERE     
                vc.M_Consumerid = @M_Consumerid     
                AND r.Comp_ID = @Comp_ID    
        );    
END;
GO
