SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[USP_BL_ManageBlockUser]
    @Action VARCHAR(10),        -- 'GET' or 'ADD'
    @Comp_Id VARCHAR(20) = NULL,
    @MobileNo VARCHAR(20) = NULL,
    @Search VARCHAR(100) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @IsExport BIT = 0,
    @DatePreset NVARCHAR(20) = NULL,
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- Construct Date Range
    -------------------------------------------------
    DECLARE @StartDate DATE, @EndDate DATE;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    DECLARE @Win NVARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@DatePreset,''))));
    
    IF @Win = '' OR @Win = 'NULL' SET @Win = 'ALL';

    IF @Win = 'TODAY'
    BEGIN
        SET @StartDate = @Today;
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YESTERDAY' OR @Win = 'LASTDAY'
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, @Today);
        SET @EndDate   = @Today;
    END
    ELSE IF @Win = 'WEEK'
    BEGIN
        SET DATEFIRST 1; -- Monday
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTWEEK'
    BEGIN
        SET DATEFIRST 1;
        DECLARE @ThisWeekStart DATE = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @StartDate = DATEADD(DAY, -7, @ThisWeekStart);
        SET @EndDate   = @ThisWeekStart;
    END
    ELSE IF @Win = 'MONTH'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTMONTH'
    BEGIN
        DECLARE @ThisMonthStart DATE = DATEFROMPARTS(YEAR(@Today), MONTH(@Today), 1);
        SET @StartDate = DATEADD(MONTH, -1, @ThisMonthStart);
        SET @EndDate   = @ThisMonthStart;
    END
    ELSE IF @Win = 'QUARTER'
    BEGIN
        SET @StartDate = DATEADD(DAY, -90, @Today);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'YEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'LASTYEAR'
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(@Today) - 1, 1, 1);
        SET @EndDate   = DATEFROMPARTS(YEAR(@Today), 1, 1);
    END
    ELSE IF @Win = 'ALL'
    BEGIN
        SET @StartDate = '1900-01-01';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END
    ELSE IF @Win = 'CUSTOM'
    BEGIN
        SET @StartDate = ISNULL(CAST(@FromDate AS DATE), '1900-01-01');
        SET @EndDate   = DATEADD(DAY, 1, ISNULL(CAST(@ToDate AS DATE), @Today));
    END
    ELSE
    BEGIN
        SET @StartDate = '1900-01-01';
        SET @EndDate   = DATEADD(DAY, 1, @Today);
    END

    IF @Action = 'GET'
    BEGIN
        IF @IsExport = 1
        BEGIN
            SELECT 
                mc.Entry_Date AS Registration_Date,
                mc.ConsumerName,
                mc.MobileNo AS MobileNumber,
                mc.PinCode,
                mc.City,
                mc.block_date AS block_date
            FROM M_Consumer mc WITH (NOLOCK)
            INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
            WHERE vks.Comp_id = @Comp_Id 
              AND (
                  (mc.IsDelete = '1')
                  OR (vks.IsDelete = 1)
              )
              AND (
                  (mc.block_date >= @StartDate AND mc.block_date < @EndDate)
                  OR (mc.block_date IS NULL AND @Win = 'ALL')
              )
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              )
            ORDER BY mc.Entry_Date DESC;
        END
        ELSE
        BEGIN
            SELECT 
                mc.Entry_Date AS Registration_Date,
                mc.ConsumerName,
                mc.MobileNo AS MobileNumber,
                mc.PinCode,
                mc.City,
                mc.block_date AS block_date
            FROM M_Consumer mc WITH (NOLOCK)
            INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
            WHERE vks.Comp_id = @Comp_Id 
              AND (
                  (mc.IsActive = '1' AND mc.IsDelete = '1')
                  OR (vks.IsActive = 1 AND vks.IsDelete = 1)
              )
              AND (
                  (mc.block_date >= @StartDate AND mc.block_date < @EndDate)
                  OR (mc.block_date IS NULL AND @Win = 'ALL')
              )
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              )
            ORDER BY mc.Entry_Date DESC
            OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;

            -- Pagination metadata
            SELECT 
                COUNT(1) AS TotalRecords,
                @Page AS CurrentPage,
                @Limit AS Limit,
                CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
            FROM M_Consumer mc WITH (NOLOCK)
            INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
            WHERE vks.Comp_id = @Comp_Id 
              AND (
                  (mc.IsDelete = '1')
                  OR (vks.IsDelete = 1)
              )
              AND (
                  (mc.block_date >= @StartDate AND mc.block_date < @EndDate)
                  OR (mc.block_date IS NULL AND @Win = 'ALL')
              )
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              );
        END
    END
    ELSE IF @Action = 'ADD'
    BEGIN
        -- Verify that the consumer is registered under the company in M_Consumer and tbl_Vendorvisekycstatus
        DECLARE @ConsumerID INT = NULL;

        SELECT TOP 1 @ConsumerID = mc.M_Consumerid
        FROM M_Consumer mc WITH (NOLOCK)
        INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
        WHERE RIGHT(mc.MobileNo, 10) = RIGHT(@MobileNo, 10)
          AND vks.Comp_id = @Comp_Id;

        IF @ConsumerID IS NULL
        BEGIN
            SELECT 0 AS Status, 'Consumer is not registered under this company.' AS Message;
            RETURN;
        END

        UPDATE M_Consumer
        SET IsActive = '1',
            IsDelete = '1',
            block_date = GETDATE()
        WHERE M_Consumerid = @ConsumerID;

        UPDATE tbl_Vendorvisekycstatus
        SET IsActive = 1,
            IsDelete = 1
        WHERE M_consumerId = @ConsumerID AND Comp_id = @Comp_Id;

        IF @@ROWCOUNT > 0
        BEGIN
            SELECT 1 AS Status, 'Consumer marked as Blocked.' AS Message;
        END
        ELSE
        BEGIN
            SELECT 0 AS Status, 'Failed to block the consumer.' AS Message;
        END
    END
END
GO
