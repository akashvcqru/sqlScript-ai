SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-07
-- Description: Inserts records into the Courier_Disp_ProInfo table.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertCourierDispatchDetail_AI]
    @Courier_Disp_ID NVARCHAR(50),
    @Row_ID BIGINT,
    @Tracking_No NVARCHAR(100),
    @Dispatch_Date DATETIME,
    @Expected_Date DATETIME,
    @Dispatch_Location NVARCHAR(200),
    @Pro_ID NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Label_Code NVARCHAR(50);
    DECLARE @Label_Name NVARCHAR(250);
    DECLARE @PrintRequestTrackingNo NVARCHAR(500);
    DECLARE @Comp_ID NVARCHAR(50);

    -- 1. Get print request details
    SELECT @Label_Code = Label_Code, 
           @PrintRequestTrackingNo = Tracking_No
    FROM [dbo].[M_Label_Request]
    WHERE Row_ID = @Row_ID;

    -- 2. Get Label Name
    SELECT @Label_Name = CONCAT(Label_Name, ' ( ', Label_Size, ' )')
    FROM [dbo].[M_Label] 
    WHERE Label_Code = @Label_Code;

    -- 3. Determine Comp_ID
    SELECT @Comp_ID = Comp_ID 
    FROM [dbo].[Pro_Reg] 
    WHERE Pro_ID = @Pro_ID;

    -- 4. Insert chunked records into Courier_Disp_ProInfo
    IF @Comp_ID = 'Comp-1693'
    BEGIN
        ;WITH CTE AS (
            SELECT 
                Series_Serial,
                Series_Order,
                ROW_NUMBER() OVER(ORDER BY code1, code2) - 1 AS RowNum
            FROM [dbo].[M_Code_PFL]
            WHERE Pro_ID = @Pro_ID AND LabelRequestId = @PrintRequestTrackingNo
        )
        UPDATE CTE
        SET Series_Serial = RowNum % 10000,
            Series_Order = RowNum / 10000
        WHERE Series_Serial IS NULL;

        INSERT INTO [dbo].[Courier_Disp_ProInfo] (
            [Courier_Disp_ID],
            [Pro_ID],
            [Label_Code],
            [Label_Name],
            [Series_From],
            [Series_To],
            [Qty],
            [Entry_Date]
        )
        SELECT 
            @Courier_Disp_ID,
            @Pro_ID,
            @Label_Code,
            @Label_Name,
            -- Format Series_From
            CONVERT(NVARCHAR, @Pro_ID) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(SeriesOrder, 0)), 4) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(MinSerial, 0)), 4),
            -- Format Series_To
            CONVERT(NVARCHAR, @Pro_ID) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(SeriesOrder, 0)), 4) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(MaxSerial, 0)), 4),
            ChunkQty,
            GETDATE()
        FROM (
            SELECT 
                (RowNumber - 1) / 10000 AS ChunkIndex,
                MIN(Series_Serial) AS MinSerial,
                MAX(Series_Serial) AS MaxSerial,
                MAX(Series_Order) AS SeriesOrder,
                COUNT(*) AS ChunkQty
            FROM (
                SELECT 
                    CAST(Series_Serial AS INT) AS Series_Serial,
                    CAST(Series_Order AS INT) AS Series_Order,
                    ROW_NUMBER() OVER(ORDER BY Series_Order, Series_Serial) AS RowNumber
                FROM [dbo].[M_Code_PFL]
                WHERE Pro_ID = @Pro_ID AND LabelRequestId = @PrintRequestTrackingNo
            ) A
            GROUP BY (RowNumber - 1) / 10000
        ) B;
    END
    ELSE
    BEGIN
        ;WITH CTE AS (
            SELECT 
                Series_Serial,
                Series_Order,
                ROW_NUMBER() OVER(ORDER BY code1, code2) - 1 AS RowNum
            FROM [dbo].[M_Code]
            WHERE Pro_ID = @Pro_ID AND LabelRequestId = @PrintRequestTrackingNo
        )
        UPDATE CTE
        SET Series_Serial = RowNum % 10000,
            Series_Order = RowNum / 10000
        WHERE Series_Serial IS NULL;

        INSERT INTO [dbo].[Courier_Disp_ProInfo] (
            [Courier_Disp_ID],
            [Pro_ID],
            [Label_Code],
            [Label_Name],
            [Series_From],
            [Series_To],
            [Qty],
            [Entry_Date]
        )
        SELECT 
            @Courier_Disp_ID,
            @Pro_ID,
            @Label_Code,
            @Label_Name,
            -- Format Series_From
            CONVERT(NVARCHAR, @Pro_ID) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(SeriesOrder, 0)), 4) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(MinSerial, 0)), 4),
            -- Format Series_To
            CONVERT(NVARCHAR, @Pro_ID) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(SeriesOrder, 0)), 4) + '-' + 
            RIGHT('0000' + CONVERT(NVARCHAR, ISNULL(MaxSerial, 0)), 4),
            ChunkQty,
            GETDATE()
        FROM (
            SELECT 
                (RowNumber - 1) / 10000 AS ChunkIndex,
                MIN(Series_Serial) AS MinSerial,
                MAX(Series_Serial) AS MaxSerial,
                MAX(Series_Order) AS SeriesOrder,
                COUNT(*) AS ChunkQty
            FROM (
                SELECT 
                    CAST(Series_Serial AS INT) AS Series_Serial,
                    CAST(Series_Order AS INT) AS Series_Order,
                    ROW_NUMBER() OVER(ORDER BY Series_Order, Series_Serial) AS RowNumber
                FROM [dbo].[M_Code]
                WHERE Pro_ID = @Pro_ID AND LabelRequestId = @PrintRequestTrackingNo
            ) A
            GROUP BY (RowNumber - 1) / 10000
        ) B;
    END

    -- 5. Update M_Code or M_Code_PFL flags for this specific print request
    IF @Comp_ID = 'Comp-1693'
    BEGIN
        UPDATE [dbo].[M_Code_PFL]
        SET [DispatchFlag] = 1,
            [LabelRequestId] = @Tracking_No,Use_Type='L',ReceiveFlag=1
        WHERE Pro_ID = @Pro_ID AND LabelRequestId = @PrintRequestTrackingNo;
    END
    ELSE
    BEGIN
        UPDATE [dbo].[M_Code]
        SET [DispatchFlag] = 1,
            [LabelRequestId] = @Tracking_No,Use_Type='L',ReceiveFlag=1
        WHERE Pro_ID = @Pro_ID AND LabelRequestId = @PrintRequestTrackingNo;
    END
END
GO

