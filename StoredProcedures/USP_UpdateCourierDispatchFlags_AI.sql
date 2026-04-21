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

    DECLARE @Tracking_No NVARCHAR(50);
    
    -- Get Tracking_No from Master table
    SELECT @Tracking_No = Tracking_No 
    FROM [dbo].[Courier_Dispatch_Master] 
    WHERE [Courier_Disp_ID] = @Courier_Disp_ID;

    -- Update M_Code or M_Code_PFL depending on Comp_ID
    IF @Comp_ID = 'Comp-1693'
    BEGIN
        UPDATE MC
        SET MC.[DispatchFlag] = 1,
            MC.[LabelRequestId] = @Tracking_No
        FROM [dbo].[M_Code_PFL] MC
        INNER JOIN [dbo].[Courier_Disp_ProInfo] CDPI ON MC.[Pro_ID] = CDPI.[Pro_ID]
        WHERE CDPI.[Courier_Disp_ID] = @Courier_Disp_ID;
    END
    ELSE
    BEGIN
        UPDATE MC
        SET MC.[DispatchFlag] = 1,
            MC.[LabelRequestId] = @Tracking_No
        FROM [dbo].[M_Code] MC
        INNER JOIN [dbo].[Courier_Disp_ProInfo] CDPI ON MC.[Pro_ID] = CDPI.[Pro_ID]
        WHERE CDPI.[Courier_Disp_ID] = @Courier_Disp_ID;
    END
END
GO
