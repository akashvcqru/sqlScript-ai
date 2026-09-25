SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[USP_BL_ManageDeleteUser]
    @Action VARCHAR(10),            -- 'GET', 'DELETE', 'UNDELETE'
    @Comp_Id VARCHAR(20),
    @M_Consumerid INT = NULL,
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
        SET DATEFIRST 1;
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

    -------------------------------------------------
    -- GET DELETED USERS
    -------------------------------------------------
    IF @Action = 'GET'
    BEGIN
        IF @IsExport = 1
        BEGIN
            SELECT 
                mc.M_Consumerid AS M_Consumerid,
                mc.Entry_Date AS Registration_Date,
                mc.ConsumerName,
                mc.MobileNo AS MobileNumber,
                mc.PinCode,
                mc.City,
                ISNULL(du.Entry_date, vks.Entry_date) AS Deleted_Date
            FROM M_Consumer mc WITH (NOLOCK)
            INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
            LEFT JOIN (
                SELECT M_Consumerid, comp_id, MAX(Entry_date) AS Entry_date
                FROM tbl_DeletedUsers WITH (NOLOCK)
                WHERE comp_id = @Comp_Id
                GROUP BY M_Consumerid, comp_id
            ) du ON du.M_Consumerid = mc.M_Consumerid AND du.comp_id = vks.Comp_id
            WHERE vks.Comp_id = @Comp_Id 
              AND vks.IsDelete = 1
              AND (
                  (du.Entry_date >= @StartDate AND du.Entry_date < @EndDate)
                  OR (du.Entry_date IS NULL AND @Win = 'ALL')
              )
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              )
            ORDER BY ISNULL(du.Entry_date, vks.Entry_date) DESC;
        END
        ELSE
        BEGIN
            SELECT 
                mc.M_Consumerid AS M_Consumerid,
                mc.Entry_Date AS Registration_Date,
                mc.ConsumerName,
                mc.MobileNo AS MobileNumber,
                mc.PinCode,
                mc.City,
                ISNULL(du.Entry_date, vks.Entry_date) AS Deleted_Date
            FROM M_Consumer mc WITH (NOLOCK)
            INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
            LEFT JOIN (
                SELECT M_Consumerid, comp_id, MAX(Entry_date) AS Entry_date
                FROM tbl_DeletedUsers WITH (NOLOCK)
                WHERE comp_id = @Comp_Id
                GROUP BY M_Consumerid, comp_id
            ) du ON du.M_Consumerid = mc.M_Consumerid AND du.comp_id = vks.Comp_id
            WHERE vks.Comp_id = @Comp_Id 
              AND vks.IsDelete = 1
              AND (
                  (du.Entry_date >= @StartDate AND du.Entry_date < @EndDate)
                  OR (du.Entry_date IS NULL AND @Win = 'ALL')
              )
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              )
            ORDER BY ISNULL(du.Entry_date, vks.Entry_date) DESC
            OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;

            -- Pagination metadata
            SELECT 
                COUNT(1) AS TotalRecords,
                @Page AS CurrentPage,
                @Limit AS Limit,
                CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
            FROM M_Consumer mc WITH (NOLOCK)
            INNER JOIN tbl_Vendorvisekycstatus vks WITH (NOLOCK) ON mc.M_Consumerid = vks.M_consumerId
            LEFT JOIN (
                SELECT M_Consumerid, comp_id, MAX(Entry_date) AS Entry_date
                FROM tbl_DeletedUsers WITH (NOLOCK)
                WHERE comp_id = @Comp_Id
                GROUP BY M_Consumerid, comp_id
            ) du ON du.M_Consumerid = mc.M_Consumerid AND du.comp_id = vks.Comp_id
            WHERE vks.Comp_id = @Comp_Id 
              AND vks.IsDelete = 1
              AND (
                  (du.Entry_date >= @StartDate AND du.Entry_date < @EndDate)
                  OR (du.Entry_date IS NULL AND @Win = 'ALL')
              )
              AND (
                  @Search IS NULL 
                  OR mc.ConsumerName LIKE '%' + @Search + '%' 
                  OR mc.MobileNo LIKE '%' + @Search + '%'
              );
        END
    END
    -------------------------------------------------
    -- DELETE USER (Only updates tbl_Vendorvisekycstatus and tbl_DeletedUsers)
    -------------------------------------------------
    ELSE IF @Action = 'DELETE'
    BEGIN
        DECLARE @DeleteConsumerID INT = NULL;

        IF @M_Consumerid IS NOT NULL AND @M_Consumerid > 0
        BEGIN
            SELECT TOP 1 @DeleteConsumerID = mc.M_Consumerid
            FROM M_Consumer mc WITH (NOLOCK)
            WHERE mc.M_Consumerid = @M_Consumerid;
        END
        ELSE IF @MobileNo IS NOT NULL AND LEN(LTRIM(RTRIM(@MobileNo))) > 0
        BEGIN
            SELECT TOP 1 @DeleteConsumerID = mc.M_Consumerid
            FROM M_Consumer mc WITH (NOLOCK)
            WHERE RIGHT(mc.MobileNo, 10) = RIGHT(@MobileNo, 10);
        END

        IF @DeleteConsumerID IS NULL
        BEGIN
            SELECT 0 AS Status, 'Consumer is not registered in the system.' AS Message;
            RETURN;
        END

        -- 1. Update or insert in tbl_Vendorvisekycstatus
        IF EXISTS (SELECT 1 FROM tbl_Vendorvisekycstatus WITH (NOLOCK) WHERE M_consumerId = @DeleteConsumerID AND Comp_id = @Comp_Id)
        BEGIN
            UPDATE tbl_Vendorvisekycstatus
            SET IsDelete = 1
            WHERE M_consumerId = @DeleteConsumerID AND Comp_id = @Comp_Id;
        END
        ELSE
        BEGIN
            INSERT INTO tbl_Vendorvisekycstatus (Comp_id, M_consumerId, IsDelete, Entry_date)
            VALUES (@Comp_Id, @DeleteConsumerID, 1, GETDATE());
        END

        -- 2. Insert or refresh record in tbl_DeletedUsers
        INSERT INTO tbl_DeletedUsers (M_Consumerid, comp_id, Entry_date, IsActive, Updated_date)
        VALUES (@DeleteConsumerID, @Comp_Id, GETDATE(), 1, GETDATE());

        SELECT 1 AS Status, 'User deleted successfully.' AS Message;
    END
    -------------------------------------------------
    -- UNDELETE USER (Only updates tbl_Vendorvisekycstatus and tbl_DeletedUsers)
    -------------------------------------------------
    ELSE IF @Action = 'UNDELETE'
    BEGIN
        DECLARE @UndeleteConsumerID INT = NULL;

        IF @M_Consumerid IS NOT NULL AND @M_Consumerid > 0
        BEGIN
            SET @UndeleteConsumerID = @M_Consumerid;
        END
        ELSE IF @MobileNo IS NOT NULL AND LEN(LTRIM(RTRIM(@MobileNo))) > 0
        BEGIN
            SELECT TOP 1 @UndeleteConsumerID = mc.M_Consumerid
            FROM M_Consumer mc WITH (NOLOCK)
            WHERE RIGHT(mc.MobileNo, 10) = RIGHT(@MobileNo, 10);
        END

        IF @UndeleteConsumerID IS NULL
        BEGIN
            SELECT 0 AS Status, 'Consumer is not registered.' AS Message;
            RETURN;
        END

        -- 1. Restore tbl_Vendorvisekycstatus
        UPDATE tbl_Vendorvisekycstatus
        SET IsDelete = 0
        WHERE M_consumerId = @UndeleteConsumerID AND Comp_id = @Comp_Id;

        -- 2. Deactivate tbl_DeletedUsers records
        UPDATE tbl_DeletedUsers
        SET IsActive = 0,
            Updated_date = GETDATE()
        WHERE M_Consumerid = @UndeleteConsumerID 
          AND comp_id = @Comp_Id 
          AND IsActive = 1;

        SELECT 1 AS Status, 'User undeleted successfully.' AS Message;
    END
END
GO
