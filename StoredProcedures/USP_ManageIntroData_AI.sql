CREATE PROCEDURE [dbo].[USP_ManageIntroData_AI]
    @Action NVARCHAR(20), -- 'GET', 'SAVE', 'UPDATE', 'DELETE'
    @Comp_ID NVARCHAR(50),
    @ID NVARCHAR(50) = NULL,
    @Header NVARCHAR(255) = NULL,
    @Contents NVARCHAR(MAX) = NULL,
    @ImagePath NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentIntroData NVARCHAR(MAX);
    SELECT @CurrentIntroData = [Introdata] FROM [dbo].[BrandSettings] WHERE [Comp_ID] = @Comp_ID;

    IF @Action = 'GET'
    BEGIN
        SELECT @CurrentIntroData AS Data;
        RETURN;
    END

    IF @Action = 'SAVE'
    BEGIN
        DECLARE @NewItem NVARCHAR(MAX);
        SET @NewItem = (
            SELECT 
                ISNULL(@ID, NEWID()) AS [ID],
                NULL AS [CompanyId],
                @Header AS [Header],
                @Contents AS [Contains],
                @ImagePath AS [ImagePath]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        IF @CurrentIntroData IS NULL OR @CurrentIntroData = ''
        BEGIN
            SET @CurrentIntroData = '[' + @NewItem + ']';
        END
        ELSE
        BEGIN
            -- Using JSON_MODIFY to append is tricky for arrays in older SQL versions, 
            -- but for 2016+ we can use JSON_QUERY to append.
            SET @CurrentIntroData = JSON_MODIFY(@CurrentIntroData, 'append $', JSON_QUERY(@NewItem));
        END

        IF EXISTS (SELECT 1 FROM [dbo].[BrandSettings] WHERE [Comp_ID] = @Comp_ID)
        BEGIN
            UPDATE [dbo].[BrandSettings] SET [Introdata] = @CurrentIntroData, [Updated_Date] = GETDATE(), [Updated_by] = 'API' WHERE [Comp_ID] = @Comp_ID;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[BrandSettings] ([Comp_ID], [Introdata], [Created_Date], [Created_by], [IsActive], [IsDelete])
            VALUES (@Comp_ID, @CurrentIntroData, GETDATE(), 'API', 1, 0);
        END
        
        SELECT 1 AS Success, 'Introduction item added successfully.' AS Message;
    END
    ELSE IF @Action = 'UPDATE'
    BEGIN
        IF @CurrentIntroData IS NOT NULL AND @ID IS NOT NULL
        BEGIN
            -- We need to find the index and update. 
            -- In SQL Server, it's easier to reconstruct the array or use a temp table.
            -- For simplicity and robustness across versions, we'll parse to a table, update, then back to JSON.
            
            DECLARE @TempIntroTable TABLE (
                [ID] NVARCHAR(50),
                [CompanyId] NVARCHAR(50),
                [Header] NVARCHAR(255),
                [Contains] NVARCHAR(MAX),
                [ImagePath] NVARCHAR(MAX)
            );

            INSERT INTO @TempIntroTable
            SELECT [ID], [CompanyId], [Header], [Contains], [ImagePath]
            FROM OPENJSON(@CurrentIntroData)
            WITH (
                [ID] NVARCHAR(50),
                [CompanyId] NVARCHAR(50),
                [Header] NVARCHAR(255),
                [Contains] NVARCHAR(MAX),
                [ImagePath] NVARCHAR(MAX)
            );

            UPDATE @TempIntroTable
            SET [Header] = ISNULL(@Header, [Header]),
                [Contains] = ISNULL(@Contents, [Contains]),
                [ImagePath] = ISNULL(@ImagePath, [ImagePath])
            WHERE [ID] = @ID;

            SET @CurrentIntroData = (SELECT * FROM @TempIntroTable FOR JSON PATH);

            UPDATE [dbo].[BrandSettings] SET [Introdata] = @CurrentIntroData, [Updated_Date] = GETDATE(), [Updated_by] = 'API' WHERE [Comp_ID] = @Comp_ID;
            
            SELECT 1 AS Success, 'Introduction item updated successfully.' AS Message;
        END
        ELSE
        BEGIN
            SELECT 0 AS Success, 'Item not found or ID missing.' AS Message;
        END
    END
    ELSE IF @Action = 'DELETE'
    BEGIN
        IF @CurrentIntroData IS NOT NULL AND @ID IS NOT NULL
        BEGIN
            DECLARE @TempIntroTableDel TABLE (
                [ID] NVARCHAR(50),
                [CompanyId] NVARCHAR(50),
                [Header] NVARCHAR(255),
                [Contains] NVARCHAR(MAX),
                [ImagePath] NVARCHAR(MAX)
            );

            INSERT INTO @TempIntroTableDel
            SELECT [ID], [CompanyId], [Header], [Contains], [ImagePath]
            FROM OPENJSON(@CurrentIntroData)
            WITH (
                [ID] NVARCHAR(50),
                [CompanyId] NVARCHAR(50),
                [Header] NVARCHAR(255),
                [Contains] NVARCHAR(MAX),
                [ImagePath] NVARCHAR(MAX)
            );

            DELETE FROM @TempIntroTableDel WHERE [ID] = @ID;

            SET @CurrentIntroData = (SELECT * FROM @TempIntroTableDel FOR JSON PATH);

            UPDATE [dbo].[BrandSettings] SET [Introdata] = @CurrentIntroData, [Updated_Date] = GETDATE(), [Updated_by] = 'API' WHERE [Comp_ID] = @Comp_ID;
            
            SELECT 1 AS Success, 'Introduction item deleted successfully.' AS Message;
        END
        ELSE
        BEGIN
            SELECT 0 AS Success, 'Item not found or ID missing.' AS Message;
        END
    END
END
GO
