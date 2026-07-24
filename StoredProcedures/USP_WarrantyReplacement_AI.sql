USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Jul-2026
-- Description: Update active serial numbers and log replacement history
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_WarrantyReplacement_AI]
(
    @Id INT,
    @NewSrNo VARCHAR(100),
    @OldSrNo VARCHAR(100),
    @CompId NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate that the warranty record exists
    IF NOT EXISTS (SELECT 1 FROM [dbo].[WarrentyDetails] WHERE id = @Id)
    BEGIN
        SELECT 0 AS Success, 'Warranty record not found.' AS Message;
        RETURN;
    END

    -- Update active serial numbers on WarrentyDetails
    UPDATE [dbo].[WarrentyDetails]
    SET [Serialno] = @NewSrNo,
        [OldSerialno] = @OldSrNo
    WHERE id = @Id;

    -- Insert into WarrentyReplacement log
    INSERT INTO [dbo].[WarrentyReplacement] (
        claim_id, BillNo, PurchaseDate, ExpirationDate, Code, NewSerialno, OldSerialno, Comp_ID
    )
    SELECT 
        @Id, BillNo, PurchaseDate, ExpirationDate, Code, @NewSrNo, @OldSrNo, @CompId
    FROM [dbo].[WarrentyDetails]
    WHERE id = @Id;

    SELECT 1 AS Success, 'Warranty replacement updated successfully.' AS Message;
END
GO
