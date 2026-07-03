SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_UpdateVendorKycStatusDeleteMark_Job_AI]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Create a temp table to hold the records to process
        CREATE TABLE #TempDeleted (
            M_Consumerid INT,
            comp_id VARCHAR(20)
        );

        -- 2. Insert records that have a pending delete request older than 30 days
        INSERT INTO #TempDeleted (M_Consumerid, comp_id)
        SELECT DISTINCT d.M_Consumerid, d.comp_id
        FROM tbl_DeletedUsers d
        INNER JOIN tbl_Vendorvisekycstatus k
            ON k.M_consumerId = d.M_Consumerid
           AND k.Comp_id = d.comp_id
        -- WHERE d.IsActive = 1
        --   AND k.IsActive = 1
        --   AND k.IsDelete = 0
        --   AND d.Entry_date < DATEADD(day, -30, GETDATE());

        -- 3. Update tbl_Vendorvisekycstatus to set IsDelete = 1
        UPDATE k
        SET k.IsDelete = 1
        FROM tbl_Vendorvisekycstatus k
        INNER JOIN #TempDeleted t
            ON k.M_consumerId = t.M_Consumerid
           AND k.Comp_id = t.comp_id;

        -- 4. Deactivate the deletion request in tbl_DeletedUsers as it has been executed
        UPDATE d
        SET d.IsActive = 0,
            d.Updated_date = GETDATE()
        FROM tbl_DeletedUsers d
        INNER JOIN #TempDeleted t
            ON d.M_Consumerid = t.M_Consumerid
           AND d.comp_id = t.comp_id
        WHERE d.IsActive = 1;

        DROP TABLE #TempDeleted;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Re-throw the error for SQL Agent or caller to log
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
