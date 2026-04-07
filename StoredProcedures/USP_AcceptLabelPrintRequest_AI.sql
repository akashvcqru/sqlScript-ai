CREATE OR ALTER PROCEDURE [dbo].[USP_AcceptLabelPrintRequest_AI]
    @Row_ID INT,
    @Comp_ID NVARCHAR(50),
    @Comp_Name NVARCHAR(MAX) = NULL,
    @Qty INT,
    @PrintType NVARCHAR(50) = NULL,
    @Contact_Person NVARCHAR(MAX) = NULL,
    @Pro_ID NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Tracking_No NVARCHAR(50);
    DECLARE @Result NVARCHAR(MAX) = 'Failure';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Get Tracking No and Pro_ID (if not provided) from M_Label_Request
        SELECT @Tracking_No = Tracking_No, 
               @Pro_ID = ISNULL(@Pro_ID, Pro_ID)
        FROM M_Label_Request 
        WHERE Row_ID = @Row_ID;

        IF @Tracking_No IS NOT NULL
        BEGIN
            -- 2. Update M_Label_Request entry setting Flag to 1 (Accepted/Processed)
            UPDATE M_Label_Request 
            SET Flag = 1
            WHERE Row_ID = @Row_ID;

            -- 3. Allocation logic
            IF @Comp_ID = 'Comp-1693'
            BEGIN
                -- Update top @Qty available codes in M_Code_PFL
                UPDATE M_Code_PFL
                SET Pro_ID = @Pro_ID,
                    Print_Status = 1,
                    Print_Date = GETDATE(),
                    Allot_Date = GETDATE(),
                    LabelRequestId = @Tracking_No
                WHERE Row_ID IN (
                    SELECT TOP (@Qty) Row_ID 
                    FROM M_Code_PFL 
                    WHERE Pro_ID IS NULL 
                      AND (Print_Status IS NULL OR Print_Status = 0)
                      AND ISNULL([Use_Count],0) = 0 
                      AND DispatchFlag IS NULL 
                      AND ISNULL(ScrapeFlag,0) = 0
                    ORDER BY Row_ID ASC
                );
            END
            ELSE
            BEGIN
                -- Update top @Qty available codes in M_Code
                UPDATE M_Code
                SET Pro_ID = @Pro_ID,
                    Print_Status = 1,
                    Print_Date = GETDATE(),
                    Allot_Date = GETDATE(),
                    LabelRequestId = @Tracking_No
                WHERE Row_ID IN (
                    SELECT TOP (@Qty) Row_ID 
                    FROM M_Code 
                    WHERE Pro_ID IS NULL 
                      AND (Print_Status IS NULL OR Print_Status = 0)
                      AND ISNULL([Use_Count],0) = 0 
                      AND DispatchFlag IS NULL 
                      AND ISNULL(ScrapeFlag,0) = 0
                    ORDER BY Row_ID ASC
                );
            END

            SET @Result = 'Success';
        END
        ELSE
        BEGIN
            SET @Result = 'Label Request not found for Row_ID: ' + CAST(@Row_ID AS NVARCHAR(20));
        END

        COMMIT TRANSACTION;
        SELECT @Result AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Result = 'Error: ' + ERROR_MESSAGE();
        SELECT @Result AS Result;
    END CATCH
END
GO
