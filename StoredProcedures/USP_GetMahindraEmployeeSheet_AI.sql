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
    @IsExport   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Defaults
    IF ISNULL(@Page, 0) <= 0 SET @Page = 1;
    IF ISNULL(@Limit, 0) <= 0 SET @Limit = 10;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

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
