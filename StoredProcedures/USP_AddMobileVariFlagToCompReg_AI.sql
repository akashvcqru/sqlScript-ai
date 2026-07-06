-- =============================================
-- Script Name: USP_AddMobileVariFlagToCompReg_AI
-- Created Date: 2026-07-02
-- Description: Alters Comp_Reg table to add Mobile_Vari_Flag column if it does not exist.
-- =============================================

IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Comp_Reg' 
      AND COLUMN_NAME = 'Mobile_Vari_Flag'
)
BEGIN
    ALTER TABLE Comp_Reg 
    ADD Mobile_Vari_Flag NUMERIC(18, 0) NULL;
    
    PRINT 'Mobile_Vari_Flag column successfully added to Comp_Reg table';
END
ELSE
BEGIN
    PRINT 'Mobile_Vari_Flag column already exists in Comp_Reg table';
END
GO
