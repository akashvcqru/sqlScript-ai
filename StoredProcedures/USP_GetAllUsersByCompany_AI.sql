USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER proc [dbo].[USP_GetAllUsersByCompany_AI]    
@Comp_id nvarchar(100),
@PageNo INT = 1,
@PageSize INT = 10,
@DatePreset NVARCHAR(50) = NULL,
@FromDate NVARCHAR(30) = NULL,
@ToDate NVARCHAR(30) = NULL,
@Search NVARCHAR(200) = NULL,
@MobileNo NVARCHAR(50) = NULL,
@UserType NVARCHAR(100) = NULL,
@PinCode NVARCHAR(20) = NULL,
@Name NVARCHAR(100) = NULL,
@IsExport BIT = 0
as    
begin    
    SET NOCOUNT ON;

    IF @PageNo IS NULL OR @PageNo < 1 SET @PageNo = 1;
    IF @PageSize IS NULL OR @PageSize < 0 SET @PageSize = 10;

    -----------------------------------------
    -- Date Range Calculation
    -----------------------------------------
    DECLARE @StartDate DATETIME = NULL,
            @EndDate   DATETIME = NULL,
            @Preset    NVARCHAR(50);

    SET @Preset = UPPER(ISNULL(@DatePreset, 'ALL'));

    IF (@Preset = 'TODAY')
    BEGIN
        SET @StartDate = CAST(GETDATE() AS DATE);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'TOMORROW')
    BEGIN
        SET @StartDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 2, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'YESTERDAY' OR @Preset = 'LASTDAY')
    BEGIN
        SET @StartDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE));
        SET @EndDate   = CAST(GETDATE() AS DATE);
    END
    ELSE IF (@Preset = 'WEEK' OR @Preset = 'THIS WEEK' OR @Preset = 'THISWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, GETDATE()), CAST(GETDATE() AS DATE));
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTWEEK')
    BEGIN
        SET DATEFIRST 1;
        SET @StartDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'MONTH' OR @Preset = 'THIS MONTH' OR @Preset = 'THISMONTH' OR @Preset = 'MONTHS')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'LASTMONTH')
    BEGIN
        SET @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
        SET @EndDate   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
    END
    ELSE IF (@Preset = 'YEAR' OR @Preset = 'THIS YEAR' OR @Preset = 'THISYEAR')
    BEGIN
        SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
        SET @EndDate   = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
    END
    ELSE IF (@Preset = 'CUSTOM' AND @FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END
    ELSE IF (@FromDate IS NOT NULL AND @FromDate <> '' AND @ToDate IS NOT NULL AND @ToDate <> '')
    BEGIN
        SET @StartDate = CAST(@FromDate AS DATETIME);
        SET @EndDate   = DATEADD(DAY, 1, CAST(@ToDate AS DATE));
    END

    SELECT     
    m.M_consumerId,m.User_ID,ConsumerName,M.MobileNo, v.EmailId as email, v.IsActive,v.usercity as City,v.userstate as state,v.userpin as PinCode,v.Entry_date,v.Vrkabel_User_Type,u.User_Type,v.Outlet_name as OutletName,v.Owner_name as OwnerName,v.Segmanet_name as Segment ,v.Branddetails as Brand  , 
    dcl.total_credit_limit,dcl.current_credit_limit,dsd.deposit_amount,
    m.dob, m.gender, m.gst_number, m.pancard_number, m.pan_card_file, m.FirmName, m.Shop_address, m.aadharNumber, m.aadharFile, m.aadharback, m.employeeID, m.distributorID, m.UPIId, m.sur_name, m.Address, m.Per_Address, m.ReferralCode,
    v.userupi, v.shop_file, v.Dealer_M_consumerid, (SELECT TOP 1 ConsumerName FROM M_Consumer WHERE M_Consumerid = v.Dealer_M_consumerid) AS DealerName, m.Created_by, m.Comp_ID, m.Addedfrom,
    COUNT(1) OVER() AS TotalRecords
    FROM M_consumer M     
    INNER JOIN tbl_Vendorvisekycstatus v on m.M_Consumerid=v.M_consumerId    
    inner join User_Type u on u.Row_ID=v.Vrkabel_User_Type    
    LEFT JOIN( SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY M_Consumerid ORDER BY last_updated_at DESC) AS rn
        FROM dealer_credit_limits
    ) AS t
    WHERE t.rn = 1)
     dcl ON dcl.M_consumerid = m.M_Consumerid
    LEFT JOIN (SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY M_Consumerid ORDER BY last_updated_at DESC) AS rn
        FROM dealer_security_deposits
    ) AS t
    WHERE t.rn = 1) dsd ON dsd.M_consumerid = m.M_Consumerid
    where v.Comp_id=@Comp_id
      AND (@StartDate IS NULL OR v.Entry_date >= @StartDate)
      AND (@EndDate IS NULL OR v.Entry_date < @EndDate)
      AND (
          @Search IS NULL OR LTRIM(RTRIM(@Search)) = '' OR
          M.MobileNo LIKE '%' + @Search + '%' OR
          M.ConsumerName LIKE '%' + @Search + '%' OR
          M.sur_name LIKE '%' + @Search + '%' OR
          v.userpin LIKE '%' + @Search + '%' OR
          u.User_Type LIKE '%' + @Search + '%' OR
          v.Vrkabel_User_Type LIKE '%' + @Search + '%' OR
          M.City LIKE '%' + @Search + '%' OR
          M.state LIKE '%' + @Search + '%'
      )
      AND (@MobileNo IS NULL OR LTRIM(RTRIM(@MobileNo)) = '' OR M.MobileNo LIKE '%' + @MobileNo + '%')
      AND (@UserType IS NULL OR LTRIM(RTRIM(@UserType)) = '' OR u.User_Type LIKE '%' + @UserType + '%' OR v.Vrkabel_User_Type LIKE '%' + @UserType + '%')
      AND (@PinCode IS NULL OR LTRIM(RTRIM(@PinCode)) = '' OR v.userpin LIKE '%' + @PinCode + '%')
      AND (@Name IS NULL OR LTRIM(RTRIM(@Name)) = '' OR M.ConsumerName LIKE '%' + @Name + '%' OR M.sur_name LIKE '%' + @Name + '%')
    ORDER BY v.Entry_date DESC
    OFFSET (@PageNo - 1) * (CASE WHEN @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS
    FETCH NEXT (CASE WHEN @PageSize = 0 OR @IsExport = 1 THEN 1000000 ELSE @PageSize END) ROWS ONLY
end
GO
