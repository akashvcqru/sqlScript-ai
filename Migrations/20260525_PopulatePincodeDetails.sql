-- Migration: Populate tbl_PincodeDetails from PincodeMaster and PinCodeList
-- 1. Copy from PincodeMaster
INSERT INTO tbl_PincodeDetails (Pincode, State, City, CreatedAt)
SELECT Pincode, State, City, COALESCE(CreatedAt, GETDATE())
FROM PincodeMaster
WHERE Pincode NOT IN (SELECT Pincode FROM tbl_PincodeDetails);

-- 2. Copy from PinCodeList for any pincodes not already present
INSERT INTO tbl_PincodeDetails (Pincode, State, City, CreatedAt)
SELECT PINCODE, MAX(STATE), MAX(DISTRICT), GETDATE()
FROM PinCodeList
WHERE PINCODE NOT IN (SELECT Pincode FROM tbl_PincodeDetails)
GROUP BY PINCODE;
GO
