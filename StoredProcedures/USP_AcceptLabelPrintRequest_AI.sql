CREATE OR ALTER PROCEDURE [dbo].[USP_AcceptLabelPrintRequest_AI]
    @Row_ID INT,
    @Comp_ID NVARCHAR(50),
    @Qty INT,
    @PrintType NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Pro_ID NVARCHAR(50);
    SELECT @Pro_ID = Pro_ID FROM M_Label_Request WHERE Row_ID = @Row_ID;

    IF @Pro_ID IS NULL
    BEGIN
        SELECT 'Label Request not found or missing Product ID' AS Result;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Identify codes to update
        DECLARE @SelectedCodes TABLE (Row_ID BIGINT);

        IF @Comp_ID = 'Comp-1693'
        BEGIN
            INSERT INTO @SelectedCodes (Row_ID)
            SELECT TOP (@Qty) Row_ID 
            FROM M_Code_PFL 
            WHERE (Print_Status IS NULL OR Print_Status = 1) AND ISNULL([Use_Count],0) = 0 AND DispatchFlag IS NULL AND ISNULL(ScrapeFlag,0) = 0
            ORDER BY Row_ID ASC; -- Order by Row_ID to ensure sequential/first-gen codes

            UPDATE M_Code_PFL
            SET Pro_ID = @Pro_ID, Allot_Date = GETDATE(), Print_Status = 0, LabelRequestId = CAST(@Row_ID AS NVARCHAR(15))
            WHERE Row_ID IN (SELECT Row_ID FROM @SelectedCodes);
        END
        ELSE
        BEGIN
            INSERT INTO @SelectedCodes (Row_ID)
            SELECT TOP (@Qty) Row_ID 
            FROM M_Code 
            WHERE (Print_Status IS NULL OR Print_Status = 1) AND ISNULL([Use_Count],0) = 0 AND DispatchFlag IS NULL AND ISNULL(ScrapeFlag,0) = 0
            ORDER BY Row_ID ASC;

            UPDATE M_Code
            SET Pro_ID = @Pro_ID, Allot_Date = GETDATE(), Print_Status = 0, LabelRequestId = CAST(@Row_ID AS NVARCHAR(15))
            WHERE Row_ID IN (SELECT Row_ID FROM @SelectedCodes);
        END

        -- 2. Update Label Request Status
        IF EXISTS (SELECT 1 FROM @SelectedCodes)
        BEGIN
            UPDATE M_Label_Request
            SET Flag = 1 -- Accepted/Processed
            WHERE Row_ID = @Row_ID;

            COMMIT TRANSACTION;
            SELECT 'Success' AS Result;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'No codes available' AS Result;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS Result;
    END CATCH
END
GO
