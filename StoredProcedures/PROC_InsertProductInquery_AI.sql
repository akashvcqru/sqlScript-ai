/****** Object:  StoredProcedure [dbo].[PROC_InsertProductInquery_AI]    Script Date: 3/2/2026 12:27:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[PROC_InsertProductInquery_AI]  
      @Dial_Mode nvarchar(50)  
  ,@Enq_Date datetime  
  ,@Mode_Detail nvarchar(250)  
  ,@MobileNo nvarchar(20)  
  ,@Received_Code1 nvarchar(50)  
  ,@Received_Code2 nvarchar(50)  
  ,@Is_Success int  
  ,@IsDraw int  
  ,@City varchar(50)=null  
        ,@SST_ID bigint  
  ,@callercircle nvarchar(100) = null  
  ,@network nvarchar(80) = null  
  ,@callerdate datetime = null  
  ,@callertime nvarchar(50) = null  
  ,@M_Codeid bigint =0  
  ,@Proid nvarchar(50) = null  
  ,@Compid nvarchar(50) = null  
  ,@dealerid varchar(50)=null  
  ,@designation nvarchar(100) = null  
  ,@customername varchar(100)=null  
  ,@dealer_mobile varchar(15)=null  
   ,@State varchar(50)=null 
   ,@Retailer_Name varchar(100)=null  
  ,@Others varchar(200)=null 
    ,@Image varchar(max)=null
	,@Latitude varchar(50)=null
  ,@Longitude varchar(50)=null
  ,@IsVerified varchar(10)=null 
  ,@Pincode varchar(10)=null 
AS  
BEGIN  
Declare @M_Consumerid int  
DECLARE @MConsumerMCodeid NUMERIC(18, 0) = 0;
DECLARE @v_ProName NVARCHAR(100), @v_ServiceID NVARCHAR(50), @v_EmpID NVARCHAR(50), @v_DistID NVARCHAR(50);
declare @scp int=null  
declare @frstcnt int  
declare @compid1 nvarchar(50)  

select @compid1=pr.comp_id from  M_Code mc inner join pro_reg pr on pr.Pro_ID=mc.Pro_ID where mc.Code1=@Received_Code1 and mc.Code2=@Received_Code2  
SELECT @M_Consumerid =M_Consumerid FROM [M_Consumer] WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete=0  ORDER BY Entry_Date DESC;  

IF ISNULL(@SST_ID, 0) = 0
BEGIN
    SELECT TOP 1 @SST_ID = sst.SST_Id
    FROM M_ServiceSubscription s (NOLOCK)
    INNER JOIN M_ServiceSubscriptionTrans sst (NOLOCK) ON s.Subscribe_Id = sst.Subscribe_Id
    INNER JOIN M_Code c (NOLOCK) ON s.Pro_ID = c.Pro_ID
    WHERE c.Code1 = TRY_CAST(@Received_Code1 AS NUMERIC(18,0)) AND c.Code2 = TRY_CAST(@Received_Code2 AS NUMERIC(18,0))
      AND c.Series_Order BETWEEN s.start_order AND s.end_order
      AND c.Series_Serial BETWEEN s.start_series AND s.end_series
      AND s.IsActive = 1 AND ISNULL(s.IsDelete, 0) = 0
      AND sst.IsActive = 1 AND ISNULL(sst.IsDelete, 0) = 0
    ORDER BY sst.SST_Id DESC;
END

  --Tej Multivendor kyc
 DECLARE @cntTj INT = 0,  
        @conrid INT = 0,  
        @Vrkabel_User_Type INT = NULL,
		@Vrkabel_KycStatus INT = NULL,
		@Vrkabel_KycStatusMLVrKyc INT = NULL,
		@aadharFrontKyc  varchar(100)=null,
		@aadharBackKyc  varchar(100)=null

-- Get Consumer ID and User Type in a single query
SELECT @conrid = M_Consumerid, @aadharFrontKyc = aadharFile, @aadharBackKyc = aadharback,  @Vrkabel_User_Type = Vrkabel_User_Type FROM m_consumer WHERE RIGHT(MobileNo, 10) = RIGHT(@MobileNo, 10) AND IsDelete=0 ORDER BY Entry_Date DESC;

-- Check if a record exists in tbl_Vendorvisekycstatus
SELECT @cntTj = COUNT(*) FROM tbl_Vendorvisekycstatus WHERE Comp_id = @compid1  AND M_consumerId = @M_Consumerid;  
SELECT top 1  @Vrkabel_KycStatusMLVrKyc = VRKbl_KYC_status FROM tbl_Vendorvisekycstatus WHERE Comp_id in ('Comp-1650','Comp-1567')  AND M_consumerId = @conrid  AND VRKbl_KYC_status in('1','2','0');  

-- If no record exists, insert a new record
IF (LEN(@aadharFrontKyc) > 2 OR LEN(@aadharBackKyc) > 2)
BEGIN
    SET @Vrkabel_KycStatus = 0;
END
IF (@Vrkabel_KycStatusMLVrKyc IS NOT NULL AND (@compid1 = 'Comp-1650' OR @compid1 = 'Comp-1567'))
BEGIN
    SET @Vrkabel_KycStatus = @Vrkabel_KycStatusMLVrKyc;
END

IF (@cntTj = 0 AND @M_Consumerid IS NOT NULL AND LEN(@compid1) > 4)  
BEGIN  
   INSERT INTO tbl_Vendorvisekycstatus (M_consumerId, Comp_id, MobileNo, Vrkabel_User_Type, VRKbl_KYC_status) VALUES (@M_Consumerid, @compid1, @MobileNo, NULL, @Vrkabel_KycStatus);  
END

If (@Dial_Mode = 'IVR'and  (@Compid <> 'Comp-1714' and @Compid <> 'Comp-1728'))  
Begin  
 if (isnull(@M_Codeid,0)>0)  
   Begin  
    if not Exists(select * from M_Consumer_M_Code where M_Consumerid =@M_Consumerid  and M_Codeid =  @M_Codeid)  
    Begin  
    Insert into M_Consumer_M_Code (M_Consumerid,M_Codeid,Pro_id,CreatedDate,Compid)  
    Values (@M_Consumerid,@M_Codeid,@Proid,GetUTCDate(),@Compid)  
  
       Select IDENT_CURRENT('M_Consumer_M_Code') as M_Consumer_M_Code 
	       SET @MConsumerMCodeid = IDENT_CURRENT('M_Consumer_M_Code');
    End  
    Else  
    select M_Consumer_MCodeid as M_Consumer_M_Code from M_Consumer_M_Code where M_Consumerid =@M_Consumerid  and M_Codeid =  @M_Codeid  
   SELECT @MConsumerMCodeid = M_Consumer_MCodeid FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid   AND M_Codeid = @M_Codeid;
   End  
     set @MConsumerMCodeid = @M_Consumerid
  Select 0 as M_Consumer_M_Code  
     Insert into M_ConsumerM_Code_Temp (M_Consumerid,M_Codeid,MConsumerMCodeid,Pro_id,CreatedDate,Compid)  
    Values (@M_Consumerid,@M_Codeid,@MConsumerMCodeid,@Proid,GetUTCDate(),@Compid) 
End  
Else  
Begin  
if @Is_Success = 1   
begin   
declare @cnt int = 0   
select @cnt = count(*) from pro_enq  where Is_Success = 1 and Received_Code1 = @Received_Code1 and Received_Code2 = @Received_Code2  
if (@cnt =  0 OR (@cnt = 1 AND ( @Compid = 'Comp-1669' or @Compid ='Comp-1819') )   )  
begin  
 INSERT INTO [Pro_Enq]([Dial_Mode],[Enq_Date],[Mode_Detail],[MobileNo],  
 [Received_Code1],[Received_Code2],[Is_Success],[IsDraw],[SST_ID],City,Circle,Network,callerdate,callertime,State,Retailer_Name,Others,Image,Latitude,Longitude,Comp_ID,IsVerified)    
 VALUES (@Dial_Mode,@Enq_Date,@Mode_Detail,@MobileNo,@Received_Code1,@Received_Code2,@Is_Success,@IsDraw,@SST_ID,@city,@callercircle,@network,@callerdate,@callertime,@State,N''+ @Retailer_Name +'',N''+ @Others +'',@Image,@Latitude,@Longitude,@Compid,@IsVerified)  
select @scp=SCOPE_IDENTITY()  
if @compid1='Comp-1278'  
begin  
select @frstcnt=COUNT(*) from  user_firstcodecheck where m_consumerid=@M_Consumerid  
if @frstcnt=0   
begin  
insert into user_firstcodecheck(m_consumerid,date_span,createddate) values(@M_Consumerid,@Enq_Date,@Enq_Date)  
end  
end  
if((@customername<>'' or @customername is null) or (@designation<>'' or @designation is null))  
begin  
insert into extra_fields_proenq([code1]  
      ,[code2]  
      ,[name]  
      ,[designation]  
      ,[mobile]  
      ,[is_success]  
      ,[entry_date]) values(@Received_Code1,@Received_Code2,@customername,@designation,@MobileNo,@Is_Success,@Enq_Date)  
end  
if( @dealerid<>'')  
begin  
 insert into enq_dealerid(enq_id,dealerid,dealer_mobile,createddate) values(@scp,@dealerid,@dealer_mobile,@Enq_Date)  
end  
end   

else if (@compid1 = 'Comp-1889')
begin  
 INSERT INTO [Pro_Enq]([Dial_Mode],[Enq_Date],[Mode_Detail],[MobileNo],  
 [Received_Code1],[Received_Code2],[Is_Success],[IsDraw],[SST_ID],City,Circle,Network,callerdate,callertime,State,Retailer_Name,Others,Image,Latitude,Longitude,Comp_ID,IsVerified)    
 VALUES (@Dial_Mode,@Enq_Date,@Mode_Detail,@MobileNo,@Received_Code1,@Received_Code2,@Is_Success,@IsDraw,@SST_ID,@city,@callercircle,@network,@callerdate,@callertime,@State,N''+ @Retailer_Name +'',N''+ @Others +'',@Image,@Latitude,@Longitude,@Compid,@IsVerified)  
select @scp=SCOPE_IDENTITY()  
if @compid1='Comp-1278'  
begin  
select @frstcnt=COUNT(*) from  user_firstcodecheck where m_consumerid=@M_Consumerid  
if @frstcnt=0   
begin  
insert into user_firstcodecheck(m_consumerid,date_span,createddate) values(@M_Consumerid,@Enq_Date,@Enq_Date)  
end  
end  
if((@customername<>'' or @customername is null) or (@designation<>'' or @designation is null))  
begin  
insert into extra_fields_proenq([code1]  
      ,[code2]  
      ,[name]  
      ,[designation]  
      ,[mobile]  
      ,[is_success]  
      ,[entry_date]) values(@Received_Code1,@Received_Code2,@customername,@designation,@MobileNo,@Is_Success,@Enq_Date)  
end  
if( @dealerid<>'')  
begin  
 insert into enq_dealerid(enq_id,dealerid,dealer_mobile,createddate) values(@scp,@dealerid,@dealer_mobile,@Enq_Date)  
end  
end   

 else if (@cnt =  0 OR (@cnt =1 AND (@Compid = 'Comp-1856' OR @Compid = 'Comp-1714' OR @Compid = 'Comp-1728' OR @Compid = 'Comp-1862')))  
begin  
 INSERT INTO [Pro_Enq]([Dial_Mode],[Enq_Date],[Mode_Detail],[MobileNo],  
 [Received_Code1],[Received_Code2],[Is_Success],[IsDraw],[SST_ID],City,Circle,Network,callerdate,callertime,State,Retailer_Name,Others,Image,Latitude,Longitude,Comp_ID,IsVerified)    
 VALUES (@Dial_Mode,@Enq_Date,@Mode_Detail,@MobileNo,@Received_Code1,@Received_Code2,@Is_Success,@IsDraw,@SST_ID,@city,@callercircle,@network,@callerdate,@callertime,@State,N''+ @Retailer_Name +'',N''+ @Others +'',@Image,@Latitude,@Longitude,@Compid,@IsVerified)  
select @scp=SCOPE_IDENTITY()  
if @compid1='Comp-1278'  
begin  
select @frstcnt=COUNT(*) from  user_firstcodecheck where m_consumerid=@M_Consumerid  
if @frstcnt=0   
begin  
insert into user_firstcodecheck(m_consumerid,date_span,createddate) values(@M_Consumerid,@Enq_Date,@Enq_Date)  
end  
end  
if((@customername<>'' or @customername is null) or (@designation<>'' or @designation is null))  
begin  
insert into extra_fields_proenq([code1]  
      ,[code2]  
      ,[name]  
      ,[designation]  
      ,[mobile]  
      ,[is_success]  
      ,[entry_date]) values(@Received_Code1,@Received_Code2,@customername,@designation,@MobileNo,@Is_Success,@Enq_Date)  
end  
if( @dealerid<>'')  
begin  
 insert into enq_dealerid(enq_id,dealerid,dealer_mobile,createddate) values(@scp,@dealerid,@dealer_mobile,@Enq_Date)  
end  
end   

    IF ISNULL(@scp, 0) > 0 AND ISNULL(@M_Codeid, 0) > 0 AND ISNULL(@M_Consumerid, 0) > 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid)
        BEGIN
            INSERT INTO M_Consumer_M_Code (M_Consumerid, M_Codeid, Pro_id, CreatedDate, Compid)
            VALUES (@M_Consumerid, @M_Codeid, @Proid, GETDATE(), @Compid);
            SET @MConsumerMCodeid = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            SELECT @MConsumerMCodeid = M_Consumer_MCodeid FROM M_Consumer_M_Code WHERE M_Consumerid = @M_Consumerid AND M_Codeid = @M_Codeid;
        END
    END
end  
else   
begin    
  
 INSERT INTO [Pro_Enq]([Dial_Mode],[Enq_Date],[Mode_Detail],[MobileNo],  
 [Received_Code1],[Received_Code2],[Is_Success],[IsDraw],[SST_ID],City,Circle,Network,callerdate,callertime,State,Retailer_Name,Others,Image,Latitude,Longitude,Comp_ID,IsVerified)  
  VALUES (@Dial_Mode,@Enq_Date,@Mode_Detail,@MobileNo,@Received_Code1,@Received_Code2,@Is_Success,@IsDraw,@SST_ID,@city,@callercircle,@network,@callerdate,@callertime,@State,N''+@Retailer_Name+'',N''+@Others+'',@Image,@Latitude,@Longitude,@Compid,@IsVerified)   
select @scp=SCOPE_IDENTITY()  
if @compid1='Comp-1278'  
begin  
select @frstcnt=COUNT(*) from  user_firstcodecheck where m_consumerid=@M_Consumerid  
if @frstcnt=0  
begin  
insert into user_firstcodecheck(m_consumerid,date_span,createddate) values(@M_Consumerid,@Enq_Date,@Enq_Date)  
end  
end  
if((@customername<>'' or @customername is null) or (@designation<>'' or @designation is null))  
begin  
insert into extra_fields_proenq([code1]  
      ,[code2]  
      ,[name]  
      ,[designation]  
      ,[mobile]  
      ,[is_success]  
      ,[entry_date]) values(@Received_Code1,@Received_Code2,@customername,@designation,@MobileNo,@Is_Success,@Enq_Date)  
end  
if( @dealerid<>'')  
begin  
 insert into enq_dealerid(enq_id,dealerid,dealer_mobile,createddate) values(@scp,@dealerid,@dealer_mobile,@Enq_Date)  
end  
end   
end
  
IF ISNULL(@scp, 0) > 0 AND UPPER(@Compid) = 'COMP-1152'
BEGIN
    SELECT @v_ProName = Pro_Name FROM Pro_Reg (NOLOCK) WHERE Pro_ID = @Proid;
    SELECT @v_ServiceID = ss.Service_ID FROM M_ServiceSubscription ss (NOLOCK) INNER JOIN M_ServiceSubscriptionTrans sst (NOLOCK) ON ss.Subscribe_Id = sst.Subscribe_Id WHERE sst.SST_Id = @SST_ID;
    SELECT @v_EmpID = employeeID, @v_DistID = distributorID FROM m_consumer (NOLOCK) WHERE M_Consumerid = @M_Consumerid;

    INSERT INTO [dbo].[ConsumerPointsCashDetails]
    (MobileNo, Code1, Code2, Enq_Date, SST_Id, Points, Cash, Pro_id, Comp_id, M_ConsumerId, Is_Success, Pro_Name, Service_ID, Latitude, Longitude, PE_ID, Dial_Mode, employeedid, distributedid, expireCodeAmount)
    VALUES
    (@MobileNo, @Received_Code1, @Received_Code2, @Enq_Date, @SST_ID, 0, 0, @Proid, @Compid, @M_Consumerid, @Is_Success, @v_ProName, @v_ServiceID, @Latitude, @Longitude, @scp, @Dial_Mode, @v_EmpID, @v_DistID, 0);
END
  
SELECT @M_Consumerid =M_Consumerid FROM [M_Consumer] where [MobileNo] = @MobileNo  
IF @Is_Success = 1 AND ISNULL(@MConsumerMCodeid, 0) > 0
    SELECT @MConsumerMCodeid AS Row_ID;
ELSE
    SELECT ISNULL(@scp, 0) AS Row_ID;
END
GO
