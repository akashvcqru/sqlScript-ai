/****** Object:  StoredProcedure [dbo].[PROC_AddBrandWisePoints_AI]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PROC_AddBrandWisePoints_AI]
    @Received_Code1 NVARCHAR(50),
    @Received_Code2 NVARCHAR(50),
    @MobileNo      NVARCHAR(20)
AS
BEGIN
    DECLARE @Comp_ID    VARCHAR(20),
            @Pro_ID     VARCHAR(20),
            @Brand_Code VARCHAR(50),
            @Points     INT;

    SELECT @Comp_ID = pr.Comp_ID,
           @Pro_ID  = pr.Pro_ID
    FROM dbo.M_Code mc
    INNER JOIN dbo.Pro_Reg pr ON mc.Pro_ID = pr.Pro_ID
    WHERE mc.Code1 = @Received_Code1
      AND mc.Code2 = @Received_Code2;

    SELECT @Brand_Code = Brand_Code,
           @Points     = Points
    FROM dbo.M_BrandPoints
    WHERE Comp_ID = @Comp_ID
      AND Pro_ID  = @Pro_ID;

    IF @Brand_Code IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.M_ProductBrandPoints WHERE Brand_Code = @Brand_Code AND MobileNo = @MobileNo)
        BEGIN
            INSERT INTO dbo.M_ProductBrandPoints (Comp_ID, Pro_ID, Brand_Code, Received_Code1, Received_Code2, Points, Service_Name, MobileNo)
            VALUES (@Comp_ID, @Pro_ID, @Brand_Code, @Received_Code1, @Received_Code2, @Points, 'PROC_UpdateM_CodeUse_Count', @MobileNo);
        END
        ELSE
        BEGIN
            UPDATE dbo.M_ProductBrandPoints
            SET Points = ISNULL(Points, 0) + ISNULL(@Points, 0)
            WHERE Brand_Code = @Brand_Code
              AND MobileNo   = @MobileNo;
        END
    END
END
GO
