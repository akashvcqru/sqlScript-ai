/****** Object:  StoredProcedure [dbo].[Proc_GetServicesAssignAgainstProduct_AI]    Script Date: 3/2/2026 12:27:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Proc_GetServicesAssignAgainstProduct_AI]
(
	 @Pro_id nvarchar(50)='',
	 @Code1 nvarchar(5),
	 @Code2 nvarchar(8)
)
as
begin
	declare @seriesorder int,@seriesserial int,@cnt int,@cdcode1 int=convert(int,@Code1),@cdcode2 int=convert(int,@Code2)
	select @Pro_id=Pro_ID,@seriesorder=series_order,@seriesserial=Series_Serial from M_Code(nolock) where Code1 = @cdcode1 and Code2 = @cdcode2
	
	select * into #blankseries from M_ServiceSubscription where start_order is null

	create table #fillseries(Subscribe_Id nvarchar(100),Service_ID nvarchar(100),Comp_ID nvarchar(100), Pro_ID nvarchar(100),IsActive int,start_order int,start_series int,end_order int,end_series int )
	
	if(@Pro_id = 'AJ45' or @Pro_id = 'AJ46' or @Pro_id = 'AJ47' or @Pro_id = 'AJ48' or @Pro_id = 'AJ49' or @Pro_id = 'AJ50')
	BEGIN 
		insert into #fillseries select Subscribe_Id,Service_ID,Comp_ID,Pro_ID,IsActive,start_order,start_series,end_order,end_series  from M_ServiceSubscription where IsActive = 1 
	END 
	ELSE 
	BEGIN 
		insert into #fillseries select Subscribe_Id,Service_ID,Comp_ID,Pro_ID,IsActive,start_order,start_series,end_order,end_series  from M_ServiceSubscription where start_order is not null
	END 

	select @Pro_id=Pro_ID,@seriesorder=series_order,@seriesserial=Series_Serial from M_Code(nolock) where Code1 = @cdcode1 and Code2 = @cdcode2
	
	select @cnt=count(service_id) from #fillseries where 
	concat(format(@seriesorder,'000#'),format(@seriesserial,'000#')) between concat(format(start_order,'000#'),format([start_series],'000#')) and concat(format(end_order,'000#'),format([end_series],'000#')) and Pro_ID=@Pro_id
	
	if(@cnt=0)
	begin
		select 
			(select Pro_name from Pro_Reg where Pro_ID = ss.Pro_ID) as PNm,
			sst.*,ss.Service_ID,ss.Comp_ID,ss.Pro_ID,MSR.* from M_ServiceSubscriptionTrans sst 
			inner join #blankseries ss on (sst.Subscribe_Id= ss.Subscribe_Id   and isnull(ss.isActive,0) = 1)
			left outer join M_ServiceRules MSR on sst.SST_Id = MSR.SST_Id 
			where ss.Pro_ID =@pro_id 			
			and isnull(sst.IsActive,0) =1 and isnull(sst.IsDelete,0) = 0 
		select 0
	end
	else
	begin
		select 
			(select Pro_name from Pro_Reg where Pro_ID = ss.Pro_ID) as PNm,
			sst.*,ss.Service_ID,ss.Comp_ID,ss.Pro_ID,MSR.*from M_ServiceSubscriptionTrans sst 
			inner join #fillseries ss on (sst.Subscribe_Id= ss.Subscribe_Id   and isnull(ss.isActive,0) = 1)
			left outer join M_ServiceRules MSR on sst.SST_Id = MSR.SST_Id 
			where ss.Pro_ID = @pro_id 			
			and isnull(sst.IsActive,0) =1 and isnull(sst.IsDelete,0) = 0 
			and concat(format(@seriesorder,'000#'),format(@seriesserial,'000#')) between concat(format(ss.start_order,'000#'),format(ss.[start_series],'000#')) and concat(format(ss.end_order,'000#'),format(ss.[end_series],'000#'))
		select 0
	end
end
GO
