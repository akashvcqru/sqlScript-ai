SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Antigravity
-- Create date: 2026-04-07
-- Description: Inserts a record into the Courier_Dispatch_Master table.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[USP_InsertCourierDispatchMaster_AI]
    @Courier_Disp_ID NVARCHAR(50),
    @Comp_ID NVARCHAR(50),
    @Courier_ID NVARCHAR(50) = 'COU_101',
    @Tracking_No NVARCHAR(50),
    @Dispatch_Date DATETIME,
    @Expected_Date DATETIME,
    @Dispatch_Location NVARCHAR(50) = '',
    @Pro_ID NVARCHAR(50) = NULL,
    @Courier_Status INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @Courier_ID IS NULL OR @Courier_ID = ''
    BEGIN
        SET @Courier_ID = 'COU_101';
    END

    IF @Courier_Status IS NULL
    BEGIN
        SET @Courier_Status = 1;
    END

    -- Insert into Courier_Dispatch_Master
    INSERT INTO [dbo].[Courier_Dispatch_Master] (
        [Courier_Disp_ID],
        [Comp_ID],
        [Courier_ID],
        [Pro_ID],
        [Tracking_No],
        [Dispatch_Date],
        [Expected_Date],
        [Dispatch_Location],
        [Courier_Status],
        [Received_Flag],
        [Entry_Date]
    ) VALUES (
        @Courier_Disp_ID,
        @Comp_ID,
        @Courier_ID,
        @Pro_ID,
        @Tracking_No,
        @Dispatch_Date,
        @Expected_Date,
        @Dispatch_Location,
        @Courier_Status,
        1, -- Default to Pending
        GETDATE()
    );
END
GO
