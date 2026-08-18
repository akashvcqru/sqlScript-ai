-- =============================================
-- Script Name: USP_AddMobileVariFlagToCompReg_AI
-- Created Date: 2026-07-02
-- Description: Alters Comp_Reg table to add Mobile_Vari_Flag column if it does not exist.
-- =============================================

IF OBJECT_ID(N'[dbo].[Comp_Reg]', N'U') IS NOT NULL AND NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Comp_Reg]')
      AND name = 'Mobile_Vari_Flag'
)
BEGIN
    ALTER TABLE [dbo].[Comp_Reg] 
    ADD Mobile_Vari_Flag NUMERIC(18, 0) NULL;
    
    PRINT 'Mobile_Vari_Flag column successfully added to Comp_Reg table';
END
GO
