SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-07
-- Description: Updates DispatchFlag and LabelRequestId in the M_Code tables.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateCourierDispatchFlags_AI]
    @Comp_ID NVARCHAR(50),
    @Courier_Disp_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Flags are already updated with high precision inside USP_InsertCourierDispatchDetail_AI.
    -- This procedure is kept for compatibility with the controller call.
END
GO
