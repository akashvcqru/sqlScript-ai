-- =============================================
-- SQL Script: Create UDTT and Stored Procedure for Mahindra Employee Upload
-- =============================================

-- 1. Create User-Defined Table Type if it does not exist
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_MahindraEmployeeUpload' AND is_table_type = 1)
BEGIN
    CREATE TYPE [dbo].[UDTT_MahindraEmployeeUpload] AS TABLE(
        [Zone] [varchar](255) NULL,
        [D_State] [varchar](50) NULL,
        [DealerCode] [varchar](20) NULL,
        [DealerType] [varchar](255) NULL,
        [DealerLocation] [varchar](200) NULL,
        [DealerTechnicianId] [varchar](20) NULL,
        [DE_Designation] [varchar](50) NULL,
        [EmpCode] [varchar](255) NULL,
        [EmpLocation] [varchar](200) NULL,
        [EmpName] [varchar](200) NULL,
        [MStarId] [varchar](30) NULL,
        [EmpUIDNo] [varchar](255) NULL,
        [EmpDesignaton] [varchar](200) NULL,
        [EmpBasedAt] [varchar](255) NULL,
        [BranchCategory] [varchar](200) NULL,
        [BranchType] [varchar](200) NULL,
        [Gender] [varchar](255) NULL,
        [FatherName] [varchar](200) NULL,
        [ContactNo] [varchar](150) NULL,
        [JoiningDate] [varchar](255) NULL,
        [DOB] [varchar](255) NULL,
        [Status] [varchar](200) NULL,
        [EmpKYCStatus] [varchar](200) NULL,
        [VendorCode] [varchar](255) NULL,
        [BankAccountNo] [varchar](255) NULL,
        [BankKycStatus] [varchar](200) NULL,
        [PanNo] [varchar](255) NULL,
        [PanKycStatus] [varchar](255) NULL,
        [IDNo] [varchar](255) NULL,
        [IDProof] [varchar](255) NULL,
        [BankKycUpdatedOn] [varchar](255) NULL,
        [PanCardKycUpdatedOn] [varchar](255) NULL,
        [BankKycProceedByAgencyOn] [varchar](255) NULL,
        [PanCardKycProceedByAgencyOn] [varchar](255) NULL,
        [SapVendorCodeConfirmationReadOn] [varchar](255) NULL,
        [AgencyRemarkBank] [nvarchar](500) NULL,
        [AgencyRemarkPancard] [nvarchar](500) NULL,
        [ResignedDate] [varchar](255) NULL,
        [Age] [varchar](15) NULL,
        [EmpCount] [varchar](10) NULL,
        [D_Status] [varchar](20) NULL,
        [D_Name] [nvarchar](200) NULL,
        [Proprietor1] [varchar](100) NULL,
        [Proprietor2] [varchar](150) NULL,
        [Proprietor3] [varchar](100) NULL
    )
END
GO

-- 2. Create or Alter Stored Procedure
IF OBJECT_ID('USP_UploadMahindraEmployeeSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_UploadMahindraEmployeeSheet_AI
GO

CREATE PROCEDURE USP_UploadMahindraEmployeeSheet_AI
    @Comp_id        NVARCHAR(255),
    @EmployeeTable  [dbo].[UDTT_MahindraEmployeeUpload] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Delete all existing records for the current Comp_id
        DELETE FROM m_dealermaster_mahindra_emp 
        WHERE Comp_id = @Comp_id;

        -- 2. Insert new records from structured table parameter
        INSERT INTO m_dealermaster_mahindra_emp (
            Zone, D_State, DealerCode, DealerType, DealerLocation, DealerTechnicianId, DE_Designation,
            EmpCode, EmpLocation, EmpName, MStarId, EmpUIDNo, EmpDesignaton, EmpBasedAt,
            BranchCategory, BranchType, Gender, FatherName, ContactNo, JoiningDate, DOB,
            Status, EmpKYCStatus, VendorCode, BankAccountNo, BankKycStatus, PanNo, PanKycStatus,
            IDNo, IDProof, BankKycUpdatedOn, PanCardKycUpdatedOn, BankKycProceedByAgencyOn,
            PanCardKycProceedByAgencyOn, SapVendorCodeConfirmationReadOn, AgencyRemarkBank,
            AgencyRemarkPancard, ResignedDate, Age, EmpCount, D_Status, Created_Date, Created_By,
            D_Name, Comp_id, Proprietor1, Proprietor2, Proprietor3
        )
        SELECT
            Zone, D_State, DealerCode, DealerType, DealerLocation, DealerTechnicianId, DE_Designation,
            EmpCode, EmpLocation, EmpName, MStarId, EmpUIDNo, EmpDesignaton, EmpBasedAt,
            BranchCategory, BranchType, Gender, FatherName, ContactNo, JoiningDate, DOB,
            Status, EmpKYCStatus, VendorCode, BankAccountNo, BankKycStatus, PanNo, PanKycStatus,
            IDNo, IDProof, BankKycUpdatedOn, PanCardKycUpdatedOn, BankKycProceedByAgencyOn,
            PanCardKycProceedByAgencyOn, SapVendorCodeConfirmationReadOn, AgencyRemarkBank,
            AgencyRemarkPancard, ResignedDate, Age, EmpCount, ISNULL(D_Status, '1'), GETDATE(), 1,
            D_Name, @Comp_id, Proprietor1, Proprietor2, Proprietor3
        FROM @EmployeeTable;

        COMMIT TRANSACTION;

        SELECT 1 AS success, 'Data successfully imported.' AS message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        SELECT 0 AS success, 'Database error during import: ' + @ErrorMessage AS message;
    END CATCH
END
GO
