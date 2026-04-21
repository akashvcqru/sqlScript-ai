SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antigravity AI
-- Create date: 2026-03-31
-- Description:	Stored procedure to get total loyalty points by brand for a consumer
-- =============================================
CREATE PROCEDURE USP_GetPointsByBrand_AI
	@ConsumerId VARCHAR(50),
	@CompId VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
		SUM(bl.Points) AS TotalPoints, 
		p.Brand_Code
	FROM 
		BLoyaltyPointsEarned bl
	INNER JOIN 
		M_Code m ON bl.Code1 = m.Code1 AND bl.Code2 = m.Code2
	INNER JOIN 
		Pro_Reg p ON m.Pro_ID = p.Pro_ID
	WHERE 
		M_Consumerid = @ConsumerId 
		AND bl.compid = @CompId
	GROUP BY 
		p.Brand_Code;
END
GO
