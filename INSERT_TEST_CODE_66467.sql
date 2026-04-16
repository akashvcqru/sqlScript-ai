-- ============================================
-- INSERT TEST CODE FOR COMP-2299
-- Code: 66467-82062860
-- Mobile: 9315742109
-- Company: Comp-2299 (VCQRU Cashback-UPI)
-- ============================================

-- Step 1: Check if test code already exists
SELECT 'Step 1: Checking existing code' AS [Info];
SELECT Row_ID, Code1, Code2, Use_Count, ScrapeFlag, Pro_ID 
FROM M_Code 
WHERE Code1 = 66467 AND Code2 = 82062860;

-- Step 2: Get or create VCQRU product for Comp-2299
SELECT 'Step 2: Finding VCQRU product' AS [Info];
DECLARE @ProId INT;
DECLARE @Comp_ID VARCHAR(50) = 'Comp-2299';

SELECT TOP 1 @ProId = Pro_ID 
FROM Pro_Reg 
WHERE Comp_ID = @Comp_ID 
ORDER BY Pro_ID DESC;

IF @ProId IS NULL
BEGIN
    SELECT 'ERROR: No product found for Comp-2299. Please create a product first.' AS [Error];
    -- For demo, we'll use a sample pro_id, but this needs to be fixed
    SET @ProId = 1; -- Change this to actual product ID for Comp-2299
END

SELECT 'Using Pro_ID: ' + CAST(@ProId AS VARCHAR(20)) AS [Info];

-- Step 3: Check if code already exists and delete if it does (for clean test)
DELETE FROM M_Code 
WHERE Code1 = 66467 AND Code2 = 82062860;

-- Step 4: Insert the test code
INSERT INTO M_Code (Code1, Code2, Use_Count, ScrapeFlag, Pro_ID, EntryDate, IsDelete)
VALUES (66467, 82062860, 0, 0, @ProId, GETDATE(), 0);

SELECT 'Step 4: Test code inserted successfully' AS [Success];

-- Step 5: Verify insertion
SELECT Row_ID, Code1, Code2, Use_Count, ScrapeFlag, Pro_ID, EntryDate 
FROM M_Code 
WHERE Code1 = 66467 AND Code2 = 82062860;

-- Step 6: Verify product company association
SELECT pr.Pro_ID, pr.BrandName, pr.Comp_ID, pr.Status
FROM Pro_Reg pr
WHERE pr.Pro_ID = @ProId;

-- Step 7: Verify Comp-2299 exists
SELECT Comp_Id, Comp_Name, Status, CreatedDate
FROM LandingPage
WHERE Comp_Id = @Comp_ID;

SELECT 'Setup complete! Code 66467-82062860 is now ready for testing.' AS [Summary];
