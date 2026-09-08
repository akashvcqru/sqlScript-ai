-- Migration: Fix CreditCashBalance stored procedure for negative balance handling
-- Issue: When a vendor has a negative balance (e.g. -243.50), the SP had 'else if (@OldBlance >= 0)'
-- which skipped the UPDATE Paytm_balance statement completely.

USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[CreditCashBalance]
    @Comp_ID VARCHAR(50),
    @Amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldBalance DECIMAL(18,2);
    SELECT @OldBalance = SUM(Amount) FROM Paytm_balance WHERE Comp_ID = @Comp_ID;

    IF (@OldBalance IS NULL)
    BEGIN
        SET @OldBalance = 0;
        INSERT INTO Paytm_balance (Comp_ID, Amount, Updated_date)
        VALUES (@Comp_ID, @Amount, GETDATE());
    END
    ELSE
    BEGIN
        UPDATE Paytm_balance 
        SET Amount = Amount + @Amount, 
            Updated_date = GETDATE() 
        WHERE Comp_ID = @Comp_ID;
    END

    DECLARE @NewBalance DECIMAL(18,2) = @OldBalance + @Amount;

    INSERT INTO tblCashWalletBalance (Comp_Id, OldBal, NewBal, Amount, Cr_Dr_Type, ReqDate)
    VALUES (@Comp_ID, @OldBalance, @NewBalance, @Amount, 'Credit', GETDATE());

    SELECT ISNULL(SUM(Amount), 0) AS Amount 
    FROM Paytm_balance 
    WHERE Comp_ID = @Comp_ID;
END
GO
