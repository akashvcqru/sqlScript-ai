-- Migration: Drop balance_amount column from Paytm_balance table if it exists
IF EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[Paytm_balance]') 
      AND name = 'balance_amount'
)
BEGIN
    ALTER TABLE [dbo].[Paytm_balance] DROP COLUMN [balance_amount];
    PRINT 'Column balance_amount dropped successfully from Paytm_balance table.';
END
ELSE
BEGIN
    PRINT 'Column balance_amount does not exist in Paytm_balance table.';
END
GO
