USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_DeleteAssignCodeseriesdealerReport_AI]    Script Date: 10-09-2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 10-09-2026
-- Description: Safely delete assigned code(s) or an entire assigned series batch from tbl_assigncodelocation
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_DeleteAssignCodeseriesdealerReport_AI]
(
    @Comp_Id VARCHAR(50),
    @Mode VARCHAR(20) = 'CODES', -- 'CODES' or 'BATCH'
    @Id INT = NULL,
    @Ids NVARCHAR(MAX) = NULL,
    @Code1 VARCHAR(20) = NULL,
    @Code2 VARCHAR(20) = NULL,
    @FromSeries NVARCHAR(50) = NULL,
    @ToSeries NVARCHAR(50) = NULL,
    @DealerName NVARCHAR(100) = NULL,
    @Passcode NVARCHAR(20) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DeletedCount INT = 0;

    -- Clean parameters
    SET @DealerName = LTRIM(RTRIM(REPLACE(ISNULL(@DealerName, ''), '%20', ' ')));
    SET @FromSeries = LTRIM(RTRIM(REPLACE(ISNULL(@FromSeries, ''), '%20', ' ')));
    SET @ToSeries = LTRIM(RTRIM(REPLACE(ISNULL(@ToSeries, ''), '%20', ' ')));
    SET @Passcode = LTRIM(RTRIM(REPLACE(ISNULL(@Passcode, ''), '%20', ' ')));

    -- Strip quotes if present
    IF LEN(@DealerName) >= 2 AND LEFT(@DealerName, 1) = '"' AND RIGHT(@DealerName, 1) = '"'
        SET @DealerName = SUBSTRING(@DealerName, 2, LEN(@DealerName) - 2);

    IF UPPER(@Mode) = 'BATCH'
    BEGIN
        IF (@FromSeries IS NULL OR @FromSeries = '' OR @ToSeries IS NULL OR @ToSeries = '')
        BEGIN
            SELECT 0 AS DeletedCount, 0 AS Success, 'FromSeries and ToSeries are required for batch deletion.' AS Message;
            RETURN;
        END

        DELETE FROM [dbo].[tbl_assigncodelocation]
        WHERE Comp_ID = @Comp_Id
          AND fromseries = @FromSeries
          AND toseries = @ToSeries
          AND (@DealerName IS NULL OR @DealerName = '' OR dealer_name = @DealerName OR dealer_name LIKE '%' + @DealerName + '%')
          AND (@Passcode IS NULL OR @Passcode = '' OR Passcode = @Passcode);

        SET @DeletedCount = @@ROWCOUNT;

        SELECT @DeletedCount AS DeletedCount, 1 AS Success, CONCAT(@DeletedCount, ' code(s) removed from assigned series batch.') AS Message;
    END
    ELSE
    BEGIN
        -- Mode = 'CODES'
        IF (@Id IS NOT NULL AND @Id > 0)
        BEGIN
            DELETE FROM [dbo].[tbl_assigncodelocation]
            WHERE Comp_ID = @Comp_Id AND ID = @Id;

            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE IF (@Ids IS NOT NULL AND @Ids <> '')
        BEGIN
            DELETE FROM [dbo].[tbl_assigncodelocation]
            WHERE Comp_ID = @Comp_Id 
              AND ID IN (SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT) FROM STRING_SPLIT(@Ids, ',') WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL);

            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE IF (@Code1 IS NOT NULL AND @Code1 <> '' AND @Code2 IS NOT NULL AND @Code2 <> '')
        BEGIN
            DELETE FROM [dbo].[tbl_assigncodelocation]
            WHERE Comp_ID = @Comp_Id AND Code1 = @Code1 AND Code2 = @Code2;

            SET @DeletedCount = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            SELECT 0 AS DeletedCount, 0 AS Success, 'Valid ID, IDs, or Code1 & Code2 must be provided.' AS Message;
            RETURN;
        END

        SELECT @DeletedCount AS DeletedCount, 1 AS Success, CONCAT(@DeletedCount, ' code(s) deleted successfully.') AS Message;
    END
END
GO
