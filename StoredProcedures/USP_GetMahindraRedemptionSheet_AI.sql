-- =============================================
-- SQL Script: Create Stored Procedure for Retrieving Mahindra Redemption Uploaded Sheet
-- =============================================

IF OBJECT_ID('USP_GetMahindraRedemptionSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetMahindraRedemptionSheet_AI
GO

CREATE PROCEDURE USP_GetMahindraRedemptionSheet_AI
    @Comp_id    NVARCHAR(255),
    @Search     NVARCHAR(255) = NULL,
    @Page       INT = 1,
    @Limit      INT = 10,
    @IsExport   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Defaults
    IF ISNULL(@Page, 0) <= 0 SET @Page = 1;
    IF ISNULL(@Limit, 0) <= 0 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;
    DECLARE @StrippedCompId NVARCHAR(255) = REPLACE(@Comp_id, 'Comp-', '');

    -- CTE for filtered search data
    ;WITH FilteredRecords AS (
        SELECT 
            TransactionsId,
            M_CounserID,
            CustomerName,
            BankName,
            AccountNumber,
            IFSCCode,
            Amount,
            TransctionNumber,
            TransactionProcessDate,
            TransactionDate,
            MobileNumber,
            Branch,
            Issuccess
        FROM Transactions WITH (NOLOCK)
        WHERE CompId = @StrippedCompId
          AND (@Search IS NULL OR @Search = ''
               OR CustomerName LIKE '%' + @Search + '%'
               OR BankName LIKE '%' + @Search + '%'
               OR AccountNumber LIKE '%' + @Search + '%'
               OR TransctionNumber LIKE '%' + @Search + '%'
               OR MobileNumber LIKE '%' + @Search + '%')
    )
    SELECT * INTO #TempResults FROM FilteredRecords;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #TempResults;

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #TempResults ORDER BY TransactionDate DESC;
    END
    ELSE
    BEGIN
        SELECT * FROM #TempResults 
        ORDER BY TransactionDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata output
        SELECT 
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CEILING(CAST(@TotalRecords AS FLOAT) / @Limit) AS TotalPages;
    END

    DROP TABLE #TempResults;
END
GO
