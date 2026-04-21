/****** Object:  StoredProcedure [dbo].[USP_GetClaimMaster_AI]    Script Date: 4/13/2026 12:35:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antigravity
-- Create date: 4/13/2026
-- Description:	Fetches all claim types from tbl_ClaimMaster
-- =============================================
CREATE PROCEDURE [dbo].[USP_GetClaimMaster_AI]
AS
BEGIN
	SET NOCOUNT ON;

    SELECT [Id], [ClaimName]
    FROM [dbo].[tbl_ClaimMaster]
END
GO
