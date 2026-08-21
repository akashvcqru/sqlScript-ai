/****** Object:  StoredProcedure [dbo].[PROC_UpdateM_CodeUse_Count_AI]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[PROC_UpdateM_CodeUse_Count_AI]
		 @Received_Code1 nvarchar(50)
		,@Received_Code2 nvarchar(50)
		,@Is_Success int
AS
BEGIN
	UPDATE [M_Code] SET
      [Use_Count] = ISNULL([Use_Count], 0) + CASE WHEN @Is_Success = 1 THEN 1 ELSE 0 END
 WHERE  [Code1] = @Received_Code1
      AND [Code2] = @Received_Code2
END
GO
