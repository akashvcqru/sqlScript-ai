USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:      Antigravity
-- Create date: 2026-07-29
-- Description: Iterates through all users in tbl_Vendorvisekycstatus for a given CompID,
--              calling USP_GetDashboardSummary_AI one by one for each user
--              and combining the aggregated data.
-- ==========================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetDashboardSummaryAllUsers_AI]
(
    @CompID VARCHAR(50),
    @TempTableName NVARCHAR(256) = NULL
)
WITH RECOMPILE
AS
BEGIN
    SET NOCOUNT ON;

    -- Table to accumulate overall stats for all users
    CREATE TABLE #TempUserStats
    (
        M_consumerId INT,
        MobileNo VARCHAR(100),
        Name VARCHAR(500),
        TotalCode INT,
        ReedemPoints DECIMAL(18,2),
        SuccessCode INT,
        TotalCash DECIMAL(18,2),
        TotalPoints DECIMAL(18,2),
        HasServiceWiseGifts INT
    );

    -- Helper table to capture the first result set of USP_GetDashboardSummary_AI
    CREATE TABLE #TempSingleUserStats
    (
        TotalCode INT,
        ReedemPoints DECIMAL(18,2),
        SuccessCode INT,
        TotalCash DECIMAL(18,2),
        TotalPoints DECIMAL(18,2),
        HasServiceWiseGifts INT
    );

    -- Cursor to iterate through users
    DECLARE @M_consumerId INT;
    DECLARE @MobileNo VARCHAR(100);
    DECLARE @Name VARCHAR(500);

    -- Join with M_Consumer to get actual MobileNo and ConsumerName
    -- Filter out NULL or empty MobileNo to ensure USP_GetDashboardSummary_AI returns its result set
    DECLARE UserCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT 
        v.M_consumerId,
        m.MobileNo,
        m.ConsumerName AS Name
    FROM dbo.tbl_Vendorvisekycstatus v WITH (NOLOCK)
    INNER JOIN dbo.M_Consumer m WITH (NOLOCK) ON v.M_consumerId = m.M_Consumerid
    WHERE v.Comp_id = @CompID 
      AND v.IsDelete = 0
      AND m.MobileNo IS NOT NULL
      AND m.MobileNo <> '';

    OPEN UserCursor;

    FETCH NEXT FROM UserCursor INTO @M_consumerId, @MobileNo, @Name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #TempSingleUserStats;

        BEGIN TRY
            -- Call the stored procedure for the user and capture its first result set (Overall Stats)
            INSERT INTO #TempSingleUserStats
            EXEC [dbo].[USP_GetDashboardSummary_AI] @M_Consumerid = @M_consumerId, @CompID = @CompID, @OverallStatsOnly = 1;

            -- Combine current user info with captured stats
            INSERT INTO #TempUserStats (M_consumerId, MobileNo, Name, TotalCode, ReedemPoints, SuccessCode, TotalCash, TotalPoints, HasServiceWiseGifts)
            SELECT 
                @M_consumerId, 
                @MobileNo, 
                @Name, 
                ISNULL(TotalCode, 0), 
                ISNULL(ReedemPoints, 0.00), 
                ISNULL(SuccessCode, 0), 
                ISNULL(TotalCash, 0.00), 
                ISNULL(TotalPoints, 0.00), 
                ISNULL(HasServiceWiseGifts, 0)
            FROM #TempSingleUserStats;
            
        END TRY
        BEGIN CATCH
            DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
            PRINT 'Error processing M_consumerId: ' + CAST(@M_consumerId AS VARCHAR(20)) + ' - ' + @ErrorMsg;
        END CATCH

        FETCH NEXT FROM UserCursor INTO @M_consumerId, @MobileNo, @Name;
    END

    CLOSE UserCursor;
    DEALLOCATE UserCursor;

    -- Determine which temp table to insert into
    DECLARE @ActualTempTable NVARCHAR(256) = NULL;

    IF @TempTableName IS NOT NULL AND OBJECT_ID('tempdb..' + @TempTableName) IS NOT NULL
    BEGIN
        SET @ActualTempTable = @TempTableName;
    END
    ELSE
    BEGIN
        -- Dynamically detect any temp table in the current session starting with '#TempDashboardSummary'
        DECLARE @MangledName NVARCHAR(256) = NULL;
        
        SELECT TOP 1 @MangledName = name
        FROM tempdb.sys.tables
        WHERE name LIKE '#TempDashboardSummary%'
          AND OBJECT_ID('tempdb..' + SUBSTRING(name, 1, CHARINDEX('___', name) - 1)) IS NOT NULL;
          
        IF @MangledName IS NOT NULL
        BEGIN
            DECLARE @Idx INT = CHARINDEX('___', @MangledName);
            IF @Idx > 0
                SET @ActualTempTable = SUBSTRING(@MangledName, 1, @Idx - 1);
            ELSE
                SET @ActualTempTable = @MangledName;
        END
    END

    -- Return final aggregated data
    IF @ActualTempTable IS NOT NULL
    BEGIN
        DECLARE @Sql NVARCHAR(MAX);
        SET @Sql = N'INSERT INTO ' + @ActualTempTable + N' (M_consumerId, MobileNo, Name, TotalCode, ReedemPoints, SuccessCode, TotalCash, TotalPoints, NetAvailablePoints, HasServiceWiseGifts)
        SELECT 
            M_consumerId,
            MobileNo,
            Name,
            ISNULL(TotalCode, 0),
            ISNULL(ReedemPoints, 0.00),
            ISNULL(SuccessCode, 0),
            ISNULL(TotalCash, 0.00),
            ISNULL(TotalPoints, 0.00),
            ISNULL(TotalPoints, 0.00) - ISNULL(ReedemPoints, 0.00),
            ISNULL(HasServiceWiseGifts, 0)
        FROM #TempUserStats
        ORDER BY TotalPoints DESC;';
        
        EXEC sp_executesql @Sql;
    END
    ELSE
    BEGIN
        SELECT 
            M_consumerId,
            MobileNo,
            Name,
            ISNULL(TotalCode, 0) AS TotalCode,
            ISNULL(ReedemPoints, 0.00) AS ReedemPoints,
            ISNULL(SuccessCode, 0) AS SuccessCode,
            ISNULL(TotalCash, 0.00) AS TotalCash,
            ISNULL(TotalPoints, 0.00) AS TotalPoints,
            ISNULL(TotalPoints, 0.00) - ISNULL(ReedemPoints, 0.00) AS NetAvailablePoints,
            ISNULL(HasServiceWiseGifts, 0) AS HasServiceWiseGifts
        FROM #TempUserStats
        ORDER BY TotalPoints DESC;
    END

    -- Clean up temp tables
    DROP TABLE IF EXISTS #TempUserStats;
    DROP TABLE IF EXISTS #TempSingleUserStats;
END
GO
