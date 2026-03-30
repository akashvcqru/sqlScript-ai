-- =============================================
-- SQL Script: Create UDTT and Bulk Upload Procedure
-- =============================================

-- 1. Create User-Defined Table Type
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'UDTT_ProductUpload' AND is_table_type = 1)
BEGIN
    CREATE TYPE [dbo].[UDTT_ProductUpload] AS TABLE(
        [Pro_Name] NVARCHAR(200),
        [Pro_Desc] NVARCHAR(MAX),
        [Label_Code] NVARCHAR(50),
        [BatchSize] BIGINT,
        [DispLoc] NVARCHAR(200)
    )
END
GO

-- 2. Create Stored Procedure
IF OBJECT_ID('USP_BulkUploadProducts_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_BulkUploadProducts_AI
GO

CREATE PROCEDURE USP_BulkUploadProducts_AI
    @Comp_ID        NVARCHAR(50),
    @ProductTable   [dbo].[UDTT_ProductUpload] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EntryDate NVARCHAR(50) = FORMAT(GETDATE(), 'MM/dd/yyyy hh:mm:ss tt');
    DECLARE @SuccessCount INT = 0;
    DECLARE @ErrorCount INT = 0;

    -- Use a cursor to process each row and generate unique IDs
    DECLARE @ProName NVARCHAR(200), @ProDesc NVARCHAR(MAX), @LabelCode NVARCHAR(50), @BatchSize BIGINT, @DispLoc NVARCHAR(200);
    
    DECLARE prod_cursor CURSOR FOR 
    SELECT [Pro_Name], [Pro_Desc], [Label_Code], [BatchSize], [DispLoc] FROM @ProductTable;

    OPEN prod_cursor;
    FETCH NEXT FROM prod_cursor INTO @ProName, @ProDesc, @LabelCode, @BatchSize, @DispLoc;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Generate Pro_ID from Code_Gen table (adapted from USP_InsertUpdateProduct_AI)
        DECLARE @Prefix     NVARCHAR(10),
                @PrStart    INT,
                @NewProId   NVARCHAR(50),
                @Char1      INT,
                @Char2      INT;

        -- Check if product name already exists for this company
        IF NOT EXISTS (SELECT 1 FROM Pro_Reg WHERE Comp_ID = @Comp_ID AND Pro_Name = @ProName)
        BEGIN
            -- Atomic update/read for Code_Gen
            SELECT @Prefix  = PrPrefix,
                   @PrStart = PrStart
            FROM   Code_Gen WITH (UPDLOCK, HOLDLOCK)
            WHERE  Prfor = 'Product'
              AND  PrFlag = 1;

            -- Rollover logic if PrStart reaches 200
            IF @PrStart >= 200
            BEGIN
                SET @Char1 = ASCII(SUBSTRING(@Prefix, 1, 1));
                SET @Char2 = ASCII(SUBSTRING(@Prefix, 2, 1));

                IF @Char2 != 90 -- Not 'Z'
                    SET @Char2 = @Char2 + 1;
                ELSE
                BEGIN
                    SET @Char1 = @Char1 + 1;
                    SET @Char2 = 65; -- Reset to 'A'
                END

                IF @Char1 <= 90
                BEGIN
                    SET @Prefix = CHAR(@Char1) + CHAR(@Char2);
                    UPDATE Code_Gen SET PrFlag = 0 WHERE Prfor = 'Product' AND PrFlag = 1;
                    INSERT INTO Code_Gen (Prfor, PrPrefix, PrStart, PrFlag) VALUES ('Product', @Prefix, 100, 1);
                    SET @PrStart = 100;
                END
            END

            -- Format Pro_ID: Prefix + last 2 digits (PrStart - 100)
            SET @NewProId = @Prefix + RIGHT('0' + CAST((@PrStart - 100) AS NVARCHAR(2)), 2);

            INSERT INTO Pro_Reg
                (Comp_ID, Pro_ID, Pro_Entry_Date, Pro_Name, Update_Flag,
                 Pro_Desc, Label_Code, Doc_Flag, Sound_Flag, BatchSize, Dispatch_Location,
                 Doc_Remark, Sound_Remark)
            VALUES
                (@Comp_ID, @NewProId, @EntryDate, @ProName, 0,
                 @ProDesc, @LabelCode, 1, 1, @BatchSize, @DispLoc,
                 'approve', 'approve');

            -- Increment counter
            UPDATE Code_Gen SET PrStart = PrStart + 1 WHERE Prfor = 'Product' AND PrFlag = 1;
            
            SET @SuccessCount = @SuccessCount + 1;
        END
        ELSE
        BEGIN
            SET @ErrorCount = @ErrorCount + 1;
        END

        FETCH NEXT FROM prod_cursor INTO @ProName, @ProDesc, @LabelCode, @BatchSize, @DispLoc;
    END

    CLOSE prod_cursor;
    DEALLOCATE prod_cursor;

    SELECT 1 AS success, 
           CAST(@SuccessCount AS NVARCHAR(10)) + ' products uploaded successfully. ' + 
           CAST(@ErrorCount AS NVARCHAR(10)) + ' skipped (duplicates).' AS message;
END
GO
