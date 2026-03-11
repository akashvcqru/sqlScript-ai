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
    @BatchSize      BIGINT,
    @DispLoc        NVARCHAR(200),
    @DML            NCHAR(1)   -- 'I' = Insert, 'U' = Update
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

        -- Generate Pro_ID from Code_Gen table
        DECLARE @Prefix     NVARCHAR(10),
                @PrStart    INT,
                @NewProId   NVARCHAR(50);

        SELECT @Prefix  = PrPrefix,
               @PrStart = PrStart
        FROM   Code_Gen
        WHERE  Prfor = 'Product'
          AND  PrFlag = 1;

        SET @NewProId = ISNULL(@Prefix, 'PR') + CAST(ISNULL(@PrStart, 1) AS NVARCHAR(20));

        INSERT INTO Pro_Reg
            (Comp_ID, Pro_ID, Pro_Entry_Date, Pro_Name, Update_Flag,
             Pro_Desc, Label_Code, Doc_Flag, Sound_Flag, BatchSize, Dispatch_Location)
        VALUES
            (@Comp_ID, @NewProId, @Pro_Entry_Date, @Pro_Name, 0,
             @Pro_Desc, @Label_Code, 0, 0, @BatchSize, @DispLoc);

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
               Dispatch_Location = @DispLoc
        WHERE  Pro_ID  = @Pro_ID
          AND  Comp_ID = @Comp_ID;

        SELECT 1 AS success, 'Product updated successfully.' AS message, @Pro_ID AS Pro_ID;
    END
    ELSE
    BEGIN
        SELECT 0 AS success, 'Invalid DML operation.' AS message, '' AS Pro_ID;
    END
END
GO
