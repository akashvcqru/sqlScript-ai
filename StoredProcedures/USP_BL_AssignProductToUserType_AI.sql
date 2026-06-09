SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Antigravity
-- Create date: 2026-06-09
-- Description: Assign/Map products to a user type for a company
-- =============================================
CREATE PROCEDURE [dbo].[USP_BL_AssignProductToUserType_AI]
    @Row_ID INT,
    @ProductMapped VARCHAR(MAX),
    @Comp_ID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE User_Type
    SET ProductMapped = @ProductMapped
    WHERE Row_ID = @Row_ID AND Comp_ID = @Comp_ID;
END
GO
