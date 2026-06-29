USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-01
-- Description: Manage input fields for landing page (Add/Edit)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageInputFieldsWeb_AI]
    @FieldId INT = 0,
    @FieldName VARCHAR(100),
    @Label VARCHAR(150),
    @FieldType VARCHAR(50),
    @DefaultValidation VARCHAR(1000) = NULL,
    @Placeholder VARCHAR(150) = NULL,
    @MaxLength INT = NULL,
    @IsActive BIT = 1,
    @createdby VARCHAR(50) = NULL,
    @updatedby VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FieldId = 0
    BEGIN
        -- Insert Action
        INSERT INTO Master_InputFieldsWeb (
            FieldName, Label, FieldType, DefaultValidation, Placeholder, MaxLength, IsActive, created_date, createdby
        )
        VALUES (
            @FieldName, @Label, @FieldType, @DefaultValidation, @Placeholder, @MaxLength, @IsActive, GETDATE(), @createdby
        );
        
        SELECT SCOPE_IDENTITY() AS NewFieldId, 'Added successfully' AS [Message], 1 AS [Status];
    END
    ELSE
    BEGIN
        -- Update Action
        IF EXISTS (SELECT 1 FROM Master_InputFieldsWeb WHERE FieldId = @FieldId)
        BEGIN
            UPDATE Master_InputFieldsWeb
            SET 
                FieldName = @FieldName,
                Label = @Label,
                FieldType = @FieldType,
                DefaultValidation = @DefaultValidation,
                Placeholder = @Placeholder,
                MaxLength = @MaxLength,
                IsActive = @IsActive,
                updatedby = @updatedby,
                updated_date = GETDATE()
            WHERE FieldId = @FieldId;

            SELECT @FieldId AS NewFieldId, 'Updated successfully' AS [Message], 1 AS [Status];
        END
        ELSE
        BEGIN
            SELECT @FieldId AS NewFieldId, 'Field not found' AS [Message], 0 AS [Status];
        END
    END
END
GO
