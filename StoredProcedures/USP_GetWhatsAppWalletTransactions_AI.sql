/****** Object:  StoredProcedure [dbo].[USP_GetWhatsAppWalletTransactions_AI]    Script Date: 3/2/2026 12:27:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER Procedure [dbo].[USP_GetWhatsAppWalletTransactions_AI]
(
    @Comp_Id varchar(50),
    @datePreset varchar(20) = null,
    @FromDate varchar(20) = null,
    @ToDate varchar(20) = null,
    @Status varchar(20) = null,
    @Type varchar(10) = null,
    @Page int = null,
    @Limit int = null,
    @IsExport bit = null,
    @Search varchar(100) = null
)
as
begin
    set nocount on;

    -- Defaults
    if @Page is null or @Page < 1 set @Page = 1;
    if @Limit is null or @Limit < 1 set @Limit = 10;
    if @IsExport is null set @IsExport = 0;

    declare @Offset int = (@Page - 1) * @Limit;

    -- Date parsing logic similar to other SPs
    declare @StartDate datetime;
    declare @EndDate datetime;

    if (@FromDate is not null and @ToDate is not null and @FromDate <> '' and @ToDate <> '')
    begin
        set @StartDate = cast(@FromDate as datetime);
        set @EndDate = dateadd(day, 1, cast(@ToDate as datetime));
    end
    else if (@datePreset is not null and @datePreset <> '')
    begin
        set @datePreset = UPPER(@datePreset);
        if (@datePreset = 'TODAY')
        begin
            set @StartDate = cast(getdate() as date);
            set @EndDate = dateadd(day, 1, cast(getdate() as date));
        end
        else if (@datePreset = 'LASTDAY')
        begin
            set @StartDate = dateadd(day, -1, cast(getdate() as date));
            set @EndDate = cast(getdate() as date);
        end
        else if (@datePreset = 'WEEK')
        begin
            set datefirst 1;
            set @StartDate = dateadd(day, 1 - datepart(weekday, getdate()), cast(getdate() as date));
            set @EndDate = dateadd(day, 1, cast(getdate() as date));
        end
        else if (@datePreset = 'LASTWEEK')
        begin
            set datefirst 1;
            set @StartDate = dateadd(week, datediff(week, 0, getdate()) - 1, 0);
            set @EndDate = dateadd(week, datediff(week, 0, getdate()), 0);
        end
        else if (@datePreset = 'MONTH')
        begin
            set @StartDate = datefromparts(year(getdate()), month(getdate()), 1);
            set @EndDate = dateadd(day, 1, cast(getdate() as date));
        end
        else if (@datePreset = 'LASTMONTH')
        begin
            set @StartDate = dateadd(month, datediff(month, 0, getdate()) - 1, 0);
            set @EndDate = dateadd(month, datediff(month, 0, getdate()), 0);
        end
        else if (@datePreset = 'QUARTER')
        begin
            set @StartDate = dateadd(quarter, datediff(quarter, 0, getdate()) - 1, 0);
            set @EndDate = dateadd(quarter, datediff(quarter, 0, getdate()), 0);
        end
        else if (@datePreset = 'YEAR')
        begin
            set @StartDate = datefromparts(year(getdate()), 1, 1);
            set @EndDate = dateadd(day, 1, cast(getdate() as date));
        end
        else if (@datePreset = 'LASTYEAR')
        begin
            set @StartDate = datefromparts(year(getdate()) - 1, 1, 1);
            set @EndDate = datefromparts(year(getdate()), 1, 1);
        end
    end

    if (@IsExport = 1)
    begin
        select 
            Id, 
            Comp_Id, 
            OldBal, 
            NewBal, 
            Amount, 
            Cr_Dr_Type as CrDrType, 
            ReqDate as TransactionDate, 
            Remarks, 
            PaymentGatewayTxnId, 
            Status
        from tblWhatsAppWalletBalance
        where Comp_Id = @Comp_Id
          and (@StartDate is null or ReqDate >= @StartDate)
          and (@EndDate is null or ReqDate < @EndDate)
          and (@Status is null or @Status = '' or Status = @Status)
          and (@Type is null or @Type = '' or Cr_Dr_Type = @Type)
          and (
              @Search is null or @Search = ''
              or Remarks like '%' + @Search + '%'
              or PaymentGatewayTxnId like '%' + @Search + '%'
              or Status like '%' + @Search + '%'
              or Cr_Dr_Type like '%' + @Search + '%'
          )
        order by Id desc;
    end
    else
    begin
        select 
            Id, 
            Comp_Id, 
            OldBal, 
            NewBal, 
            Amount, 
            Cr_Dr_Type as CrDrType, 
            ReqDate as TransactionDate, 
            Remarks, 
            PaymentGatewayTxnId, 
            Status
        from tblWhatsAppWalletBalance
        where Comp_Id = @Comp_Id
          and (@StartDate is null or ReqDate >= @StartDate)
          and (@EndDate is null or ReqDate < @EndDate)
          and (@Status is null or @Status = '' or Status = @Status)
          and (@Type is null or @Type = '' or Cr_Dr_Type = @Type)
          and (
              @Search is null or @Search = ''
              or Remarks like '%' + @Search + '%'
              or PaymentGatewayTxnId like '%' + @Search + '%'
              or Status like '%' + @Search + '%'
              or Cr_Dr_Type like '%' + @Search + '%'
          )
        order by Id desc
        offset @Offset rows fetch next @Limit rows only;

        select 
            count(1) as TotalRecords,
            @Page as CurrentPage,
            @Limit as Limit,
            ceiling(count(1) * 1.0 / @Limit) as TotalPages
        from tblWhatsAppWalletBalance
        where Comp_Id = @Comp_Id
          and (@StartDate is null or ReqDate >= @StartDate)
          and (@EndDate is null or ReqDate < @EndDate)
          and (@Status is null or @Status = '' or Status = @Status)
          and (@Type is null or @Type = '' or Cr_Dr_Type = @Type)
          and (
              @Search is null or @Search = ''
              or Remarks like '%' + @Search + '%'
              or PaymentGatewayTxnId like '%' + @Search + '%'
              or Status like '%' + @Search + '%'
              or Cr_Dr_Type like '%' + @Search + '%'
          );
    end
end
GO
