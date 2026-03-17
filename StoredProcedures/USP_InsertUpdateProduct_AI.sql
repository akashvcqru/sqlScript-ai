-- =============================================
-- Procedure: USP_InsertUpdateProduct_AI
-- Description: Insert or Update a product in Pro_Reg table
-- Called from: ProductController.cs -> POST /api/vendor/products/addproduct
-- =============================================
IF OBJECT_ID('USP_InsertUpdateProduct_AI', 'P') IS NOT NULL
    DROP PROCEDURE USP_InsertUpdateProduct_AI
GO

CREATE PROCEDURE USP_InsertUpdateProduct_AI
    @Comp_ID        NVARCHAR(50),
    @Pro_ID         NVARCHAR(50),
    @Pro_Entry_Date NVARCHAR(50),
    @Pro_Name       NVARCHAR(200),
    @Pro_Desc       NVARCHAR(MAX),
    @Label_Code     NVARCHAR(50),
    @BatchSize      BIGINT = 0,
    @DispLoc        NVARCHAR(200) = NULL,
    @DML            NCHAR(1),  -- 'I' = Insert, 'U' = Update, 'F' = Update File Flags Only
    @Pro_Doc        NVARCHAR(250) = NULL,
    @Doc_Flag       INT = 0,
    @Sound_Flag     INT = 0,
    @Doc_Remark     NVARCHAR(250) = NULL,
    @Sound_Remark   NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Duplicate name check on Insert
    IF @DML = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1 FROM Pro_Reg
            WHERE Comp_ID = @Comp_ID
              AND Pro_Name = @Pro_Name
        )
        BEGIN
            SELECT 0 AS success, 'Product name already exists.' AS message, '' AS Pro_ID;
            RETURN;
        END

        -- Generate Pro_ID from Code_Gen table with locking to prevent race conditions
        DECLARE @Prefix     NVARCHAR(10),
                @PrStart    INT,
                @NewProId   NVARCHAR(50),
                @Char1      INT,
                @Char2      INT;

        -- Use UPDLOCK and HOLDLOCK to ensure only one process can read/update the counter at a time
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
            BEGIN
                SET @Char2 = @Char2 + 1;
            END
            ELSE
            BEGIN
                SET @Char1 = @Char1 + 1;
                SET @Char2 = 65; -- Reset to 'A'
            END

            -- Check for ZZ limit
            IF @Char1 <= 90
            BEGIN
                SET @Prefix = CHAR(@Char1) + CHAR(@Char2);
                
                -- Mark old record as inactive and create new one
                UPDATE Code_Gen SET PrFlag = 0 WHERE Prfor = 'Product' AND PrFlag = 1;
                INSERT INTO Code_Gen (Prfor, PrPrefix, PrStart, PrFlag) 
                VALUES ('Product', @Prefix, 100, 1);
                
                SET @PrStart = 100;
            END
        END

        -- Format Pro_ID: Prefix + last 2 digits (PrStart - 100)
        SET @NewProId = @Prefix + RIGHT('0' + CAST((@PrStart - 100) AS NVARCHAR(2)), 2);

        -- Final check for Pro_ID uniqueness in Pro_Reg
        IF EXISTS (SELECT 1 FROM Pro_Reg WHERE Pro_ID = @NewProId)
        BEGIN
            SELECT 0 AS success, 'Duplicate Product ID generated: ' + @NewProId AS message, '' AS Pro_ID;
            RETURN;
        END

        INSERT INTO Pro_Reg
            (Comp_ID, Pro_ID, Pro_Entry_Date, Pro_Name, Update_Flag,
             Pro_Desc, Label_Code, Doc_Flag, Sound_Flag, BatchSize, Dispatch_Location, Pro_Doc,
             Doc_Remark, Sound_Remark)
        VALUES
            (@Comp_ID, @NewProId, @Pro_Entry_Date, @Pro_Name, 0,
             @Pro_Desc, @Label_Code, @Doc_Flag, @Sound_Flag, @BatchSize, @DispLoc, @Pro_Doc,
             @Doc_Remark, @Sound_Remark);

        -- Increment counter
        UPDATE Code_Gen
        SET    PrStart = PrStart + 1
        WHERE  Prfor = 'Product'
          AND  PrFlag = 1;

        SELECT 1 AS success, 'Product registered successfully.' AS message, @NewProId AS Pro_ID;
    END
    ELSE IF @DML = 'U'
    BEGIN
        UPDATE Pro_Reg
        SET    Pro_Name          = @Pro_Name,
               Pro_Desc          = @Pro_Desc,
               Label_Code        = @Label_Code,
               BatchSize         = @BatchSize,
               Dispatch_Location = @DispLoc,
               Pro_Doc           = ISNULL(@Pro_Doc, Pro_Doc),
               Doc_Flag          = CASE WHEN @Pro_Doc IS NOT NULL THEN @Doc_Flag ELSE Doc_Flag END,
               Sound_Flag        = CASE WHEN @Sound_Flag > 0 THEN @Sound_Flag ELSE Sound_Flag END,
               Doc_Remark        = ISNULL(@Doc_Remark, Doc_Remark),
               Sound_Remark      = ISNULL(@Sound_Remark, Sound_Remark)
        WHERE  Pro_ID  = @Pro_ID
          AND  Comp_ID = @Comp_ID;

        SELECT 1 AS success, 'Product updated successfully.' AS message, @Pro_ID AS Pro_ID;
    END
    ELSE IF @DML = 'F'
    BEGIN
        -- Used to update just the file flags and names after the initial insert generates the Pro_ID
        UPDATE Pro_Reg
        SET    Pro_Doc           = ISNULL(@Pro_Doc, Pro_Doc),
               Doc_Flag          = CASE WHEN @Pro_Doc IS NOT NULL THEN @Doc_Flag ELSE Doc_Flag END,
               Sound_Flag        = CASE WHEN @Sound_Flag > 0 THEN @Sound_Flag ELSE Sound_Flag END
        WHERE  Pro_ID  = @Pro_ID
          AND  Comp_ID = @Comp_ID;

        SELECT 1 AS success, 'Product files updated successfully.' AS message, @Pro_ID AS Pro_ID;
    END
    ELSE
    BEGIN
        SELECT 0 AS success, 'Invalid DML operation.' AS message, '' AS Pro_ID;
    END
END
GO
