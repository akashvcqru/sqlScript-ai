-- =============================================
-- SQL Script: Create UDTT and Stored Procedure for Mahindra Code Status Upload
-- =============================================

-- 1. Create User-Defined Table Type if it does not exist
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_MahindraCodeStatusUpload' AND is_table_type = 1)
BEGIN
    CREATE TYPE [dbo].[UDTT_MahindraCodeStatusUpload] AS TABLE(
        [CompleteCode] [nvarchar](50) NULL,
        [TransactionStatus] [nvarchar](100) NULL,
        [TransactionDate] [datetime] NULL
    )
END
GO

-- 2. Create or Alter Stored Procedure
IF OBJECT_ID('USP_UploadMahindraCodeStatusSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_UploadMahindraCodeStatusSheet_AI
GO

CREATE PROCEDURE USP_UploadMahindraCodeStatusSheet_AI
    @CodeStatusTable  [dbo].[UDTT_MahindraCodeStatusUpload] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #UploadStatus (
        CompleteCode NVARCHAR(50),
        TransactionStatus NVARCHAR(100),
        Status NVARCHAR(20),
        ErrorMessage NVARCHAR(255)
    );

    BEGIN TRY
        -- 1. Identify Already Existing records
        INSERT INTO #UploadStatus
        SELECT 
            CompleteCode, TransactionStatus, 'Already Exist', 'Record already exists in database.'
        FROM @CodeStatusTable t
        WHERE EXISTS (
            SELECT 1 FROM Transaction_status WITH (NOLOCK)
            WHERE Complete_code = CAST(t.CompleteCode AS NUMERIC(18,0))
        );

        -- 2. Perform insertions of new records
        INSERT INTO Transaction_status (Complete_code, Transaction_Status, Transaction_date)
        SELECT 
            CAST(CompleteCode AS NUMERIC(18,0)), TransactionStatus, TransactionDate
        FROM @CodeStatusTable t
        WHERE NOT EXISTS (
            SELECT 1 FROM #UploadStatus WHERE CompleteCode = t.CompleteCode
        );

        -- 3. Mark inserted records as Success
        INSERT INTO #UploadStatus
        SELECT 
            CompleteCode, TransactionStatus, 'Success', ''
        FROM @CodeStatusTable t
        WHERE NOT EXISTS (
            SELECT 1 FROM #UploadStatus WHERE CompleteCode = t.CompleteCode
        );

        -- Return status report
        SELECT * FROM #UploadStatus;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        SELECT 
            CompleteCode, TransactionStatus, 'Failed' AS Status, 'Database error during insertion: ' + @ErrorMessage AS ErrorMessage
        FROM @CodeStatusTable t
        WHERE NOT EXISTS (
            SELECT 1 FROM #UploadStatus WHERE CompleteCode = t.CompleteCode
        );
    END CATCH

    DROP TABLE #UploadStatus;
END
GO
