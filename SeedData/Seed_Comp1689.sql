-- Seed script for Comp-1689 Landing Page
-- This script adds a premium default configuration for testing.

DECLARE @Comp_Id VARCHAR(50) = 'Comp-1689';
DECLARE @Service_Id VARCHAR(50) = 'SRV1001'; -- Anti-Counterfeit/Verification

-- Delete existing if any (to allow re-runs)
DELETE FROM LandingPage_FieldConfig WHERE PageId IN (SELECT PageId FROM LandingPage WHERE Comp_Id = @Comp_Id);
DELETE FROM LandingPage WHERE Comp_Id = @Comp_Id;

-- Insert Landing Page
INSERT INTO LandingPage (
    Comp_Id, Service_Id, PageName, BrandName, ServiceType, 
    LogoUrl, BackgroundImageUrl, ProductImage1, IsActive, CreatedDate
)
VALUES (
    @Comp_Id, @Service_Id, 'Premium Verification Portal', 'VCQRU Global', 'Anti-Counterfeit', 
    'https://www.vcqru.com/newContent/front-assets/img/vcqru-logo.png', 
    'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2029&auto=format&fit=crop', -- Sample abstract background
    'https://www.vcqru.com/assets/images/product-placeholder.png',
    1, GETDATE()
);

DECLARE @PageId INT = SCOPE_IDENTITY();

-- Insert Field Configurations
-- FieldId mapping (Assuming standard IDs from Master_InputFieldsWeb):
-- 1: Mobile (Required)
-- 2: ConsumerName (Required)
-- 3: PinCode (Required)
-- 4: City (Optional/Auto)
-- 5: State (Optional/Auto)

INSERT INTO LandingPage_FieldConfig (PageId, FieldId, IsRequired, DisplayOrder, IsVisible, CustomLabel, CreatedDate)
VALUES 
(@PageId, 1, 1, 1, 1, 'Mobile Number', GETDATE()),
(@PageId, 2, 1, 2, 1, 'Full Name', GETDATE()),
(@PageId, 3, 1, 3, 1, 'Pincode', GETDATE()),
(@PageId, 4, 0, 4, 1, 'City', GETDATE()),
(@PageId, 5, 0, 5, 1, 'State', GETDATE());

SELECT 'Seed complete for ' + @Comp_Id as [Status];
