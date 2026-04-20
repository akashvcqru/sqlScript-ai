USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetCreditHistory]    Script Date: 4/2/2026 8:23:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_GetCreditHistory_AI]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.*, b.Comp_Name 
    FROM dealer_credit_limits a 
	INNER JOIN comp_reg b ON a.comp_id = b.comp_id
	WHERE M_Consumerid = @UserId 
    ORDER BY last_updated_at DESC
END
GO
