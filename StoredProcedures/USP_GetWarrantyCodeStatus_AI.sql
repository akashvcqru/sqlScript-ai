CREATE OR ALTER PROCEDURE [dbo].[USP_GetWarrantyCodeStatus_AI]
    @Code NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- 1. Parse code into Code1 and Code2 if it's 13 digits or hyphenated
    DECLARE @Code1 NUMERIC(5,0) = NULL;
    DECLARE @Code2 NUMERIC(8,0) = NULL;
    DECLARE @CleanCode VARCHAR(50) = REPLACE(LTRIM(RTRIM(@Code)), '-', '');

    IF LEN(@CleanCode) = 13
    BEGIN
        SET @Code1 = TRY_CAST(SUBSTRING(@CleanCode, 1, 5) AS NUMERIC(5,0));
        SET @Code2 = TRY_CAST(SUBSTRING(@CleanCode, 6, 8) AS NUMERIC(8,0));
    END
    ELSE
    BEGIN
        IF CHARINDEX('-', @Code) > 0
        BEGIN
            DECLARE @Idx INT = CHARINDEX('-', @Code);
            SET @Code1 = TRY_CAST(SUBSTRING(@Code, 1, @Idx - 1) AS NUMERIC(5,0));
            SET @Code2 = TRY_CAST(SUBSTRING(@Code, @Idx + 1, LEN(@Code)) AS NUMERIC(8,0));
        END
    END

    -- If parsing failed, return invalid code check status
    IF @Code1 IS NULL OR @Code2 IS NULL
    BEGIN
        SELECT 
            0 AS success, 
            'Please valid 13 digit code.' AS Message;
        RETURN;
    END

    -- 2. Find the code in M_Code
    DECLARE @RowID NUMERIC(12,0) = NULL;
    DECLARE @ProID VARCHAR(50) = NULL;
    DECLARE @CompID VARCHAR(50) = NULL;
    DECLARE @UseCount INT = 0;

    SELECT TOP 1 
        @RowID = mc.Row_ID, 
        @ProID = mc.Pro_ID, 
        @CompID = pr.Comp_ID, 
        @UseCount = ISNULL(mc.Use_Count, 0)
    FROM M_Code mc WITH (NOLOCK)
    INNER JOIN Pro_Reg pr WITH (NOLOCK) ON mc.Pro_ID = pr.Pro_ID
    WHERE mc.Code1 = @Code1 AND mc.Code2 = @Code2;

    -- If code doesn't exist at all, return not check
    IF @RowID IS NULL
    BEGIN
        SELECT 
            0 AS success, 
            'Invalid code. Code does not exist in our database.' AS Message;
        RETURN;
    END

    -- 3. Check if any code check (inquiry log or warranty registration) has occurred
    DECLARE @WarrantyPeriod NVARCHAR(50) = NULL;
    DECLARE @ExpirationDate DATETIME = NULL;
    DECLARE @MobileNo NVARCHAR(20) = NULL;
    DECLARE @Email NVARCHAR(50) = NULL;
    DECLARE @RegisterWarranty BIT = 0;

    SELECT TOP 1 
        @WarrantyPeriod = WarrantyPeriod,
        @ExpirationDate = ExpirationDate,
        @MobileNo = Mobile,
        @Email = Email,
        @RegisterWarranty = 1
    FROM WarrentyDetails WITH (NOLOCK)
    WHERE Code = CAST(@Code1 AS VARCHAR) + '-' + CAST(@Code2 AS VARCHAR) 
       OR Code = @CleanCode;

    DECLARE @HasChecked BIT = 0;
    IF @RegisterWarranty = 1
    BEGIN
        SET @HasChecked = 1;
    END
    ELSE
    BEGIN
        -- Check Pro_Enq
        IF EXISTS (SELECT 1 FROM Pro_Enq WITH (NOLOCK) WHERE Received_Code1 = CAST(@Code1 AS VARCHAR) AND Received_Code2 = CAST(@Code2 AS VARCHAR))
            SET @HasChecked = 1;
        
        -- Fallback to mc.Use_Count
        IF @HasChecked = 0 AND @UseCount >= 1
            SET @HasChecked = 1;
    END

    -- If the code has never been checked/scanned, return false status
    IF @HasChecked = 0
    BEGIN
        SELECT 
            0 AS success, 
            'This code has not been checked or registered yet.' AS Message;
        RETURN;
    END

    -- 4. Gather detailed information
    -- Fetch Product Name
    DECLARE @ProductName NVARCHAR(200) = NULL;
    SELECT TOP 1 @ProductName = Pro_Name FROM Pro_Reg WITH (NOLOCK) WHERE Pro_ID = @ProID;

    -- Warranty Duration fallback from T_Pro if missing
    IF @WarrantyPeriod IS NULL
    BEGIN
        DECLARE @BatchNo VARCHAR(50) = NULL;
        SELECT TOP 1 @BatchNo = Batch_No FROM M_Code WITH (NOLOCK) WHERE Code1 = @Code1 AND Code2 = @Code2;

        SELECT TOP 1 @WarrantyPeriod = CAST(WarrantyDurationMonth AS VARCHAR(50))
        FROM T_Pro WITH (NOLOCK)
        WHERE Row_ID = ISNULL(@BatchNo, '133');
    END

    -- Retrieve latest Code Check Time
    DECLARE @CodeCheckTime DATETIME = NULL;
    SELECT TOP 1 @CodeCheckTime = Enq_Date 
    FROM Pro_Enq WITH (NOLOCK) 
    WHERE Received_Code1 = CAST(@Code1 AS VARCHAR) AND Received_Code2 = CAST(@Code2 AS VARCHAR) 
    ORDER BY Enq_Date ASC;

    IF @CodeCheckTime IS NULL
    BEGIN
        SELECT TOP 1 @CodeCheckTime = ISNULL(claimdate, PurchaseDate) 
        FROM WarrentyDetails WITH (NOLOCK) 
        WHERE Code = CAST(@Code1 AS VARCHAR) + '-' + CAST(@Code2 AS VARCHAR) OR Code = @CleanCode;
    END

    -- Retrieve Mobile number if not populated from WarrentyDetails
    IF @MobileNo IS NULL OR @MobileNo = ''
    BEGIN
        SELECT TOP 1 @MobileNo = MobileNo 
        FROM Pro_Enq WITH (NOLOCK) 
        WHERE Received_Code1 = CAST(@Code1 AS VARCHAR) AND Received_Code2 = CAST(@Code2 AS VARCHAR) 
        ORDER BY Enq_Date ASC;
    END

    -- Retrieve Username from M_Consumer using MobileNo
    DECLARE @UserName NVARCHAR(150) = NULL;
    IF @MobileNo IS NOT NULL AND @MobileNo <> ''
    BEGIN
        SELECT TOP 1 @UserName = ConsumerName 
        FROM M_Consumer WITH (NOLOCK)
        WHERE MobileNo = @MobileNo 
           OR RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10);
    END
    
    IF @UserName IS NULL AND @Email IS NOT NULL AND @Email <> ''
    BEGIN
        SELECT TOP 1 @UserName = ConsumerName FROM M_Consumer WITH (NOLOCK) WHERE Email = @Email;
    END

    -- Fallback username to email, mobile, or default
    IF @UserName IS NULL SET @UserName = ISNULL(NULLIF(@Email, ''), ISNULL(NULLIF(@MobileNo, ''), 'Consumer'));

    DECLARE @LeftNumberOfDays INT = NULL;
    IF @ExpirationDate IS NOT NULL
    BEGIN
        SET @LeftNumberOfDays = DATEDIFF(DAY, GETDATE(), @ExpirationDate);
        IF @LeftNumberOfDays < 0 SET @LeftNumberOfDays = 0;
    END

    -- Return full success details
    SELECT 
        1 AS success,
        @CleanCode AS ThirteenDigitCode,
        @ProductName AS ProductName,
        @ExpirationDate AS ExpireDate,
        @WarrantyPeriod AS WarrantyInMonth,
        @RegisterWarranty AS RegisterWarranty,
        @CodeCheckTime AS CodeCheckTime,
        @UserName AS Username,
        CASE WHEN @UseCount >= 1 OR @HasChecked = 1 THEN 'Used' ELSE 'Un Used' END AS CodeStatus,
        @CompID AS CompanyId,
        @MobileNo AS MobileNo,
        @LeftNumberOfDays AS LeftNumberOfDays;
END
GO
