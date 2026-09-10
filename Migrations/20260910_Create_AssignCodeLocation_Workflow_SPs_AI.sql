-- Migration: 20260910_Create_AssignCodeLocation_Workflow_SPs_AI.sql
-- Description: Create USP_SearchSeriesRangeForAssign_AI and USP_AssignCodesToDealer_AI

USE [Vcqru]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 1. USP_SearchSeriesRangeForAssign_AI
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_SearchSeriesRangeForAssign_AI]
(
    @Comp_Id VARCHAR(50),
    @FromSeries NVARCHAR(50),
    @ToSeries NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SET @FromSeries = LTRIM(RTRIM(ISNULL(@FromSeries, '')));
    SET @ToSeries = LTRIM(RTRIM(ISNULL(@ToSeries, '')));

    IF (@FromSeries = '' OR @ToSeries = '')
    BEGIN
        SELECT 
            CAST(NULL AS INT) AS M_CodeID,
            CAST(NULL AS VARCHAR(50)) AS Code1,
            CAST(NULL AS VARCHAR(50)) AS Code2,
            CAST(NULL AS VARCHAR(100)) AS Code,
            CAST(NULL AS VARCHAR(50)) AS Pro_ID,
            CAST(NULL AS VARCHAR(20)) AS Series_Order,
            CAST(NULL AS VARCHAR(20)) AS Series_Serial,
            CAST(NULL AS VARCHAR(100)) AS Series,
            CAST(NULL AS VARCHAR(50)) AS Comp_ID,
            CAST(NULL AS VARCHAR(20)) AS AssignStatus
        WHERE 1 = 0;
        RETURN;
    END

    DECLARE @Pro_ID VARCHAR(50);
    DECLARE @Series_Order VARCHAR(20);
    DECLARE @Series_SerialFrom VARCHAR(20);
    DECLARE @Series_OrderTo VARCHAR(20);
    DECLARE @Series_SerialTo VARCHAR(20);

    IF CHARINDEX('-', @FromSeries) > 0 AND CHARINDEX('-', @FromSeries, CHARINDEX('-', @FromSeries) + 1) > 0
    BEGIN
        SET @Pro_ID = LEFT(@FromSeries, CHARINDEX('-', @FromSeries) - 1);
        SET @Series_Order = SUBSTRING(
            @FromSeries,
            CHARINDEX('-', @FromSeries) + 1,
            CHARINDEX('-', @FromSeries, CHARINDEX('-', @FromSeries) + 1) - CHARINDEX('-', @FromSeries) - 1
        );
        SET @Series_SerialFrom = RIGHT(@FromSeries, LEN(@FromSeries) - CHARINDEX('-', @FromSeries, CHARINDEX('-', @FromSeries) + 1));
    END
    ELSE
    BEGIN
        SET @Pro_ID = PARSENAME(REPLACE(@FromSeries, '-', '.'), 3);
        SET @Series_Order = PARSENAME(REPLACE(@FromSeries, '-', '.'), 2);
        SET @Series_SerialFrom = PARSENAME(REPLACE(@FromSeries, '-', '.'), 1);
    END

    IF CHARINDEX('-', @ToSeries) > 0 AND CHARINDEX('-', @ToSeries, CHARINDEX('-', @ToSeries) + 1) > 0
    BEGIN
        SET @Series_OrderTo = SUBSTRING(
            @ToSeries,
            CHARINDEX('-', @ToSeries) + 1,
            CHARINDEX('-', @ToSeries, CHARINDEX('-', @ToSeries) + 1) - CHARINDEX('-', @ToSeries) - 1
        );
        SET @Series_SerialTo = RIGHT(@ToSeries, LEN(@ToSeries) - CHARINDEX('-', @ToSeries, CHARINDEX('-', @ToSeries) + 1));
    END
    ELSE
    BEGIN
        SET @Series_OrderTo = PARSENAME(REPLACE(@ToSeries, '-', '.'), 2);
        SET @Series_SerialTo = PARSENAME(REPLACE(@ToSeries, '-', '.'), 1);
    END

    DECLARE @OrderFromInt INT = TRY_CAST(@Series_Order AS INT);
    DECLARE @OrderToInt INT = TRY_CAST(@Series_OrderTo AS INT);
    DECLARE @SerialFromInt INT = TRY_CAST(@Series_SerialFrom AS INT);
    DECLARE @SerialToInt INT = TRY_CAST(@Series_SerialTo AS INT);

    IF (@OrderFromInt IS NULL OR @OrderToInt IS NULL OR @SerialFromInt IS NULL OR @SerialToInt IS NULL)
    BEGIN
        SELECT 
            CAST(NULL AS INT) AS M_CodeID,
            CAST(NULL AS VARCHAR(50)) AS Code1,
            CAST(NULL AS VARCHAR(50)) AS Code2,
            CAST(NULL AS VARCHAR(100)) AS Code,
            CAST(NULL AS VARCHAR(50)) AS Pro_ID,
            CAST(NULL AS VARCHAR(20)) AS Series_Order,
            CAST(NULL AS VARCHAR(20)) AS Series_Serial,
            CAST(NULL AS VARCHAR(100)) AS Series,
            CAST(NULL AS VARCHAR(50)) AS Comp_ID,
            CAST(NULL AS VARCHAR(20)) AS AssignStatus
        WHERE 1 = 0;
        RETURN;
    END

    IF (@OrderFromInt > @OrderToInt OR (@OrderFromInt = @OrderToInt AND @SerialFromInt > @SerialToInt))
    BEGIN
        SELECT 
            CAST(NULL AS INT) AS M_CodeID,
            CAST(NULL AS VARCHAR(50)) AS Code1,
            CAST(NULL AS VARCHAR(50)) AS Code2,
            CAST(NULL AS VARCHAR(100)) AS Code,
            CAST(NULL AS VARCHAR(50)) AS Pro_ID,
            CAST(NULL AS VARCHAR(20)) AS Series_Order,
            CAST(NULL AS VARCHAR(20)) AS Series_Serial,
            CAST(NULL AS VARCHAR(100)) AS Series,
            CAST(NULL AS VARCHAR(50)) AS Comp_ID,
            CAST(NULL AS VARCHAR(20)) AS AssignStatus
        WHERE 1 = 0;
        RETURN;
    END

    IF (@OrderFromInt = @OrderToInt)
    BEGIN
        ;WITH CodeList AS (
            SELECT DISTINCT 
                m.Row_ID AS M_CodeID, 
                m.Code1,  
                m.Code2, 
                CONCAT(m.Code1, '-', m.Code2) AS Code,
                m.Pro_ID,  
                m.Series_Order,  
                m.Series_Serial, 
                CONCAT(m.Pro_ID, '-', m.Series_Order, '-', m.Series_Serial) AS Series,
                p.Comp_ID,
                CASE WHEN a.M_CodeID IS NOT NULL THEN 'Already Assigned' ELSE 'Fresh' END AS AssignStatus
            FROM [dbo].[M_Code] m WITH (NOLOCK)
            INNER JOIN [dbo].[pro_reg] p WITH (NOLOCK) ON p.Pro_ID = m.Pro_ID
            LEFT JOIN [dbo].[tbl_assigncodelocation] a WITH (NOLOCK) ON 
                a.M_CodeID = m.Row_ID AND a.Comp_ID = p.Comp_ID
            WHERE m.Pro_ID = @Pro_ID
              AND p.Comp_ID = @Comp_Id
              AND m.Series_Order = @OrderFromInt
              AND m.Series_Serial BETWEEN @SerialFromInt AND @SerialToInt
        )
        SELECT 
            M_CodeID,
            Code1,
            Code2,
            Code,
            Pro_ID,
            CAST(Series_Order AS VARCHAR(20)) AS Series_Order,
            CAST(Series_Serial AS VARCHAR(20)) AS Series_Serial,
            Series,
            Comp_ID,
            AssignStatus
        FROM CodeList
        ORDER BY Series_Order, Series_Serial;
    END
    ELSE
    BEGIN
        ;WITH CodeList AS (
            SELECT DISTINCT 
                m.Row_ID AS M_CodeID, 
                m.Code1,  
                m.Code2, 
                CONCAT(m.Code1, '-', m.Code2) AS Code,
                m.Pro_ID,  
                m.Series_Order,  
                m.Series_Serial, 
                CONCAT(m.Pro_ID, '-', m.Series_Order, '-', m.Series_Serial) AS Series,
                p.Comp_ID,
                CASE WHEN a.M_CodeID IS NOT NULL THEN 'Already Assigned' ELSE 'Fresh' END AS AssignStatus
            FROM [dbo].[M_Code] m WITH (NOLOCK)
            INNER JOIN [dbo].[pro_reg] p WITH (NOLOCK) ON p.Pro_ID = m.Pro_ID
            LEFT JOIN [dbo].[tbl_assigncodelocation] a WITH (NOLOCK) ON 
                a.M_CodeID = m.Row_ID AND a.Comp_ID = p.Comp_ID
            WHERE m.Pro_ID = @Pro_ID
              AND p.Comp_ID = @Comp_Id
              AND (
                    (m.Series_Order = @OrderFromInt AND m.Series_Serial >= @SerialFromInt)
                    OR (m.Series_Order = @OrderToInt AND m.Series_Serial <= @SerialToInt)
                    OR (m.Series_Order > @OrderFromInt AND m.Series_Order < @OrderToInt)
                  )
        )
        SELECT 
            M_CodeID,
            Code1,
            Code2,
            Code,
            Pro_ID,
            CAST(Series_Order AS VARCHAR(20)) AS Series_Order,
            CAST(Series_Serial AS VARCHAR(20)) AS Series_Serial,
            Series,
            Comp_ID,
            AssignStatus
        FROM CodeList
        ORDER BY Series_Order, Series_Serial;
    END
END
GO

-- =============================================
-- 2. USP_AssignCodesToDealer_AI
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_AssignCodesToDealer_AI]
(
    @Comp_Id VARCHAR(50),
    @FromSeries NVARCHAR(50),
    @ToSeries NVARCHAR(50),
    @DealerName NVARCHAR(100),
    @Passcode NVARCHAR(20),
    @MCodeIds NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @DealerName = LTRIM(RTRIM(ISNULL(@DealerName, '')));
    SET @FromSeries = LTRIM(RTRIM(ISNULL(@FromSeries, '')));
    SET @ToSeries = LTRIM(RTRIM(ISNULL(@ToSeries, '')));
    SET @Passcode = LTRIM(RTRIM(ISNULL(@Passcode, '')));

    IF LEN(@DealerName) >= 2 AND LEFT(@DealerName, 1) = '"' AND RIGHT(@DealerName, 1) = '"'
        SET @DealerName = SUBSTRING(@DealerName, 2, LEN(@DealerName) - 2);

    IF (@DealerName = '' OR @FromSeries = '' OR @ToSeries = '' OR @Passcode = '')
    BEGIN
        SELECT 0 AS AssignedCount, 0 AS SkippedCount, '01' AS NextPasscodePrefix, 0 AS Success, 'All fields (FromSeries, ToSeries, DealerName, Passcode) are required.' AS Message;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM [dbo].[DealerDetailMiniMax] WHERE Dealer_Name = @DealerName AND Comp_ID = @Comp_Id)
    BEGIN
        INSERT INTO [dbo].[DealerDetailMiniMax] (Dealer_Name, Status, Entry_Date, Comp_ID)
        VALUES (@DealerName, 1, GETDATE(), @Comp_Id);
    END

    DECLARE @AssignedCount INT = 0;

    IF (@MCodeIds IS NOT NULL AND @MCodeIds <> '')
    BEGIN
        INSERT INTO [dbo].[tbl_assigncodelocation]
        (
            M_CodeID, Code1, Code2, Pro_ID, Series_Order, Series_Serial, 
            Comp_ID, status, entry_date, dealer_name, Passcode, fromseries, toseries
        )
        SELECT 
            m.Row_ID, m.Code1, m.Code2, m.Pro_ID, CAST(m.Series_Order AS VARCHAR(20)), CAST(m.Series_Serial AS VARCHAR(20)),
            p.Comp_ID, 0, GETDATE(), @DealerName, @Passcode, @FromSeries, @ToSeries
        FROM [dbo].[M_Code] m
        INNER JOIN [dbo].[pro_reg] p ON p.Pro_ID = m.Pro_ID
        WHERE p.Comp_ID = @Comp_Id
          AND m.Row_ID IN (SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT) FROM STRING_SPLIT(@MCodeIds, ',') WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL)
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[tbl_assigncodelocation] a WHERE a.M_CodeID = m.Row_ID
          );

        SET @AssignedCount = @@ROWCOUNT;
    END
    ELSE
    BEGIN
        DECLARE @Pro_ID VARCHAR(50);
        DECLARE @Series_Order VARCHAR(20);
        DECLARE @Series_SerialFrom VARCHAR(20);
        DECLARE @Series_OrderTo VARCHAR(20);
        DECLARE @Series_SerialTo VARCHAR(20);

        IF CHARINDEX('-', @FromSeries) > 0 AND CHARINDEX('-', @FromSeries, CHARINDEX('-', @FromSeries) + 1) > 0
        BEGIN
            SET @Pro_ID = LEFT(@FromSeries, CHARINDEX('-', @FromSeries) - 1);
            SET @Series_Order = SUBSTRING(
                @FromSeries,
                CHARINDEX('-', @FromSeries) + 1,
                CHARINDEX('-', @FromSeries, CHARINDEX('-', @FromSeries) + 1) - CHARINDEX('-', @FromSeries) - 1
            );
            SET @Series_SerialFrom = RIGHT(@FromSeries, LEN(@FromSeries) - CHARINDEX('-', @FromSeries, CHARINDEX('-', @FromSeries) + 1));
        END
        ELSE
        BEGIN
            SET @Pro_ID = PARSENAME(REPLACE(@FromSeries, '-', '.'), 3);
            SET @Series_Order = PARSENAME(REPLACE(@FromSeries, '-', '.'), 2);
            SET @Series_SerialFrom = PARSENAME(REPLACE(@FromSeries, '-', '.'), 1);
        END

        IF CHARINDEX('-', @ToSeries) > 0 AND CHARINDEX('-', @ToSeries, CHARINDEX('-', @ToSeries) + 1) > 0
        BEGIN
            SET @Series_OrderTo = SUBSTRING(
                @ToSeries,
                CHARINDEX('-', @ToSeries) + 1,
                CHARINDEX('-', @ToSeries, CHARINDEX('-', @ToSeries) + 1) - CHARINDEX('-', @ToSeries) - 1
            );
            SET @Series_SerialTo = RIGHT(@ToSeries, LEN(@ToSeries) - CHARINDEX('-', @ToSeries, CHARINDEX('-', @ToSeries) + 1));
        END
        ELSE
        BEGIN
            SET @Series_OrderTo = PARSENAME(REPLACE(@ToSeries, '-', '.'), 2);
            SET @Series_SerialTo = PARSENAME(REPLACE(@ToSeries, '-', '.'), 1);
        END

        DECLARE @OrderFromInt INT = TRY_CAST(@Series_Order AS INT);
        DECLARE @OrderToInt INT = TRY_CAST(@Series_OrderTo AS INT);
        DECLARE @SerialFromInt INT = TRY_CAST(@Series_SerialFrom AS INT);
        DECLARE @SerialToInt INT = TRY_CAST(@Series_SerialTo AS INT);

        IF (@OrderFromInt = @OrderToInt)
        BEGIN
            INSERT INTO [dbo].[tbl_assigncodelocation]
            (
                M_CodeID, Code1, Code2, Pro_ID, Series_Order, Series_Serial, 
                Comp_ID, status, entry_date, dealer_name, Passcode, fromseries, toseries
            )
            SELECT 
                m.Row_ID, m.Code1, m.Code2, m.Pro_ID, CAST(m.Series_Order AS VARCHAR(20)), CAST(m.Series_Serial AS VARCHAR(20)),
                p.Comp_ID, 0, GETDATE(), @DealerName, @Passcode, @FromSeries, @ToSeries
            FROM [dbo].[M_Code] m
            INNER JOIN [dbo].[pro_reg] p ON p.Pro_ID = m.Pro_ID
            WHERE m.Pro_ID = @Pro_ID
              AND p.Comp_ID = @Comp_Id
              AND m.Series_Order = @OrderFromInt
              AND m.Series_Serial BETWEEN @SerialFromInt AND @SerialToInt
              AND NOT EXISTS (
                  SELECT 1 FROM [dbo].[tbl_assigncodelocation] a WHERE a.M_CodeID = m.Row_ID
              );

            SET @AssignedCount = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[tbl_assigncodelocation]
            (
                M_CodeID, Code1, Code2, Pro_ID, Series_Order, Series_Serial, 
                Comp_ID, status, entry_date, dealer_name, Passcode, fromseries, toseries
            )
            SELECT 
                m.Row_ID, m.Code1, m.Code2, m.Pro_ID, CAST(m.Series_Order AS VARCHAR(20)), CAST(m.Series_Serial AS VARCHAR(20)),
                p.Comp_ID, 0, GETDATE(), @DealerName, @Passcode, @FromSeries, @ToSeries
            FROM [dbo].[M_Code] m
            INNER JOIN [dbo].[pro_reg] p ON p.Pro_ID = m.Pro_ID
            WHERE m.Pro_ID = @Pro_ID
              AND p.Comp_ID = @Comp_Id
              AND (
                    (m.Series_Order = @OrderFromInt AND m.Series_Serial >= @SerialFromInt)
                    OR (m.Series_Order = @OrderToInt AND m.Series_Serial <= @SerialToInt)
                    OR (m.Series_Order > @OrderFromInt AND m.Series_Order < @OrderToInt)
                  )
              AND NOT EXISTS (
                  SELECT 1 FROM [dbo].[tbl_assigncodelocation] a WHERE a.M_CodeID = m.Row_ID
              );

            SET @AssignedCount = @@ROWCOUNT;
        END
    END

    DECLARE @LastId INT = 0;
    SELECT @LastId = ISNULL(MAX(ID), 0) FROM [dbo].[tbl_assigncodelocation];
    SET @LastId = @LastId + 1;
    DECLARE @NextPrefix VARCHAR(10) = RIGHT('00' + CAST(@LastId AS VARCHAR(10)), 2);

    IF (@AssignedCount > 0)
    BEGIN
        SELECT 
            @AssignedCount AS AssignedCount, 
            0 AS SkippedCount, 
            @NextPrefix AS NextPasscodePrefix, 
            1 AS Success, 
            CONCAT(@AssignedCount, ' code(s) assigned successfully.') AS Message;
    END
    ELSE
    BEGIN
        SELECT 
            0 AS AssignedCount, 
            0 AS SkippedCount, 
            @NextPrefix AS NextPasscodePrefix, 
            0 AS Success, 
            'No fresh codes found to assign (codes in this range may already be assigned).' AS Message;
    END
END
GO
