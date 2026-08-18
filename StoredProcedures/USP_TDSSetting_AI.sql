USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_TDSSetting_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_TDSSetting_AI]
(
    @Action VARCHAR(20),                -- 'GET', 'SAVE', 'DELETE'
    @Comp_ID VARCHAR(50) = NULL,
    @Tds_Status INT = NULL,              -- 0: Not Applicable, 1: Enable, 2: Disable
    @Tds_Description NVARCHAR(200) = NULL,
    @Id INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Action = 'GET'
    BEGIN
        SELECT 
            ID AS Id,
            Comp_ID AS CompId,
            tds_status AS TdsStatus,
            CASE 
                WHEN tds_status = 0 THEN 'Not Applicable' 
                WHEN tds_status = 1 THEN 'Enable' 
                ELSE 'Disable' 
            END AS TdsStatusName,
            tds_description AS TdsDescription,
            entry_date AS EntryDate,
            updated_date AS UpdatedDate
        FROM set_tds
        WHERE Comp_ID = @Comp_ID;
    END
    ELSE IF @Action = 'SAVE'
    BEGIN
        IF EXISTS (SELECT 1 FROM set_tds WHERE Comp_ID = @Comp_ID)
        BEGIN
            UPDATE set_tds 
            SET tds_status = @Tds_Status, 
                tds_description = @Tds_Description, 
                updated_date = GETDATE() 
            WHERE Comp_ID = @Comp_ID;

            SELECT 1 AS Success, 'Record updated successfully.' AS Message;
        END
        ELSE
        BEGIN
            INSERT INTO set_tds (Comp_ID, tds_status, tds_description, entry_date, updated_date)
            VALUES (@Comp_ID, @Tds_Status, @Tds_Description, GETDATE(), GETDATE());

            SELECT 1 AS Success, 'Record added successfully.' AS Message;
        END
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
        IF EXISTS (SELECT 1 FROM set_tds WHERE Id = @Id)
        BEGIN
            DELETE FROM set_tds WHERE Id = @Id;
            SELECT 1 AS Success, 'Record deleted successfully.' AS Message;
        END
        ELSE
        BEGIN
            SELECT 0 AS Success, 'Record not found.' AS Message;
        END
    END
END
GO
