USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_GetChildUsers_AI]
    @dealerid INT,
    @comp_id VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------
    -- 1. Get List of Child Users for Dealer
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#ChildUsers') IS NOT NULL DROP TABLE #ChildUsers;

    SELECT 
        mc.M_Consumerid, 
        mc.ConsumerName, 
        mc.Email, 
        mc.MobileNo
    INTO #ChildUsers
    FROM M_Consumer mc WITH (NOLOCK)
    INNER JOIN tbl_Vendorvisekycstatus vc WITH (NOLOCK) 
        ON mc.M_Consumerid = vc.M_consumerId 
    WHERE vc.Comp_id = @comp_id 
      AND vc.Dealer_M_consumerid = @dealerid
      AND vc.IsDelete = 0;

    -- Result Table
    IF OBJECT_ID('tempdb..#FinalResult') IS NOT NULL DROP TABLE #FinalResult;

    CREATE TABLE #FinalResult (
        M_Consumerid INT,
        ConsumerName VARCHAR(250),
        Email VARCHAR(250),
        MobileNo VARCHAR(50),
        totalPoints DECIMAL(18,2),
        claimPoint DECIMAL(18,2),
        availablePoints DECIMAL(18,2)
    );

    IF NOT EXISTS (SELECT 1 FROM #ChildUsers)
    BEGIN
        SELECT * FROM #FinalResult;
        RETURN;
    END

    ---------------------------------------------------------
    -- 2. Temp Table to Capture Output of USP_GetDashboardSummary_AI
    ---------------------------------------------------------
    IF OBJECT_ID('tempdb..#OverallStats') IS NOT NULL DROP TABLE #OverallStats;

    CREATE TABLE #OverallStats (
        TotalCode INT,
        ReedemPoints DECIMAL(18,2),
        SuccessCode INT,
        UnsuccessCode INT,
        TotalCash DECIMAL(18,2),
        TotalPoints DECIMAL(18,2),
        HasServiceWiseGifts BIT,
        InvalidCode INT
    );

    ---------------------------------------------------------
    -- 3. Loop Child Users and Call USP_GetDashboardSummary_AI
    ---------------------------------------------------------
    DECLARE @curr_M_Consumerid INT, 
            @curr_ConsumerName VARCHAR(250), 
            @curr_Email VARCHAR(250), 
            @curr_MobileNo VARCHAR(50);

    DECLARE child_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT M_Consumerid, ConsumerName, Email, MobileNo FROM #ChildUsers;

    OPEN child_cursor;
    FETCH NEXT FROM child_cursor INTO @curr_M_Consumerid, @curr_ConsumerName, @curr_Email, @curr_MobileNo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        TRUNCATE TABLE #OverallStats;

        BEGIN TRY
            INSERT INTO #OverallStats
            EXEC [dbo].[USP_GetDashboardSummary_AI] 
                @M_Consumerid = @curr_M_Consumerid, 
                @CompID = @comp_id, 
                @OverallStatsOnly = 1;

            INSERT INTO #FinalResult (M_Consumerid, ConsumerName, Email, MobileNo, totalPoints, claimPoint, availablePoints)
            SELECT 
                @curr_M_Consumerid,
                @curr_ConsumerName,
                @curr_Email,
                @curr_MobileNo,
                ISNULL(TotalPoints, 0),
                ISNULL(ReedemPoints, 0),
                ISNULL(TotalPoints, 0) - ISNULL(ReedemPoints, 0)
            FROM #OverallStats;
        END TRY
        BEGIN CATCH
            INSERT INTO #FinalResult (M_Consumerid, ConsumerName, Email, MobileNo, totalPoints, claimPoint, availablePoints)
            VALUES (@curr_M_Consumerid, @curr_ConsumerName, @curr_Email, @curr_MobileNo, 0, 0, 0);
        END CATCH

        FETCH NEXT FROM child_cursor INTO @curr_M_Consumerid, @curr_ConsumerName, @curr_Email, @curr_MobileNo;
    END

    CLOSE child_cursor;
    DEALLOCATE child_cursor;

    ---------------------------------------------------------
    -- 4. Final Selection & Cleanup
    ---------------------------------------------------------
    SELECT * FROM #FinalResult;

    DROP TABLE IF EXISTS #ChildUsers;
    DROP TABLE IF EXISTS #FinalResult;
    DROP TABLE IF EXISTS #OverallStats;
END
GO


