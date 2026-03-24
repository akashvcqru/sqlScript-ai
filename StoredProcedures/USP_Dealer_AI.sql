CREATE OR ALTER PROCEDURE [dbo].[USP_Dealer_AI]
    @Mode NVARCHAR(20),
    @ID INT = NULL,
    @Dealer_Name NVARCHAR(200) = NULL,
    @Dealer_Location NVARCHAR(500) = NULL,
    @mobile NVARCHAR(15) = NULL,
    @email NVARCHAR(100) = NULL,
    @Invoice_Number NVARCHAR(100) = NULL,
    @Latitude NVARCHAR(50) = NULL,
    @Longitude NVARCHAR(50) = NULL,
    @Comp_ID NVARCHAR(50) = NULL,
    @Page INT = 1,
    @Limit INT = 10,
    @SearchQuery NVARCHAR(200) = '',
    @TimeWindow NVARCHAR(50) = '',
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Mode = 'INSERT'
    BEGIN
        INSERT INTO [M_Dealer_AI] (
            [Dealer_Name], 
            [Dealer_Location], 
            [mobile], 
            [email], 
            [Invoice_Number], 
            [Latitude], 
            [Longitude], 
            [Comp_ID]
        )
        VALUES (
            @Dealer_Name, 
            @Dealer_Location, 
            @mobile, 
            @email, 
            @Invoice_Number, 
            @Latitude, 
            @Longitude, 
            @Comp_ID
        );
        
        SELECT SCOPE_IDENTITY() AS NewID;
    END
    ELSE IF @Mode = 'UPDATE'
    BEGIN
        UPDATE [M_Dealer_AI]
        SET [Dealer_Name] = ISNULL(@Dealer_Name, [Dealer_Name]),
            [Dealer_Location] = ISNULL(@Dealer_Location, [Dealer_Location]),
            [mobile] = ISNULL(@mobile, [mobile]),
            [email] = ISNULL(@email, [email]),
            [Invoice_Number] = ISNULL(@Invoice_Number, [Invoice_Number]),
            [Latitude] = ISNULL(@Latitude, [Latitude]),
            [Longitude] = ISNULL(@Longitude, [Longitude])
        WHERE [ID] = @ID AND [Comp_ID] = @Comp_ID;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    ELSE IF @Mode = 'DELETE'
    BEGIN
        UPDATE [M_Dealer_AI]
        SET [isdelete] = 1
        WHERE [ID] = @ID AND [Comp_ID] = @Comp_ID;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END
    ELSE IF @Mode = 'SELECT'
    BEGIN
        DECLARE @CalculatedFromDate DATETIME = NULL;
        DECLARE @CalculatedToDate DATETIME = NULL;

        IF @TimeWindow = 'this week'
        BEGIN
            SET @CalculatedFromDate = DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0);
            SET @CalculatedToDate = GETDATE();
        END
        ELSE IF @TimeWindow = 'lastweek' OR @TimeWindow = 'last week'
        BEGIN
            SET @CalculatedFromDate = DATEADD(week, DATEDIFF(week, 7, GETDATE()), 0);
            SET @CalculatedToDate = DATEADD(second, -1, DATEADD(week, DATEDIFF(week, 0, GETDATE()), 0));
        END
        ELSE IF @TimeWindow = 'this month'
        BEGIN
            SET @CalculatedFromDate = DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0);
            SET @CalculatedToDate = GETDATE();
        END
        ELSE IF @TimeWindow = 'last month'
        BEGIN
            SET @CalculatedFromDate = DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0);
            SET @CalculatedToDate = DATEADD(second, -1, DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0));
        END
        ELSE IF @TimeWindow = 'quarter'
        BEGIN
            SET @CalculatedFromDate = DATEADD(quarter, DATEDIFF(quarter, 0, GETDATE()), 0);
            SET @CalculatedToDate = GETDATE();
        END
        ELSE IF @FromDate IS NOT NULL OR @ToDate IS NOT NULL OR @TimeWindow = 'from to date'
        BEGIN
            SET @CalculatedFromDate = @FromDate;
            SET @CalculatedToDate = ISNULL(DATEADD(day, 1, @ToDate), GETDATE()); 
        END

        SELECT 
            [ID],
            [Dealer_Name],
            [Dealer_Location],
            [mobile],
            [email],
            [Invoice_Number],
            [Latitude],
            [Longitude],
            [entry_date]
        FROM [M_Dealer_AI]
        WHERE [Comp_ID] = @Comp_ID AND [isdelete] = 0
          AND (@SearchQuery = '' OR [Dealer_Name] LIKE '%' + @SearchQuery + '%' OR [Invoice_Number] LIKE '%' + @SearchQuery + '%' OR [mobile] LIKE '%' + @SearchQuery + '%' OR [email] LIKE '%' + @SearchQuery + '%')
          AND (@CalculatedFromDate IS NULL OR [entry_date] >= @CalculatedFromDate)
          AND (@CalculatedToDate IS NULL OR [entry_date] <= @CalculatedToDate)
        ORDER BY [entry_date] DESC
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;

        SELECT COUNT(*) AS TotalRecords
        FROM [M_Dealer_AI]
        WHERE [Comp_ID] = @Comp_ID AND [isdelete] = 0
          AND (@SearchQuery = '' OR [Dealer_Name] LIKE '%' + @SearchQuery + '%' OR [Invoice_Number] LIKE '%' + @SearchQuery + '%' OR [mobile] LIKE '%' + @SearchQuery + '%' OR [email] LIKE '%' + @SearchQuery + '%')
          AND (@CalculatedFromDate IS NULL OR [entry_date] >= @CalculatedFromDate)
          AND (@CalculatedToDate IS NULL OR [entry_date] <= @CalculatedToDate);
    END
END
GO
