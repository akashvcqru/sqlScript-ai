-- =============================================
-- SQL Script: Create UDTT and Stored Procedure for Mahindra Redemption Upload
-- =============================================

-- 1. Drop referencing Stored Procedure first if it exists
IF OBJECT_ID('USP_UploadMahindraRedemptionSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_UploadMahindraRedemptionSheet_AI
GO

-- 2. Drop User-Defined Table Type if it exists
IF EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_MahindraRedemptionUpload' AND is_table_type = 1)
BEGIN
    DROP TYPE [dbo].[UDTT_MahindraRedemptionUpload]
END
GO

-- 3. Create User-Defined Table Type with new columns
CREATE TYPE [dbo].[UDTT_MahindraRedemptionUpload] AS TABLE(
    [CustomerName] [varchar](100) NULL,
    [BankName] [varchar](100) NULL,
    [AccountNumber] [varchar](100) NULL,
    [IFSCCode] [varchar](20) NULL,
    [Amount] [decimal](18, 2) NULL,
    [TransctionNumber] [varchar](100) NULL,
    [TransactionDate] [datetime] NULL,
    [MobileNumber] [varchar](15) NULL,
    [City] [varchar](200) NULL,
    [RawAmount] [varchar](50) NULL,
    [RawTransactionDate] [varchar](50) NULL,
    [TransactionProcessDate] [datetime] NULL,
    [RawTransactionProcessDate] [varchar](50) NULL
)
GO

-- 4. Create Stored Procedure
CREATE PROCEDURE USP_UploadMahindraRedemptionSheet_AI
    @Comp_id          NVARCHAR(255),
    @RedemptionTable  [dbo].[UDTT_MahindraRedemptionUpload] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StrippedCompId NVARCHAR(30) = REPLACE(@Comp_id, 'Comp-', '');

    -- Table to accumulate processing status for each record
    CREATE TABLE #UploadStatus (
        CustomerName VARCHAR(100),
        BankName VARCHAR(100),
        AccountNumber VARCHAR(100),
        IFSCCode VARCHAR(20),
        Amount VARCHAR(50),
        TransctionNumber VARCHAR(100),
        TransactionDate VARCHAR(50),
        TransactionProcessDate VARCHAR(50),
        MobileNumber VARCHAR(15),
        City VARCHAR(200),
        Status VARCHAR(20),
        ErrorMessage VARCHAR(255)
    );

    BEGIN TRY
        -- 1. Identify Already Existing records
        INSERT INTO #UploadStatus
        SELECT 
            [CustomerName], [BankName], [AccountNumber], [IFSCCode], [RawAmount], [TransctionNumber], [RawTransactionDate], [RawTransactionProcessDate], [MobileNumber], [City],
            'Already', 'Record already exists'
        FROM @RedemptionTable t
        WHERE EXISTS (
            SELECT 1 FROM Transactions WITH (NOLOCK)
            WHERE TransctionNumber = t.TransctionNumber AND CompId = @StrippedCompId
        );

        -- 2. Identify records that Fail due to unregistered or inactive mobile number in M_consumer
        INSERT INTO #UploadStatus
        SELECT 
            [CustomerName], [BankName], [AccountNumber], [IFSCCode], [RawAmount], [TransctionNumber], [RawTransactionDate], [RawTransactionProcessDate], [MobileNumber], [City],
            'Failed', 'Insert failed. Mobile number might not be registered or active in M_consumer.'
        FROM @RedemptionTable t
        WHERE NOT EXISTS (
            SELECT 1 FROM #UploadStatus WHERE TransctionNumber = t.TransctionNumber
        )
        AND NOT EXISTS (
            SELECT 1 FROM M_consumer b WITH (NOLOCK)
            WHERE RIGHT(CAST(CAST(t.MobileNumber AS BIGINT) AS VARCHAR(20)), 10) = RIGHT(b.MobileNo, 10)
              AND b.IsDelete = '0'
        );

        -- 3. Perform Insertions for valid records
        INSERT INTO Transactions
        (M_CounserID, CustomerName, BankName, AccountNumber, IFSCCode, Amount,
         TransctionNumber, TransactionProcessDate, TransactionDate, CompId, MobileNumber, IsSuccess, City)
        SELECT 
            b.M_Consumerid,
            t.CustomerName,
            t.BankName,
            t.AccountNumber,
            t.IFSCCode,
            t.Amount,
            t.TransctionNumber,
            t.TransactionProcessDate,
            t.TransactionDate,
            @StrippedCompId,
            '91' + RIGHT(t.MobileNumber, 10),
            1,
            t.City
        FROM @RedemptionTable t
        INNER JOIN M_consumer b WITH (NOLOCK) ON RIGHT(CAST(CAST(t.MobileNumber AS BIGINT) AS VARCHAR(20)), 10) = RIGHT(b.MobileNo, 10)
        WHERE b.IsDelete = '0'
          AND NOT EXISTS (
              SELECT 1 FROM #UploadStatus WHERE TransctionNumber = t.TransctionNumber
          );

        -- 4. Mark inserted records as Success
        INSERT INTO #UploadStatus
        SELECT 
            [CustomerName], [BankName], [AccountNumber], [IFSCCode], [RawAmount], [TransctionNumber], [RawTransactionDate], [RawTransactionProcessDate], [MobileNumber], [City],
            'Success', ''
        FROM @RedemptionTable t
        WHERE NOT EXISTS (
            SELECT 1 FROM #UploadStatus WHERE TransctionNumber = t.TransctionNumber
        );

        -- Return status report
        SELECT * FROM #UploadStatus;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        
        -- Fallback: return error status for any rows not yet categorized
        SELECT 
            [CustomerName], [BankName], [AccountNumber], [IFSCCode], [RawAmount] AS Amount, [TransctionNumber], [RawTransactionDate] AS TransactionDate, [RawTransactionProcessDate] AS TransactionProcessDate, [MobileNumber], [City],
            'Failed' AS Status, 'Database error during insertion: ' + @ErrorMessage AS ErrorMessage
        FROM @RedemptionTable t
        WHERE NOT EXISTS (
            SELECT 1 FROM #UploadStatus WHERE TransctionNumber = t.TransctionNumber
        );
    END CATCH

    DROP TABLE #UploadStatus;
END
GO
