USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_SearchSeriesRangeForAssign_AI]    Script Date: 10-09-2026 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 10-09-2026
-- Description: Search code series range in M_Code and check assignment status in tbl_assigncodelocation
-- Reference:   USP_assigncodelocation_sp / AssignCodeLocation.aspx.cs
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
            CAST(NULL AS VARCHAR(100)) AS Code,
            CAST(NULL AS VARCHAR(50)) AS Pro_ID,
            CAST(NULL AS VARCHAR(20)) AS Series_Order,
            CAST(NULL AS VARCHAR(20)) AS Series_Serial,
            CAST(NULL AS VARCHAR(100)) AS Series,
            CAST(NULL AS VARCHAR(20)) AS AssignStatus
        WHERE 1 = 0;
        RETURN;
    END

    -- Declare split variables
    DECLARE @Pro_ID VARCHAR(50);
    DECLARE @Series_Order VARCHAR(20);
    DECLARE @Series_SerialFrom VARCHAR(20);
    DECLARE @Series_OrderTo VARCHAR(20);
    DECLARE @Series_SerialTo VARCHAR(20);

    -- Parse FromSeries
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

    -- Parse ToSeries
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
            CAST(NULL AS VARCHAR(100)) AS Code,
            CAST(NULL AS VARCHAR(50)) AS Pro_ID,
            CAST(NULL AS VARCHAR(20)) AS Series_Order,
            CAST(NULL AS VARCHAR(20)) AS Series_Serial,
            CAST(NULL AS VARCHAR(100)) AS Series,
            CAST(NULL AS VARCHAR(20)) AS AssignStatus
        WHERE 1 = 0;
        RETURN;
    END

    IF (@OrderFromInt > @OrderToInt OR (@OrderFromInt = @OrderToInt AND @SerialFromInt > @SerialToInt))
    BEGIN
        SELECT 
            CAST(NULL AS INT) AS M_CodeID,
            CAST(NULL AS VARCHAR(100)) AS Code,
            CAST(NULL AS VARCHAR(50)) AS Pro_ID,
            CAST(NULL AS VARCHAR(20)) AS Series_Order,
            CAST(NULL AS VARCHAR(20)) AS Series_Serial,
            CAST(NULL AS VARCHAR(100)) AS Series,
            CAST(NULL AS VARCHAR(20)) AS AssignStatus
        WHERE 1 = 0;
        RETURN;
    END

    -- Query M_Code and evaluate AssignStatus
    IF (@OrderFromInt = @OrderToInt)
    BEGIN
        ;WITH CodeList AS (
            SELECT DISTINCT 
                m.Row_ID AS M_CodeID, 
                CONCAT(m.Code1, m.Code2) AS Code,
                m.Pro_ID,  
                m.Series_Order,  
                m.Series_Serial, 
                CONCAT(m.Pro_ID, '-', m.Series_Order, '-', m.Series_Serial) AS Series,
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
            Code,
            Pro_ID,
            CAST(Series_Order AS VARCHAR(20)) AS Series_Order,
            CAST(Series_Serial AS VARCHAR(20)) AS Series_Serial,
            Series,
            AssignStatus
        FROM CodeList
        ORDER BY Series_Order, Series_Serial;
    END
    ELSE
    BEGIN
        ;WITH CodeList AS (
            SELECT DISTINCT 
                m.Row_ID AS M_CodeID, 
                CONCAT(m.Code1, m.Code2) AS Code,
                m.Pro_ID,  
                m.Series_Order,  
                m.Series_Serial, 
                CONCAT(m.Pro_ID, '-', m.Series_Order, '-', m.Series_Serial) AS Series,
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
            Code,
            Pro_ID,
            CAST(Series_Order AS VARCHAR(20)) AS Series_Order,
            CAST(Series_Serial AS VARCHAR(20)) AS Series_Serial,
            Series,
            AssignStatus
        FROM CodeList
        ORDER BY Series_Order, Series_Serial;
    END
END
GO
