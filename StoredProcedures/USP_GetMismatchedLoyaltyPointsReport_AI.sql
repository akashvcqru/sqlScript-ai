-- =========================================================================================================
-- Author:      Antigravity
-- Create Date: 2026-07-08
-- Description: Retrieves count of mismatched loyalty codes per company where the first-scan record
--              is missing points/cash but duplicate scan records have them.
-- =========================================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetMismatchedLoyaltyPointsReport_AI]
    @CompId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        mc.Compid AS CompanyID,
        COUNT(DISTINCT mc.M_Consumer_MCodeid) AS MismatchedCodesCount
    FROM dbo.BuiltLoyaltyMCodeCheck b1 WITH (NOLOCK)
    INNER JOIN dbo.BuiltLoyaltyMCodeCheck b2 WITH (NOLOCK)
        ON b1.M_Consumer_MCOdeid = b2.M_Consumer_MCOdeid 
        AND b1.Pkid < b2.Pkid
    INNER JOIN M_Consumer_M_Code mc WITH (NOLOCK)
        ON b1.M_Consumer_MCOdeid = mc.M_Consumer_MCodeid
    INNER JOIN BLoyaltyPointsEarned e1 WITH (NOLOCK)
        ON e1.BuildLoyaltyOrReferralMCodeCheckid = b1.Pkid
    INNER JOIN BLoyaltyPointsEarned e2 WITH (NOLOCK)
        ON e2.BuildLoyaltyOrReferralMCodeCheckid = b2.Pkid
    WHERE (@CompId IS NULL OR mc.Compid = @CompId)
      AND (((e1.Points IS NULL OR e1.Points = 0) AND (e2.Points > 0))
           OR ((e1.Cash IS NULL OR e1.Cash = 0) AND (e2.Cash > 0)))
    GROUP BY mc.Compid
    ORDER BY MismatchedCodesCount DESC;
END
GO
