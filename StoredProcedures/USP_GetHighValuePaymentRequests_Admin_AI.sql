USE [vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-07-03
-- Description: Retrieves high value payment requests from ClaimDetails with fallback to DEFAULT limit.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetHighValuePaymentRequests_Admin_AI]
(
      @Compid           NVARCHAR(50) = NULL,   -- Optional company filter
      @FromDate         DATE = NULL,
      @ToDate           DATE = NULL,
      @datePreset       NVARCHAR(20) = NULL,
      @Search           NVARCHAR(50) = NULL,   -- Search parameter (mobile, claim ID, or bank reference)
      @Page             INT = 1,
      @Limit            INT = 10,
      @IsExport         BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DROP TABLE IF EXISTS #FinalData;

    CREATE TABLE #FinalData (
        ClaimId INT NOT NULL,
        ClaimDate DATETIME NOT NULL,
        MobileNo VARCHAR(15) NULL,
        Amount DECIMAL(18, 2) NULL,
        CompName NVARCHAR(150) NULL,
        CompId VARCHAR(50) NULL,
        IsApproved INT NOT NULL,
        VendorComment NVARCHAR(MAX) NULL,
        [UpiId/AC] VARCHAR(100) NULL,
        PaymentRemarks NVARCHAR(MAX) NULL,
        PaymentStatus VARCHAR(50) NULL,
        ClaimMode NVARCHAR(200) NULL
    );

    -- Date window resolution
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(ISNULL(@datePreset,''));

    IF @FromDate IS NOT NULL AND @ToDate IS NOT NULL
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = DATEADD(DAY, 1, @ToDate);
    END
    ELSE
    BEGIN
        IF @Win = 'TODAY'
        BEGIN
            SET @StartDate = @Today;
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'LASTDAY'
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @Today);
            SET @EndDate   = @Today;
        END
        ELSE IF @Win = 'WEEK'
        BEGIN
            SET DATEFIRST 1;
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE IF @Win = 'MONTH'
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
        ELSE
        BEGIN
            -- Default to last 30 days
            SET @StartDate = DATEADD(DAY, -30, @Today);
            SET @EndDate   = DATEADD(DAY, 1, @Today);
        END
    END

    -- Fetch high value claims prioritizing company threshold or falling back to default threshold
    INSERT INTO #FinalData (ClaimId, ClaimDate, MobileNo, Amount, CompName, CompId, IsApproved, VendorComment, [UpiId/AC], PaymentRemarks, PaymentStatus, ClaimMode)
    SELECT
        cd.Row_id AS ClaimId,
        cd.Claim_date AS ClaimDate,
        cd.Mobileno AS MobileNo,
        CAST(cd.RequestAmmount AS DECIMAL(18,2)) AS Amount,
        ISNULL(c.Comp_Name, 'Unknown') AS CompName,
        cd.Comp_id AS CompId,
        cd.Isapproved AS IsApproved,
        cd.vendor_comment AS VendorComment,
        ISNULL(cd.UPIID, cd.BankRefID) AS [UpiId/AC],
        cd.PaymentRemarks AS PaymentRemarks,
        CASE WHEN cd.Isapproved = 1 THEN 'Approved' WHEN cd.Isapproved = 2 THEN 'Rejected' ELSE 'Pending' END AS PaymentStatus,
        cd.Claim_mode AS ClaimMode
    FROM ClaimDetails cd WITH (NOLOCK)
    LEFT JOIN Comp_Reg c WITH (NOLOCK) ON c.Comp_ID = cd.Comp_id
    WHERE cd.Claim_date >= @StartDate
      AND cd.Claim_date < @EndDate
      AND (@Compid IS NULL OR cd.Comp_id = @Compid)
      AND cd.IsHighValue = 1
      AND cd.Isapproved = 0
      AND (
          @Search IS NULL 
          OR cd.Mobileno LIKE '%' + @Search + '%' 
          OR CAST(cd.Row_id AS VARCHAR(20)) = @Search 
          OR cd.UPIID LIKE '%' + @Search + '%'
          OR cd.BankRefID LIKE '%' + @Search + '%'
      );

    DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM #FinalData);

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #FinalData
        ORDER BY CASE WHEN IsApproved = 0 THEN 0 ELSE 1 END ASC, ClaimDate DESC;
    END
    ELSE
    BEGIN
        DECLARE @Offset INT = (@Page - 1) * @Limit;

        SELECT * FROM #FinalData
        ORDER BY CASE WHEN IsApproved = 0 THEN 0 ELSE 1 END ASC, ClaimDate DESC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;

        -- Metadata
        SELECT 
            @TotalRecords AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS Limit,
            CAST(CEILING(CAST(@TotalRecords AS DECIMAL) / @Limit) AS INT) AS TotalPages;
    END
END
GO
