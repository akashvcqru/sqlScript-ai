/****** Object:  StoredProcedure [dbo].[SP_BL_GetNewUsersAndKYCReportAutoFilterData]    Script Date: 3/2/2026 12:27:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_BL_GetNewUsersAndKYCReportAutoFilterData]
    @Comp_Id VARCHAR(15),
    @TimeWindow NVARCHAR(20) = NULL ,  -- TODAY, YESTERDAY, WEEK, LASTWEEK, MONTH, QUARTER
    @FromDate DATE = NULL,              
    @ToDate DATE = NULL,                
    @KYCStatusFilter NVARCHAR(20) = NULL,
    @StateFilter NVARCHAR(100) = NULL,   
    @Page INT = NULL,                    
    @Limit INT = NULL,
    @IsExport BIT =NULL,
    @Search nvarchar(30) = null
  
AS
BEGIN
   SET NOCOUNT ON;

    ------------------------------------------------------
    -- Pagination Defaults
    ------------------------------------------------------
    IF @Page IS NULL OR @Page <= 0 SET @Page = 1;
    IF @Limit IS NULL OR @Limit <= 0 SET @Limit = 10;
    IF @IsExport IS NULL SET @IsExport = 0;

    DECLARE @Offset INT = (@Page - 1) * @Limit;

    ------------------------------------------------------
    -- Fetch KYC Requirements
    ------------------------------------------------------
    DECLARE 
        @AadharCardReq NVARCHAR(10) = 'No',
        @PANCardReq NVARCHAR(10) = 'No',
        @UPIReq NVARCHAR(10) = 'No',
        @AccountDetails NVARCHAR(10) = 'No';

    ;WITH Req AS (
        SELECT j.[key], j.[value]
        FROM claimKycForWebMVC c
        CROSS APPLY OPENJSON(c.kyc_Details) j
        WHERE c.Comp_ID = @Comp_Id
    )
    SELECT
        @AadharCardReq = CASE WHEN EXISTS (SELECT 1 FROM Req WHERE [key]='AadharCard' AND [value]='Yes') THEN 'Yes' ELSE 'No' END,
        @PANCardReq = CASE WHEN EXISTS (SELECT 1 FROM Req WHERE [key]='PANCard' AND [value]='Yes') THEN 'Yes' ELSE 'No' END,
        @UPIReq = CASE WHEN EXISTS (SELECT 1 FROM Req WHERE [key]='UPI' AND [value]='Yes') THEN 'Yes' ELSE 'No' END,
        @AccountDetails = CASE WHEN EXISTS (SELECT 1 FROM Req WHERE [key]='AccountDetails' AND [value]='Yes') THEN 'Yes' ELSE 'No' END;

    ------------------------------------------------------
    -- Date Range
    ------------------------------------------------------
    DECLARE @StartDate DATE = NULL;
    DECLARE @EndDate   DATE = NULL;

    -- Normalize TimeWindow
    IF (
           @TimeWindow IS NULL
        OR LTRIM(RTRIM(@TimeWindow)) = ''
        OR LOWER(LTRIM(RTRIM(@TimeWindow))) = 'null'
    )
        SET @TimeWindow = NULL;
    ELSE
        SET @TimeWindow = UPPER(LTRIM(RTRIM(@TimeWindow)));

    -- Explicit date range overrides TimeWindow
    IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
    BEGIN
        SET @StartDate = @FromDate;
        SET @EndDate   = @ToDate;
    END
    ELSE
    BEGIN
        SET @EndDate = CAST(GETDATE() AS DATE);
        SET DATEFIRST 1; -- Monday start

        IF (@TimeWindow = 'TODAY')
            SET @StartDate = @EndDate;

        ELSE IF (@TimeWindow = 'YESTERDAY')
        BEGIN
            SET @StartDate = DATEADD(DAY, -1, @EndDate);
            SET @EndDate   = DATEADD(DAY, -1, @EndDate);
        END

        ELSE IF (@TimeWindow = 'WEEK')
            SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @EndDate), @EndDate);

        ELSE IF (@TimeWindow = 'LASTWEEK')
        BEGIN
            SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(WEEK, DATEDIFF(WEEK, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'MONTH')
            SET @StartDate = DATEFROMPARTS(YEAR(@EndDate), MONTH(@EndDate), 1);

        ELSE IF (@TimeWindow = 'LASTMONTH')
        BEGIN
            SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate) - 1, 0);
            SET @EndDate   = DATEADD(DAY, -1,
                               DATEADD(MONTH, DATEDIFF(MONTH, 0, @EndDate), 0));
        END

        ELSE IF (@TimeWindow = 'QUARTER')
            SET @StartDate = DATEADD(DAY, -90, @EndDate);

        ELSE -- ALL / NULL
        BEGIN
            SET @StartDate = NULL;
            SET @EndDate   = NULL;
        END
    END


    ------------------------------------------------------
    -- Base WHERE clause
    ------------------------------------------------------
    DECLARE @BaseWhere NVARCHAR(MAX) = N'
        WHERE VKS.Comp_ID = @Comp_Id
          AND MC.IsDelete = 0';

    IF @StartDate IS NOT NULL
        SET @BaseWhere += N' AND CAST(VKS.Entry_Date AS DATE) BETWEEN @StartDate AND @EndDate';

    IF @KYCStatusFilter IS NOT NULL
        SET @BaseWhere += N'
        AND (
            (@KYCStatusFilter = ''APPROVED'' AND VKS.VRKbl_KYC_status = 1) OR
            (@KYCStatusFilter = ''REJECTED'' AND VKS.VRKbl_KYC_status = 2) OR
            (@KYCStatusFilter = ''PENDING'' AND (VKS.VRKbl_KYC_status = 0 OR VKS.VRKbl_KYC_status IS NULL))
        )';

    IF @StateFilter IS NOT NULL AND LTRIM(RTRIM(@StateFilter)) <> ''
        SET @BaseWhere += N' AND MC.[State] = @StateFilter';

    ------------------------------------------------------
    -- Mobile Number Search
    ------------------------------------------------------
    IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> ''
        SET @BaseWhere += N' AND MC.MobileNo LIKE ''%'' + @Search + ''%''';

    ------------------------------------------------------
    -- Data Query
    ------------------------------------------------------
    DECLARE @SQLData NVARCHAR(MAX) = N'
    SELECT
        MC.ConsumerName,
        MC.MobileNo,
        MC.Email,
        MC.[State],
        MC.City,
        CASE 
            WHEN VKS.VRKbl_KYC_status = 1 THEN ''KYC Approved''
            WHEN VKS.VRKbl_KYC_status = 2 THEN ''KYC Rejected''
            ELSE ''KYC Pending''
        END AS KYCStatus,
        MC.Selfie_image,
        VKS.Entry_Date,
        MC.M_Consumerid,
        VKS.kycremark';

    IF @PANCardReq = 'Yes'
        SET @SQLData += N', MC.pancard_number, MC.PanHolderName, MC.pan_card_file AS PanCardImage';

    IF @UPIReq = 'Yes'
        SET @SQLData += N', MC.UPIId, MC.UpiidImage AS UPIIDImage';

    IF @AadharCardReq = 'Yes'
        SET @SQLData += N', MC.aadharNumber, MC.aadharFile AS AadharFront, MC.aadharback AS AadharBack';

    IF @AccountDetails = 'Yes'
        SET @SQLData += N', MB.Account_HolderNm, MB.Account_No, MB.IFSC_Code, MB.Branch, MB.chkPassbook';

    SET @SQLData += N'
    FROM tbl_Vendorvisekycstatus VKS
    INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
    OUTER APPLY (
        SELECT TOP 1 *
        FROM M_BankAccount MB
        WHERE MB.M_Consumerid = MC.M_Consumerid
        ORDER BY MB.Entry_Date DESC
    ) MB
    ' + @BaseWhere + N'
    ORDER BY VKS.Entry_Date DESC';

    IF @IsExport = 0
        SET @SQLData += N' OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY';

    ------------------------------------------------------
    -- Count Query (only for non-export)
    ------------------------------------------------------
    DECLARE @SQLCount NVARCHAR(MAX) = N'';

    IF @IsExport = 0
    BEGIN
        SET @SQLCount = N'
        SELECT
            COUNT(1) AS TotalRecords,
            @Page AS CurrentPage,
            @Limit AS [Limit],
            CEILING(COUNT(1) * 1.0 / @Limit) AS TotalPages
        FROM tbl_Vendorvisekycstatus VKS
        INNER JOIN M_Consumer MC ON MC.M_Consumerid = VKS.M_Consumerid
        ' + @BaseWhere;
    END

    ------------------------------------------------------
    -- Execute
    ------------------------------------------------------
    IF @IsExport = 1
    BEGIN
        EXEC sp_executesql
            @SQLData,
            N'
                @Comp_Id VARCHAR(15),
                @StartDate DATE,
                @EndDate DATE,
                @KYCStatusFilter NVARCHAR(20),
                @StateFilter NVARCHAR(100),
                @Search NVARCHAR(30),
                @Offset INT,
                @Limit INT,
                @Page INT
            ',
            @Comp_Id,
            @StartDate,
            @EndDate,
            @KYCStatusFilter,
            @StateFilter,
            @Search,
            @Offset,
            @Limit,
            @Page;
    END
    ELSE
    BEGIN
        DECLARE @FinalSQL NVARCHAR(MAX);
        SET @FinalSQL = @SQLData + N'; ' + @SQLCount;

        EXEC sp_executesql
            @FinalSQL,
            N'
                @Comp_Id VARCHAR(15),
                @StartDate DATE,
                @EndDate DATE,
                @KYCStatusFilter NVARCHAR(20),
                @StateFilter NVARCHAR(100),
                @Search NVARCHAR(30),
                @Offset INT,
                @Limit INT,
                @Page INT
            ',
            @Comp_Id,
            @StartDate,
            @EndDate,
            @KYCStatusFilter,
            @StateFilter,
            @Search,
            @Offset,
            @Limit,
            @Page;
    END
END
GO
