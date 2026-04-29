USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Apr-2026
-- Modified:    29-Apr-2026 (Use numeric ApproveStatus: 1=Approved, 2=Rejected)
-- Description: Handle Warranty Claim Approval or Rejection
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_WarrantyClaimApproveReject_AI]
(
    @Id INT,
    @ApproveStatus NVARCHAR(50),
    @Comment NVARCHAR(MAX)
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

    IF @ApproveStatus = '2' -- Rejected
    BEGIN
        -- Update existing record
        UPDATE [dbo].[WarrentyDetails]
        SET [IsWarrantyClaimed] = 2,
            [VendorClaimStatus] = 'Rejected',
            [VendorComments] = @Comment
        WHERE id = @Id;

        -- Insert new record for retry/re-entry
        INSERT INTO [dbo].[WarrentyDetails] (
            BillNo, PurchaseDate, Email, Mobile, WarrantyPeriod, ExpirationDate, 
            ImagePathBill, Code, claimdate, [State], City, DealerName, 
            VendorClaimStatus, Serialno, PurchaseFrom, Battary_volt, Brand, 
            Ratting, Pincode, [Address], Model, batryType
        )
        SELECT 
            BillNo, PurchaseDate, Email, Mobile, WarrantyPeriod, ExpirationDate, 
            ImagePathBill, Code, claimdate, [State], City, DealerName, 
            '', Serialno, PurchaseFrom, Battary_volt, Brand, 
            Ratting, Pincode, [Address], Model, batryType
        FROM [dbo].[WarrentyDetails]
        WHERE id = @Id;

        SELECT 1 AS Success, 'Warranty claim rejected successfully.' AS Message;
    END
    ELSE IF @ApproveStatus = '1' -- Approved
    BEGIN
        -- Update existing record for approval
        UPDATE [dbo].[WarrentyDetails]
        SET [IsWarrantyClaimed] = 1,
            [VendorClaimStatus] = 'Approved',
            [VendorComments] = @Comment
        WHERE id = @Id;

        SELECT 1 AS Success, 'Warranty claim approved successfully.' AS Message;
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid ApproveStatus. Use 1 for Approved or 2 for Rejected.' AS Message;
    END
END
GO
