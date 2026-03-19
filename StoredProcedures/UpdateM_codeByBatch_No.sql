SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER Procedure [dbo].[UpdateM_codeByBatch_No]
(
    @Row_ID numeric(20),
    @pro_id nvarchar(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE [T_Pro]
    SET [Series_Limit] = (
        SELECT 
            (SELECT TOP 1 'From  ' + pro_id + '-' + 
                (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' +
                (CASE 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                    ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                END)
             FROM [M_Code] 
             WHERE print_status = 1 AND pro_id = @pro_id AND Batch_no = CAST(@Row_ID AS VARCHAR(50))
             ORDER BY [Series_Order], [Series_Serial]) 
            + '   ' +
            (SELECT TOP 1 'To  ' + pro_id + '-' + 
                (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' +
                (CASE 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                    WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                    ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                END)
             FROM [M_Code] 
             WHERE print_status = 1 AND pro_id = @pro_id AND Batch_no = CAST(@Row_ID AS VARCHAR(50))
             ORDER BY [Series_Order] DESC, [Series_Serial] DESC)
    )
    WHERE Row_ID = @Row_ID;
END
GO
