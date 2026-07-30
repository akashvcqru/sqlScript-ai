-- Create the User-Defined Table Type if it does not exist
IF NOT EXISTS (SELECT 1 FROM sys.types WHERE is_user_defined = 1 AND name = 'UDTT_MahindraSBUUpload')
BEGIN
    CREATE TYPE [dbo].[UDTT_MahindraSBUUpload] AS TABLE(
        [Zone] [VARCHAR](100) NULL,
        [D_State] [VARCHAR](100) NULL,
        [DealerCode] [VARCHAR](100) NULL,
        [DealerLocation] [VARCHAR](255) NULL,
        [DealerTechnicianId] [VARCHAR](100) NULL,
        [D_Name] [NVARCHAR](255) NULL,
        [Mobile_Num] [NVARCHAR](50) NULL
    )
END
GO

-- Create or Alter the Stored Procedure with name USP_UploadSBUUserExcel_AI
CREATE OR ALTER PROCEDURE [dbo].[USP_UploadSBUUserExcel_AI]
    @Comp_id    NVARCHAR(255),
    @UpdatedBy  NVARCHAR(255),
    @SBUTable   [dbo].[UDTT_MahindraSBUUpload] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Mark all existing SBU dealers for Comp_id as InActive
        UPDATE m_dealermaster 
        SET D_Status = 'InActive', 
            Updated_By = @UpdatedBy, 
            Updated_Date = GETDATE() 
        WHERE DealerType = 'SBU' AND Comp_id = @Comp_id;

        -- 2. Update existing SBU records to Active and update their fields
        UPDATE dm
        SET 
            dm.Zone = src.Zone,
            dm.D_State = src.D_State,
            dm.DealerLocation = src.DealerLocation,
            dm.D_Name = src.D_Name,
            dm.Mobile_Num = src.Mobile_Num,
            dm.D_Status = 'Active',
            dm.Updated_By = @UpdatedBy,
            dm.Updated_Date = GETDATE()
        FROM m_dealermaster dm
        INNER JOIN @SBUTable src ON 
            dm.DealerCode = src.DealerCode AND 
            dm.DealerTechnicianId = src.DealerTechnicianId
        WHERE dm.DealerType = 'SBU' AND dm.Comp_id = @Comp_id;

        -- 3. Insert new SBU records
        INSERT INTO m_dealermaster (
            Zone, D_State, DealerCode, DealerType, DealerLocation, DealerTechnicianId, D_Status, D_Name, Comp_id, Mobile_Num, Created_Date, Created_By, Updated_Date, Updated_By
        )
        SELECT 
            src.Zone, src.D_State, src.DealerCode, 'SBU', src.DealerLocation, src.DealerTechnicianId, 'Active', src.D_Name, @Comp_id, src.Mobile_Num, GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy
        FROM @SBUTable src
        WHERE NOT EXISTS (
            SELECT 1 
            FROM m_dealermaster dm 
            WHERE dm.DealerType = 'SBU' 
              AND dm.DealerCode = src.DealerCode 
              AND dm.DealerTechnicianId = src.DealerTechnicianId 
              AND dm.Comp_id = @Comp_id
        );

        COMMIT TRANSACTION;

        SELECT 1 AS success, 'Mahindra SBU sheet data successfully synchronized.' AS message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        SELECT 0 AS success, 'Database error during SBU import: ' + @ErrorMessage AS message;
    END CATCH
END
GO
