USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Apr-2026
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

    IF @ApproveStatus = 'Reject'
    BEGIN
        -- Update existing record
        UPDATE [dbo].[WarrentyDetails]
        SET [IsWarrantyClaimed] = 2,
            [VendorClaimStatus] = @ApproveStatus,
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
    END
    ELSE
    BEGIN
        -- Update existing record for approval
        UPDATE [dbo].[WarrentyDetails]
        SET [IsWarrantyClaimed] = 1,
            [VendorClaimStatus] = @ApproveStatus,
            [VendorComments] = @Comment
        WHERE id = @Id;
    END

    SELECT 1 AS Success, 'Warranty claim processed successfully' AS Message;
END
GO
