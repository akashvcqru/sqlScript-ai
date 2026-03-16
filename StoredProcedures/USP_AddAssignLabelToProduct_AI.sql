-- =============================================
-- Author:      AI
-- Create date: 2026-03-16
-- Description: Add product label assignment and update codes
-- =============================================
CREATE PROCEDURE [dbo].[USP_AddAssignLabelToProduct_AI]
    @Comp_ID NVARCHAR(50),
    @Pro_ID NVARCHAR(50),
    @Batch_No_Text NVARCHAR(50),
    @MRP NUMERIC(10, 2) = NULL,
    @Mfd_Date DATETIME = NULL,
    @Exp_Date DATETIME = NULL,
    @Comments NVARCHAR(100) = NULL,
    @Warranty INT = NULL,
    @SeriesData NVARCHAR(MAX) -- JSON Data
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewRowID NUMERIC(10, 0);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Insert into T_Pro
        INSERT INTO [dbo].[T_Pro] (
            [Pro_ID], 
            [MRP], 
            [Mfd_Date], 
            [Exp_Date], 
            [Batch_No], 
            [Entry_Date], 
            [Comments], 
            [IsWarranty]
        )
        VALUES (
            @Pro_ID, 
            @MRP, 
            @Mfd_Date, 
            @Exp_Date, 
            @Batch_No_Text, 
            GETDATE(), 
            @Comments, 
            CASE WHEN @Warranty > 0 THEN 1 ELSE 0 END
        );

        SET @NewRowID = SCOPE_IDENTITY();

        -- 2. Update M_Code for each series in the JSON
        UPDATE mc
        SET mc.Batch_No = @NewRowID
        FROM M_Code mc
        JOIN OPENJSON(@SeriesData)
        WITH (
            SeriesInitial INT '$.SeriesInitial',
            SeriesFrom INT '$.SeriesFrom',
            SeriesTo INT '$.SeriesTo'
        ) json ON mc.Pro_ID = @Pro_ID 
              AND mc.Series_Order = json.SeriesInitial
              AND mc.Series_Serial >= json.SeriesFrom
              AND mc.Series_Serial <= json.SeriesTo
        WHERE mc.Batch_No IS NULL;

        -- 3. Update Series_Limit in T_Pro (Matching legacy logic)
        UPDATE [T_Pro]
        SET [Series_Limit] = (
            SELECT 
                (SELECT TOP 1 
                    'From  ' + pro_id + '-' + 
                    (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' + 
                    (CASE 
                        WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                        ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                    END)
                 FROM [M_Code] 
                 WHERE print_status = 1 AND pro_id = @Pro_ID AND Batch_no = @NewRowID
                 ORDER BY [Series_Order], [Series_Serial]) 
                + '   ' +
                (SELECT TOP 1 
                    'To  ' + pro_id + '-' + 
                    (CASE WHEN LEN(CONVERT(NVARCHAR, [Series_Order])) = 1 THEN '0' + CONVERT(NVARCHAR, [Series_Order]) ELSE CONVERT(NVARCHAR, [Series_Order]) END) + '-' + 
                    (CASE 
                        WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 1 THEN '000' + CONVERT(NVARCHAR, [Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 2 THEN '00' + CONVERT(NVARCHAR, [Series_Serial]) 
                        WHEN LEN(CONVERT(NVARCHAR, [Series_Serial])) = 3 THEN '0' + CONVERT(NVARCHAR, [Series_Serial]) 
                        ELSE CONVERT(NVARCHAR, [Series_Serial]) 
                    END)
                 FROM [M_Code] 
                 WHERE print_status = 1 AND pro_id = @Pro_ID AND Batch_no = @NewRowID
                 ORDER BY [Series_Order] DESC, [Series_Serial] DESC)
        )
        WHERE Row_ID = @NewRowID;

        COMMIT TRANSACTION;

        SELECT 1 AS success, 'Label assignment successful.' AS message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
