USE [vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-07-03
-- Description: Adds or updates the high-value configuration threshold for a company.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_AddUpdateHighValuePaymentConfig_AI]
(
    @Comp_ID VARCHAR(50),
    @Amount DECIMAL(18,2),
    @Isactive BIT
)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM tbl_HighValuePaymentConfig WHERE Comp_ID = @Comp_ID)
    BEGIN
        UPDATE tbl_HighValuePaymentConfig
        SET Amount = @Amount,
            Isactive = @Isactive
        WHERE Comp_ID = @Comp_ID;
    END
    ELSE
    BEGIN
        INSERT INTO tbl_HighValuePaymentConfig (Comp_ID, Amount, Isactive, Created_Date)
        VALUES (@Comp_ID, @Amount, @Isactive, GETDATE());
    END
END
GO
