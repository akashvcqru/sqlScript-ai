SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-07
-- Description: Inserts records into the Courier_Disp_ProInfo table.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertCourierDispatchDetail_AI]
    @Courier_Disp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50),
    @Label_Code NVARCHAR(50),
    @Label_Name NVARCHAR(50),
    @Series_From NVARCHAR(50),
    @Series_To NVARCHAR(50),
    @Qty DECIMAL(18, 0)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert into Courier_Disp_ProInfo
    INSERT INTO [dbo].[Courier_Disp_ProInfo] (
        [Courier_Disp_ID],
        [Pro_ID],
        [Label_Code],
        [Label_Name],
        [Series_From],
        [Series_To],
        [Qty]
    ) VALUES (
        @Courier_Disp_ID,
        @Pro_ID,
        @Label_Code,
        @Label_Name,
        @Series_From,
        @Series_To,
        @Qty
    );
END
GO
