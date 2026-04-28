SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- exec [dbo].[SP_BL_GetKYCSetting_AI] 'Comp-1152'
CREATE PROCEDURE [dbo].[SP_BL_GetKYCSetting_AI]
(
    @Comp_Id VARCHAR(15)
)
AS
BEGIN
   SET NOCOUNT ON;

    SELECT 
        kyc_Details AS KycSetting
    FROM claimKycForWebMVC
    WHERE Comp_ID = @Comp_Id;
END;
GO
