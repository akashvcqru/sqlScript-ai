-- =============================================
-- SQL Script: Create Stored Procedure for Retrieving Mahindra Employee Uploaded Sheet
-- =============================================

IF OBJECT_ID('USP_GetMahindraEmployeeSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_GetMahindraEmployeeSheet_AI
GO

CREATE PROCEDURE USP_GetMahindraEmployeeSheet_AI
    @Comp_id    NVARCHAR(255),
    @Search     NVARCHAR(255) = NULL,
    @Page       INT = 1,
    @Limit      INT = 10,
    @IsExport   BIT = 0,
    @datePreset NVARCHAR(20) = NULL,
    @FromDate   DATETIME = NULL,
    @ToDate     DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Defaults
    IF ISNULL(@Page, 0) <= 0 SET @Page = 1;
    IF ISNULL(@Limit, 0) <= 0 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ---------------------------------------------------------
    -- Date range calculation
    ---------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    IF (
           @datePreset IS NULL
        OR LTRIM(RTRIM(@datePreset)) = ''
        OR LOWER(LTRIM(RTRIM(@datePreset))) = 'null'
    )
        SET @datePreset = NULL;
    ELSE
        SET @datePreset = UPPER(LTRIM(RTRIM(@datePreset)));

    DECLARE @Win NVARCHAR(50) = @datePreset;

    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1;

        IF (@Win = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@Win = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@Win = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@Win = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@Win = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);

        ELSE IF (@Win = 'YEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @EndDate = GETDATE();
        END
        ELSE IF (@Win = 'LASTYEAR')
        BEGIN
            SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END
        ELSE
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END

    -- CTE for filtered search data
    ;WITH FilteredRecords AS (
        SELECT 
            Zone, D_State, DealerCode, DealerType, DealerLocation, DealerTechnicianId, DE_Designation,
            EmpCode, EmpLocation, EmpName, MStarId, EmpUIDNo, EmpDesignaton, EmpBasedAt,
            BranchCategory, BranchType, Gender, FatherName, ContactNo, JoiningDate, DOB,
            Status, EmpKYCStatus, VendorCode, BankAccountNo, BankKycStatus, PanNo, PanKycStatus,
            IDNo, IDProof, BankKycUpdatedOn, PanCardKycUpdatedOn, BankKycProceedByAgencyOn,
            PanCardKycProceedByAgencyOn, SapVendorCodeConfirmationReadOn, AgencyRemarkBank,
            AgencyRemarkPancard, ResignedDate, Age, EmpCount, D_Status, Created_Date, Created_By,
            D_Name, Comp_id, Proprietor1, Proprietor2, Proprietor3
        FROM m_dealermaster_mahindra_emp WITH (NOLOCK)
        WHERE Comp_id = @Comp_id
          AND (@StartDate IS NULL OR Created_Date >= @StartDate)
          AND (@EndDate IS NULL OR Created_Date < DATEADD(DAY, 1, @EndDate))
          AND (@Search IS NULL OR @Search = ''
               OR EmpName LIKE '%' + @Search + '%'
               OR EmpCode LIKE '%' + @Search + '%'
               OR DealerCode LIKE '%' + @Search + '%'
               OR DealerTechnicianId LIKE '%' + @Search + '%'
               OR ContactNo LIKE '%' + @Search + '%')
    )
    SELECT * INTO #TempResults FROM FilteredRecords;

    DECLARE @TotalRecords INT;
    SELECT @TotalRecords = COUNT(*) FROM #TempResults;

    IF @IsExport = 1
    BEGIN
        SELECT * FROM #TempResults ORDER BY Created_Date DESC;
    END
    ELSE
    BEGIN
        SELECT * FROM #TempResults 
        ORDER BY Created_Date DESC
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
