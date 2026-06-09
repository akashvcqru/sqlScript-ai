-- =============================================
-- SQL Script: Create UDTT and Stored Procedure for Mahindra Mstar Upload
-- =============================================

-- 1. Create User-Defined Table Type if it does not exist
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_MahindraMstarUpload' AND is_table_type = 1)
BEGIN
    CREATE TYPE [dbo].[UDTT_MahindraMstarUpload] AS TABLE(
        [Dealer_Zone] [varchar](255) NULL,
        [Dealer_Code] [varchar](50) NULL,
        [Dealer_Tehsil Name] [varchar](255) NULL,
        [Dealer Name] [varchar](255) NULL,
        [Dealer Village] [varchar](255) NULL,
        [Mobile_Number] [varchar](50) NULL,
        [Dealer_State Name] [varchar](100) NULL,
        [Tech_Master Id] [varchar](50) NULL,
        [Enrolment_Date] [varchar](100) NULL
    )
END
GO

-- 2. Create or Alter Stored Procedure
IF OBJECT_ID('USP_UploadMahindraMstarSheet_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_UploadMahindraMstarSheet_AI
GO

CREATE PROCEDURE USP_UploadMahindraMstarSheet_AI
    @Comp_id      NVARCHAR(255),
    @MstarTable   [dbo].[UDTT_MahindraMstarUpload] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Delete all existing records for the current Comp_id where DealerType is null
        DELETE FROM m_dealermaster 
        WHERE Comp_id = @Comp_id AND DealerType IS NULL;

        -- 2. Insert new records from structured table parameter
        INSERT INTO m_dealermaster (
            Zone, DealerCode, DealerLocation, D_Name, City, Mobile_Num, D_State, DealerTechnicianId, D_Status, Comp_id, Updated_Date, Created_Date, Created_By
        )
        SELECT
            [Dealer_Zone],
            [Dealer_Code],
            [Dealer_Tehsil Name],
            [Dealer Name],
            [Dealer Village],
            CASE 
                WHEN ISNULL(Mobile_Number, '') = '' THEN NULL
                WHEN Mobile_Number LIKE '91%' AND LEN(Mobile_Number) > 10 THEN Mobile_Number
                ELSE '91' + Mobile_Number
            END,
            [Dealer_State Name],
            [Tech_Master Id],
            'Active',
            @Comp_id,
            CASE 
                WHEN ISNULL([Enrolment_Date], '') = '' THEN NULL
                ELSE TRY_CAST([Enrolment_Date] AS DATETIME)
            END,
            GETDATE(),
            1
        FROM @MstarTable;

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
