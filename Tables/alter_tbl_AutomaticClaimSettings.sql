IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('tbl_AutomaticClaimSettings') AND name = 'ClaimType'
)
BEGIN
    ALTER TABLE tbl_AutomaticClaimSettings ADD ClaimType VARCHAR(50) NULL;
END
GO
