CREATE OR ALTER PROCEDURE USP_UpdateClaimDetailsExcelUpload_AI
    @Comp_ID VARCHAR(50),
    @JsonData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SuccessIDs TABLE (ClaimID INT);
    DECLARE @InputIDs TABLE (ClaimID INT, Isapproved INT, vendor_comment NVARCHAR(MAX), UPIID VARCHAR(100), BankRefID VARCHAR(200), PaymentRemarks VARCHAR(500), TransactionDate VARCHAR(100));

    BEGIN TRY
        INSERT INTO @InputIDs (ClaimID, Isapproved, vendor_comment, UPIID, BankRefID, PaymentRemarks, TransactionDate)
        SELECT 
            ClaimID, Isapproved, vendor_comment, UPIID, BankRefID, PaymentRemarks, TransactionDate
        FROM OPENJSON(@JsonData) WITH (
            ClaimID INT '$.ClaimID',
            vendor_comment NVARCHAR(MAX) '$.vendor_comment',
            UPIID VARCHAR(100) '$.UPIID',
            BankRefID VARCHAR(200) '$.BankRefID',
            PaymentRemarks VARCHAR(500) '$.PaymentRemarks',
            TransactionDate VARCHAR(100) '$.TransactionDate',
            Isapproved INT '$.Isapproved'
        );

        UPDATE CD
        SET 
            CD.Isapproved = J.Isapproved,
            CD.IsPaid = CASE WHEN J.Isapproved = 1 THEN 1 ELSE 0 END,
            CD.PaymentStatus = CASE WHEN J.Isapproved = 1 THEN 'Success' WHEN J.Isapproved = 2 THEN 'Rejected' END,
            CD.vendor_comment = J.vendor_comment,
            CD.UPIID = J.UPIID,
            CD.BankRefID = J.BankRefID,
            CD.PaymentRemarks = J.PaymentRemarks,
            CD.TransactionDate = J.TransactionDate
        OUTPUT inserted.Row_id INTO @SuccessIDs
        FROM ClaimDetails CD
        INNER JOIN @InputIDs J ON CD.Row_id = J.ClaimID AND CD.Comp_id = @Comp_ID
        WHERE J.Isapproved IN (1, 2);

        DECLARE @SuccessStr VARCHAR(MAX);
        DECLARE @FailedStr VARCHAR(MAX);
        DECLARE @SuccessCount INT;
        DECLARE @FailedCount INT;

        SELECT @SuccessStr = STRING_AGG(CAST(ClaimID AS VARCHAR(MAX)), ','), @SuccessCount = COUNT(ClaimID) FROM @SuccessIDs;
        SELECT @FailedStr = STRING_AGG(CAST(ClaimID AS VARCHAR(MAX)), ','), @FailedCount = COUNT(ClaimID) FROM @InputIDs WHERE ClaimID NOT IN (SELECT ClaimID FROM @SuccessIDs);

        SELECT 
            1 AS success, 
            'Claim successfully updated' AS message,
            ISNULL(@SuccessStr, '') AS SuccessClaimidID,
            ISNULL(@FailedStr, '') AS FailedClaimidID,
            ISNULL(@SuccessCount, 0) AS SuccessClaimidIDCount,
            ISNULL(@FailedCount, 0) AS FailedClaimidIDCount;
    END TRY
    BEGIN CATCH
        SELECT 
            0 AS success, 
            ERROR_MESSAGE() AS message,
            '' AS SuccessClaimidID,
            '' AS FailedClaimidID,
            0 AS SuccessClaimidIDCount,
            0 AS FailedClaimidIDCount;
    END CATCH
END
