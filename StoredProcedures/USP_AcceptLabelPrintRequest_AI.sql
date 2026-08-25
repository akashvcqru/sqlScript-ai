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
            SET Flag = 1, PrintType = @PrintType
            WHERE Row_ID = @Row_ID;

            -- 3. Allocation logic
            DECLARE @LastOrder INT = NULL;
            DECLARE @LastSerial INT = NULL;
            DECLARE @StartOrder INT = 0;
            DECLARE @StartSerial INT = 0;
            DECLARE @StartAbsoluteIndex INT = 0;

            IF @Comp_ID = 'Comp-1693'
            BEGIN
                -- Find last assigned series for this product in M_Code_PFL
                SELECT TOP 1 
                    @LastOrder = CAST(Series_Order AS INT), 
                    @LastSerial = CAST(Series_Serial AS INT)
                FROM M_Code_PFL WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID 
                  AND Series_Order IS NOT NULL 
                  AND Series_Serial IS NOT NULL
                ORDER BY Series_Order DESC, Series_Serial DESC;

                IF @LastOrder IS NOT NULL AND @LastSerial IS NOT NULL
                BEGIN
                    IF @LastSerial = 9999
                    BEGIN
                        SET @StartOrder = @LastOrder + 1;
                        SET @StartSerial = 0;
                    END
                    ELSE
                    BEGIN
                        SET @StartOrder = @LastOrder;
                        SET @StartSerial = @LastSerial + 1;
                    END
                END

                SET @StartAbsoluteIndex = @StartOrder * 10000 + @StartSerial;

                -- Select Top @Qty available rows to update
                DECLARE @SelectedRowsPFL TABLE (Row_ID NUMERIC(12, 0) PRIMARY KEY);
                
                INSERT INTO @SelectedRowsPFL (Row_ID)
                SELECT TOP (@Qty) Row_ID 
                FROM M_Code_PFL WITH (NOLOCK)
                WHERE Pro_ID IS NULL 
                  AND Use_Type IS NULL
                  AND Allot_Date IS NULL
                  AND (Print_Status IS NULL OR Print_Status = 0)
                  AND ISNULL([Use_Count],0) = 0 
                  AND DispatchFlag IS NULL 
                  AND ISNULL(ScrapeFlag,0) = 0
                ORDER BY Row_ID ASC;

                IF (SELECT COUNT(1) FROM @SelectedRowsPFL) < @Qty
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 'Not sufficient code to print LABELS. Kindly first generate the CODES and then proceed further.' AS Result;
                    RETURN;
                END

                -- Update top @Qty available codes in M_Code_PFL with sequential series
                ;WITH CTE_Update AS (
                    SELECT 
                        mc.Pro_ID,
                        mc.Print_Status,
                        mc.Print_Date,
                        mc.Allot_Date,
                        mc.LabelRequestId,
                        mc.Series_Order,
                        mc.Series_Serial,
                        ROW_NUMBER() OVER (ORDER BY mc.Row_ID ASC) - 1 AS Seq
                    FROM M_Code_PFL mc
                    INNER JOIN @SelectedRowsPFL sr ON mc.Row_ID = sr.Row_ID
                )
                UPDATE CTE_Update
                SET Pro_ID = @Pro_ID,
                    Print_Status = 1,
                    Print_Date = GETDATE(),
                    Allot_Date = GETDATE(),
                    LabelRequestId = @Tracking_No,
                    Series_Order = (@StartAbsoluteIndex + Seq) / 10000,
                    Series_Serial = (@StartAbsoluteIndex + Seq) % 10000;
            END
            ELSE
            BEGIN
                -- Find last assigned series for this product in M_Code
                SELECT TOP 1 
                    @LastOrder = CAST(Series_Order AS INT), 
                    @LastSerial = CAST(Series_Serial AS INT)
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID = @Pro_ID 
                  AND Series_Order IS NOT NULL 
                  AND Series_Serial IS NOT NULL
                ORDER BY Series_Order DESC, Series_Serial DESC;

                IF @LastOrder IS NOT NULL AND @LastSerial IS NOT NULL
                BEGIN
                    IF @LastSerial = 9999
                    BEGIN
                        SET @StartOrder = @LastOrder + 1;
                        SET @StartSerial = 0;
                    END
                    ELSE
                    BEGIN
                        SET @StartOrder = @LastOrder;
                        SET @StartSerial = @LastSerial + 1;
                    END
                END

                SET @StartAbsoluteIndex = @StartOrder * 10000 + @StartSerial;

                -- Select Top @Qty available rows to update
                DECLARE @SelectedRows TABLE (Row_ID NUMERIC(12, 0) PRIMARY KEY);
                
                INSERT INTO @SelectedRows (Row_ID)
                SELECT TOP (@Qty) Row_ID 
                FROM M_Code WITH (NOLOCK)
                WHERE Pro_ID IS NULL 
                  AND Use_Type IS NULL
                  AND Allot_Date IS NULL
                  AND (Print_Status IS NULL OR Print_Status = 0)
                  AND ISNULL([Use_Count],0) = 0 
                  AND DispatchFlag IS NULL 
                  AND ISNULL(ScrapeFlag,0) = 0
                ORDER BY Row_ID ASC;

                IF (SELECT COUNT(1) FROM @SelectedRows) < @Qty
                BEGIN
                    ROLLBACK TRANSACTION;
                    SELECT 'Not sufficient code to print LABELS. Kindly first generate the CODES and then proceed further.' AS Result;
                    RETURN;
                END

                -- Update top @Qty available codes in M_Code with sequential series
                ;WITH CTE_Update AS (
                    SELECT 
                        mc.Pro_ID,
                        mc.Print_Status,
                        mc.Use_type,
                        mc.Print_Date,
                        mc.Allot_Date,
                        mc.LabelRequestId,
                        mc.Series_Order,
                        mc.Series_Serial,
                        ROW_NUMBER() OVER (ORDER BY mc.Row_ID ASC) - 1 AS Seq
                    FROM M_Code mc
                    INNER JOIN @SelectedRows sr ON mc.Row_ID = sr.Row_ID
                )
                UPDATE CTE_Update
                SET Pro_ID = @Pro_ID,
                    Print_Status = 1,
                    Use_type = 'L',
                    Print_Date = GETDATE(),
                    Allot_Date = GETDATE(),
                    LabelRequestId = @Tracking_No,
                    Series_Order = (@StartAbsoluteIndex + Seq) / 10000,
                    Series_Serial = (@StartAbsoluteIndex + Seq) % 10000;
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
