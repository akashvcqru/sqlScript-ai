USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_AssignCodeDealer_AI]    Script Date: 10-09-2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 10-09-2026
-- Description: Manage Assign Code Dealers in DealerDetailMiniMax (SELECT, INSERT, UPDATE, DELETE)
--              Dealer_Name is UNIQUE Company ID wise (Comp_ID scope).
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_AssignCodeDealer_AI]
(
    @Mode VARCHAR(20) = 'SELECT', -- 'SELECT', 'INSERT', 'UPDATE', 'DELETE'
    @Comp_Id VARCHAR(50),
    @Dealer_ID INT = NULL,
    @Dealer_Name NVARCHAR(100) = NULL,
    @Status INT = NULL,
    @datePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @Search NVARCHAR(100) = NULL,
    @IsExport BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SET @Dealer_Name = LTRIM(RTRIM(ISNULL(@Dealer_Name, '')));
    SET @Search = LTRIM(RTRIM(ISNULL(@Search, '')));

    -- Strip surrounding double quotes if present
    IF LEN(@Dealer_Name) >= 2 AND LEFT(@Dealer_Name, 1) = '"' AND RIGHT(@Dealer_Name, 1) = '"'
        SET @Dealer_Name = SUBSTRING(@Dealer_Name, 2, LEN(@Dealer_Name) - 2);

    IF UPPER(@Mode) = 'SELECT'
    BEGIN
        IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
        IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
        IF @IsExport IS NULL SET @IsExport = 0;
        DECLARE @Offset INT = (@Page - 1) * @Limit;

        DECLARE @StartDate DATETIME = @FromDate;
        DECLARE @EndDate   DATETIME = @ToDate;

        IF (@datePreset IS NOT NULL AND @datePreset <> '' AND LOWER(@datePreset) <> 'null' AND LOWER(@datePreset) <> 'all')
        BEGIN
            DECLARE @Win NVARCHAR(50) = UPPER(LTRIM(RTRIM(@datePreset)));
            DECLARE @Today DATE = CAST(GETDATE() AS DATE);
            SET DATEFIRST 1;

            IF (@Win = 'TODAY')
            BEGIN
                SET @StartDate = CAST(@Today AS DATETIME);
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
            END
            ELSE IF (@Win = 'YESTERDAY' OR @Win = 'LASTDAY')
            BEGIN
                SET @StartDate = DATEADD(DAY, -1, CAST(@Today AS DATETIME));
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, @StartDate));
            END
            ELSE IF (@Win = 'WEEK')
            BEGIN
                SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), CAST(@Today AS DATETIME));
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
            END
            ELSE IF (@Win = 'LASTWEEK')
            BEGIN
                SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @Today) - 1, 0);
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, DATEADD(DAY, 6, @StartDate)));
            END
            ELSE IF (@Win = 'MONTH')
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
            END
            ELSE IF (@Win = 'LASTMONTH')
            BEGIN
                SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today) - 1, 0);
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Today), 0));
            END
            ELSE IF (@Win = 'QUARTER')
            BEGIN
                SET @StartDate = DATEADD(DAY, -90, CAST(@Today AS DATETIME));
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
            END
            ELSE IF (@Win = 'YEAR')
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
                SET @EndDate   = DATEADD(SECOND, -1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)));
            END
            ELSE IF (@Win = 'LASTYEAR')
            BEGIN
                SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
                SET @EndDate   = DATEADD(SECOND, -1, DATEFROMPARTS(YEAR(GETDATE()), 1, 1));
            END
        END
        ELSE IF (@StartDate IS NOT NULL AND @EndDate IS NOT NULL)
        BEGIN
            IF CAST(@EndDate AS TIME) = '00:00:00'
                SET @EndDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @EndDate));
        END

        DECLARE @SearchParam NVARCHAR(102) = NULL;
        IF @Search IS NOT NULL AND @Search <> ''
            SET @SearchParam = '%' + @Search + '%';

        -- 1. Query Data
        SELECT 
            Dealer_ID AS DealerId,
            Dealer_Name AS DealerName,
            CAST(ISNULL(Status, 1) AS INT) AS Status,
            Entry_Date AS EntryDate
        FROM [dbo].[DealerDetailMiniMax] WITH (NOLOCK)
        WHERE Comp_ID = @Comp_Id
          AND (@StartDate IS NULL OR Entry_Date >= @StartDate)
          AND (@EndDate IS NULL OR Entry_Date <= @EndDate)
          AND (@SearchParam IS NULL OR Dealer_Name LIKE @SearchParam OR CAST(Dealer_ID AS NVARCHAR) LIKE @SearchParam)
        ORDER BY Entry_Date DESC, Dealer_ID DESC
        OFFSET CASE WHEN @IsExport = 1 THEN 0 ELSE @Offset END ROWS 
        FETCH NEXT CASE WHEN @IsExport = 1 THEN 1000000 ELSE @Limit END ROWS ONLY;

        -- 2. Query Pagination Meta
        IF @IsExport = 0
        BEGIN
            SELECT 
                COUNT(1) AS TotalRecords,
                @Page AS CurrentPage,
                @Limit AS [Limit],
                CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
            FROM [dbo].[DealerDetailMiniMax] WITH (NOLOCK)
            WHERE Comp_ID = @Comp_Id
              AND (@StartDate IS NULL OR Entry_Date >= @StartDate)
              AND (@EndDate IS NULL OR Entry_Date <= @EndDate)
              AND (@SearchParam IS NULL OR Dealer_Name LIKE @SearchParam OR CAST(Dealer_ID AS NVARCHAR) LIKE @SearchParam);
        END
    END
    ELSE IF UPPER(@Mode) = 'INSERT'
    BEGIN
        IF @Dealer_Name IS NULL OR @Dealer_Name = ''
        BEGIN
            SELECT 0 AS Success, 'Dealer Name is required.' AS Message, 0 AS DealerId;
            RETURN;
        END

        -- Uniqueness check company id wise
        IF EXISTS (SELECT 1 FROM [dbo].[DealerDetailMiniMax] WHERE Dealer_Name = @Dealer_Name AND Comp_ID = @Comp_Id)
        BEGIN
            SELECT 0 AS Success, 'A dealer with this name already exists for your company.' AS Message, 0 AS DealerId;
            RETURN;
        END

        INSERT INTO [dbo].[DealerDetailMiniMax] (Dealer_Name, Status, Entry_Date, Comp_ID)
        VALUES (@Dealer_Name, ISNULL(@Status, 1), GETDATE(), @Comp_Id);

        DECLARE @NewId INT = SCOPE_IDENTITY();
        SELECT 1 AS Success, 'Dealer added successfully.' AS Message, @NewId AS DealerId;
    END
    ELSE IF UPPER(@Mode) = 'UPDATE'
    BEGIN
        IF @Dealer_ID IS NULL OR @Dealer_ID <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid Dealer ID is required for update.' AS Message, 0 AS DealerId;
            RETURN;
        END

        IF @Dealer_Name IS NULL OR @Dealer_Name = ''
        BEGIN
            SELECT 0 AS Success, 'Dealer Name is required.' AS Message, @Dealer_ID AS DealerId;
            RETURN;
        END

        -- Uniqueness check company id wise excluding current Dealer_ID
        IF EXISTS (SELECT 1 FROM [dbo].[DealerDetailMiniMax] WHERE Dealer_Name = @Dealer_Name AND Dealer_ID <> @Dealer_ID AND Comp_ID = @Comp_Id)
        BEGIN
            SELECT 0 AS Success, 'Another dealer with this name already exists for your company.' AS Message, @Dealer_ID AS DealerId;
            RETURN;
        END

        UPDATE [dbo].[DealerDetailMiniMax]
        SET Dealer_Name = @Dealer_Name,
            Status = ISNULL(@Status, Status)
        WHERE Dealer_ID = @Dealer_ID AND Comp_ID = @Comp_Id;

        SELECT 1 AS Success, 'Dealer updated successfully.' AS Message, @Dealer_ID AS DealerId;
    END
    ELSE IF UPPER(@Mode) = 'DELETE'
    BEGIN
        IF @Dealer_ID IS NULL OR @Dealer_ID <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid Dealer ID is required for deletion.' AS Message, 0 AS DealerId;
            RETURN;
        END

        DELETE FROM [dbo].[DealerDetailMiniMax]
        WHERE Dealer_ID = @Dealer_ID AND Comp_ID = @Comp_Id;

        IF @@ROWCOUNT > 0
            SELECT 1 AS Success, 'Dealer deleted successfully.' AS Message, @Dealer_ID AS DealerId;
        ELSE
            SELECT 0 AS Success, 'Dealer not found or already deleted.' AS Message, @Dealer_ID AS DealerId;
    END
END
GO
