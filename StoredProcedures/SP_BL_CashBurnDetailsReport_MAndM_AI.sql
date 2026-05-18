USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Description: Cash Burn Details Report for Mahindra & Mahindra (Comp-1152)
-- exec [dbo].[SP_BL_CashBurnDetailsReport_MAndM_AI] 'Comp-1152',1,10,0
CREATE OR ALTER PROCEDURE [dbo].[SP_BL_CashBurnDetailsReport_MAndM_AI]
(
    @Comp_Id NVARCHAR(15) = NULL,
    @CompId NVARCHAR(15) = NULL,
    @Page INT = NULL,
    @Limit INT = NULL,
    @IsExport BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Normalize company ID parameter name
    IF @Comp_Id IS NULL AND @CompId IS NOT NULL
        SET @Comp_Id = @CompId;

    ---------------------------------------------------------
    -- Validate Comp_Id
    ---------------------------------------------------------
    IF (@Comp_Id IS NULL OR LTRIM(RTRIM(@Comp_Id)) = '')
    BEGIN
        RAISERROR('Comp_Id is required', 16, 1);
        RETURN;
    END

    ---------------------------------------------------------
    -- SBU Company Check Logic
    ---------------------------------------------------------
    DECLARE @ActualCompId NVARCHAR(15) = @Comp_Id;
    DECLARE @IsSBUTeam INT = 0;

    IF EXISTS (SELECT 1 FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM')
    BEGIN
        SELECT @ActualCompId = MainCompID FROM tbl_sbuCompany WHERE SubComp_ID = @Comp_Id AND SubCompTypeType = 'SBUTEAM';
        SET @IsSBUTeam = 1;
    END

    ---------------------------------------------------------
    -- Normalize inputs
    ---------------------------------------------------------
    SET @IsExport = ISNULL(@IsExport, 0);

    IF @Page IS NULL OR @Page < 1 SET @Page = 1;
    IF @Limit IS NULL OR @Limit < 1 SET @Limit = 10;
    IF @Limit > 500 SET @Limit = 500;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Aggregate Monthly Data (materialized once)
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#MonthAgg') IS NOT NULL DROP TABLE #MonthAgg;

    SELECT 
       SchemeName, Lot, RedemptionPeriod, ApprovalDate, CountOfUser, ApprovalGrossAmount, GrossAmount, TDSDeducted, NetPaidAmount, NoOfUserPaidSuccessful, TransactionDates
    INTO #MonthAgg
    FROM cash_burn_reportMN WITH (NOLOCK)
    -- WHERE CompId = @CompId -- Assuming the table is already filtered or has a CompId column if shared

    ---------------------------------------------------------
    -- EXPORT MODE → ALL MONTHS
    ---------------------------------------------------------
    IF (@IsExport = 1)
    BEGIN
        SELECT
             SchemeName, Lot, RedemptionPeriod, ApprovalDate, CountOfUser, ApprovalGrossAmount, GrossAmount, TDSDeducted, NetPaidAmount, NoOfUserPaidSuccessful, TransactionDates
        FROM #MonthAgg
        ORDER BY TransactionDates DESC;

        RETURN;
    END

    ---------------------------------------------------------
    -- NORMAL MODE → PAGINATION
    ---------------------------------------------------------
    SELECT
         SchemeName, Lot, RedemptionPeriod, ApprovalDate, CountOfUser, ApprovalGrossAmount, GrossAmount, TDSDeducted, NetPaidAmount, NoOfUserPaidSuccessful, TransactionDates
    FROM #MonthAgg
    ORDER BY TransactionDates DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

    ---------------------------------------------------------
    -- META DATA
    ---------------------------------------------------------
    SELECT
        COUNT(1) AS TotalRecords,
        @Page AS CurrentPage,
        @Limit AS [Limit],
        CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
    FROM #MonthAgg;

    DROP TABLE IF EXISTS #MonthAgg;
END;
GO
