/****** Object:  StoredProcedure [dbo].[USP_ManagePrinterPaperModel_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================
-- Author:      Antigravity
-- Create date: 2026-10-01
-- Description: Stored procedure to Manage (List, Add, Update, Delete) Printer Paper Models
-- =========================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManagePrinterPaperModel_AI]
    @Action NVARCHAR(20),                  -- 'LIST', 'ADD', 'UPDATE', 'DELETE', 'GETBYID'
    @Id INT = NULL,
    @Comp_ID NVARCHAR(50) = NULL,
    @Model_Code NVARCHAR(50) = NULL,
    @Model_Name NVARCHAR(150) = NULL,
    @Paper_Type NVARCHAR(50) = 'A4_Sheet',
    @Label_Width_MM DECIMAL(10,2) = 0,
    @Label_Height_MM DECIMAL(10,2) = 0,
    @Columns_Per_Row INT = 1,
    @Rows_Per_Page INT = 1,
    @Gap_X_MM DECIMAL(10,2) = 0,
    @Gap_Y_MM DECIMAL(10,2) = 0,
    @Margin_Top_MM DECIMAL(10,2) = 0,
    @Margin_Left_MM DECIMAL(10,2) = 0,
    @Description NVARCHAR(250) = NULL,
    @Display_Order INT = 0,
    @IsActive BIT = 1,
    -- List & Filter Parameters
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @Search NVARCHAR(100) = NULL,
    @Offset INT = 0,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- =====================================================================
    -- 1. LIST WITH FILTERS & PAGINATION
    -- =====================================================================
    IF @Action = 'LIST'
    BEGIN
        DECLARE @SearchPattern NVARCHAR(105) = NULL;
        IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
        BEGIN
            SET @SearchPattern = '%' + LTRIM(RTRIM(@Search)) + '%';
        END

        ;WITH FilteredModels AS (
            SELECT 
                Id, 
                Model_Code, 
                Model_Name, 
                Paper_Type, 
                Label_Width_MM, 
                Label_Height_MM, 
                Columns_Per_Row, 
                Rows_Per_Page, 
                Gap_X_MM, 
                Gap_Y_MM, 
                Margin_Top_MM, 
                Margin_Left_MM, 
                Description, 
                Display_Order, 
                Comp_ID, 
                Entry_date,
                IsActive,
                COUNT(*) OVER() AS TotalRecords
            FROM [dbo].[M_Printer_Paper_Master] WITH (NOLOCK)
            WHERE (Comp_ID IS NULL OR Comp_ID = '' OR Comp_ID = @Comp_ID OR Comp_ID = 'ALL')
              AND (@IsActive IS NULL OR IsActive = @IsActive)
              AND (@Paper_Type IS NULL OR LTRIM(RTRIM(@Paper_Type)) = '' OR Paper_Type = @Paper_Type)
              AND (@DateFrom IS NULL OR Entry_date >= @DateFrom)
              AND (@DateTo IS NULL OR Entry_date <= @DateTo)
              AND (
                  @SearchPattern IS NULL 
                  OR Model_Code LIKE @SearchPattern 
                  OR Model_Name LIKE @SearchPattern 
                  OR Description LIKE @SearchPattern 
                  OR Paper_Type LIKE @SearchPattern
              )
        )
        SELECT 
            Id, 
            Model_Code, 
            Model_Name, 
            Paper_Type, 
            Label_Width_MM, 
            Label_Height_MM, 
            Columns_Per_Row, 
            Rows_Per_Page, 
            Gap_X_MM, 
            Gap_Y_MM, 
            Margin_Top_MM, 
            Margin_Left_MM, 
            Description, 
            Display_Order, 
            Comp_ID, 
            Entry_date,
            IsActive,
            TotalRecords
        FROM FilteredModels
        ORDER BY Display_Order ASC, Id ASC
        OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
    END

    -- =====================================================================
    -- 2. ADD / INSERT NEW MODEL
    -- =====================================================================
    ELSE IF @Action IN ('ADD', 'INSERT')
    BEGIN
        -- Auto-generate Model_Code if empty
        IF @Model_Code IS NULL OR LTRIM(RTRIM(@Model_Code)) = ''
        BEGIN
            DECLARE @TypePrefix NVARCHAR(10) = CASE WHEN @Paper_Type = 'Roll_Thermal' THEN 'ROLL' ELSE 'A4' END;
            SET @Model_Code = 'MDL-' + @TypePrefix + '-' + CAST(CAST(@Label_Width_MM AS INT) AS NVARCHAR(10)) + CAST(CAST(@Label_Height_MM AS INT) AS NVARCHAR(10)) + '-' + RIGHT(CONVERT(NVARCHAR(36), NEWID()), 6);
        END

        -- Validate uniqueness of Model_Code
        IF EXISTS (SELECT 1 FROM [dbo].[M_Printer_Paper_Master] WITH (NOLOCK) WHERE Model_Code = @Model_Code)
        BEGIN
            SELECT 0 AS success, 'Model code already exists: ' + @Model_Code AS message, 0 AS Id;
            RETURN;
        END

        -- Default columns & rows if not provided
        DECLARE @Cols INT = CASE WHEN @Columns_Per_Row > 0 THEN @Columns_Per_Row ELSE (CASE WHEN @Paper_Type = 'Roll_Thermal' THEN 1 ELSE 2 END) END;
        DECLARE @Rows INT = CASE WHEN @Rows_Per_Page > 0 THEN @Rows_Per_Page ELSE (CASE WHEN @Paper_Type = 'Roll_Thermal' THEN 1 ELSE 4 END) END;

        INSERT INTO [dbo].[M_Printer_Paper_Master] (
            Model_Code, Model_Name, Paper_Type, Label_Width_MM, Label_Height_MM, 
            Columns_Per_Row, Rows_Per_Page, Gap_X_MM, Gap_Y_MM, Margin_Top_MM, Margin_Left_MM, 
            Description, IsActive, Display_Order, Comp_ID, Entry_date
        )
        VALUES (
            @Model_Code, LTRIM(RTRIM(@Model_Name)), @Paper_Type, @Label_Width_MM, @Label_Height_MM, 
            @Cols, @Rows, @Gap_X_MM, @Gap_Y_MM, @Margin_Top_MM, @Margin_Left_MM, 
            @Description, ISNULL(@IsActive, 1), @Display_Order, @Comp_ID, GETDATE()
        );

        DECLARE @NewId INT = SCOPE_IDENTITY();
        SELECT 1 AS success, 'Printer model added successfully.' AS message, @NewId AS Id;
    END

    -- =====================================================================
    -- 3. UPDATE EXISTING MODEL
    -- =====================================================================
    ELSE IF @Action = 'UPDATE'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [dbo].[M_Printer_Paper_Master] WITH (NOLOCK) WHERE Id = @Id)
        BEGIN
            SELECT 0 AS success, 'Printer model not found.' AS message, @Id AS Id;
            RETURN;
        END

        UPDATE [dbo].[M_Printer_Paper_Master]
        SET Model_Name = ISNULL(LTRIM(RTRIM(@Model_Name)), Model_Name),
            Paper_Type = ISNULL(@Paper_Type, Paper_Type),
            Label_Width_MM = CASE WHEN @Label_Width_MM > 0 THEN @Label_Width_MM ELSE Label_Width_MM END,
            Label_Height_MM = CASE WHEN @Label_Height_MM > 0 THEN @Label_Height_MM ELSE Label_Height_MM END,
            Columns_Per_Row = CASE WHEN @Columns_Per_Row > 0 THEN @Columns_Per_Row ELSE Columns_Per_Row END,
            Rows_Per_Page = CASE WHEN @Rows_Per_Page > 0 THEN @Rows_Per_Page ELSE Rows_Per_Page END,
            Gap_X_MM = ISNULL(@Gap_X_MM, Gap_X_MM),
            Gap_Y_MM = ISNULL(@Gap_Y_MM, Gap_Y_MM),
            Margin_Top_MM = ISNULL(@Margin_Top_MM, Margin_Top_MM),
            Margin_Left_MM = ISNULL(@Margin_Left_MM, Margin_Left_MM),
            Description = ISNULL(@Description, Description),
            Display_Order = ISNULL(@Display_Order, Display_Order),
            IsActive = ISNULL(@IsActive, IsActive)
        WHERE Id = @Id;

        SELECT 1 AS success, 'Printer model updated successfully.' AS message, @Id AS Id;
    END

    -- =====================================================================
    -- 4. DELETE MODEL (SOFT DELETE)
    -- =====================================================================
    ELSE IF @Action = 'DELETE'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [dbo].[M_Printer_Paper_Master] WITH (NOLOCK) WHERE Id = @Id)
        BEGIN
            SELECT 0 AS success, 'Printer model not found.' AS message, @Id AS Id;
            RETURN;
        END

        -- Soft delete by updating IsActive = 0
        UPDATE [dbo].[M_Printer_Paper_Master]
        SET IsActive = 0
        WHERE Id = @Id;

        SELECT 1 AS success, 'Printer model deleted successfully.' AS message, @Id AS Id;
    END

    -- =====================================================================
    -- 5. GET SINGLE MODEL BY ID
    -- =====================================================================
    ELSE IF @Action = 'GETBYID'
    BEGIN
        SELECT 
            Id, Model_Code, Model_Name, Paper_Type, Label_Width_MM, Label_Height_MM, 
            Columns_Per_Row, Rows_Per_Page, Gap_X_MM, Gap_Y_MM, Margin_Top_MM, Margin_Left_MM, 
            Description, Display_Order, Comp_ID, Entry_date, IsActive
        FROM [dbo].[M_Printer_Paper_Master] WITH (NOLOCK)
        WHERE Id = @Id;
    END
END
GO
