USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[PROC_AddBrandWisePoints_AI]    Script Date: 7/13/2026 12:19:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[PROC_AddBrandWisePoints_AI]
		 @Received_Code1 nvarchar(50)
		,@Received_Code2 nvarchar(50)
		,@MobileNo nvarchar(50)
    
AS
BEGIN

     DECLARE 
        @Brand_Code VARCHAR(50),
        @Pro_ID     VARCHAR(50),
        @Points     NUMERIC,
        @Use_Count     INT,
        @Comp_ID    VARCHAR(50);

    -- Get Brand & Company
    SELECT 
	    --@Use_Count = Use_Count,
        @Brand_Code = pr.Brand_Code,
        @Pro_ID     = pr.Pro_ID,
        @Comp_ID    = pr.Comp_ID
    FROM M_Code mc
    INNER JOIN pro_reg pr ON pr.Pro_ID = mc.Pro_ID
    WHERE mc.Code1 = @Received_Code1
      AND mc.Code2 = @Received_Code2;


	  select @Use_Count= Is_Success from Pro_enq where Received_Code1 = @Received_Code1 and Received_Code2 = @Received_Code2 and  MobileNo = @MobileNo

   IF (@Comp_ID = 'Comp-2124' and @Use_Count = '1')
    BEGIN
                           drop table if exists #temp1
						   
						   SELECT sst.SST_Id,sst.Points,sst.IsCash, ss.Pro_ID, ss.start_order, ss.start_series, ss.end_order, ss.end_series,sst.IsActive,ss.Service_ID
                           into #temp1 FROM M_ServiceSubscriptionTrans sst
                           INNER JOIN M_ServiceSubscription ss ON sst.Subscribe_Id = ss.Subscribe_Id
                           Inner join Pro_reg pr on pr.Pro_id = ss.Pro_ID 
			               inner join Comp_reg cr on cr.Comp_ID = pr.Comp_ID  where pr.Comp_ID = @Comp_ID--'Comp-1727'--@CompId


                           select @Points = sd.Points from  M_Code r join #temp1 sd 
                                  ON sd.Pro_ID = r.Pro_id
								 AND CONCAT(FORMAT(Series_Order, '000#'), FORMAT(Series_Serial, '000#')) 
                                     BETWEEN CONCAT(FORMAT(start_order, '000#'), FORMAT(start_series, '000#')) 
                                         AND CONCAT(FORMAT(end_order, '000#'), FORMAT(end_series, '000#')) where code1 = @Received_Code1 and Code2 = @Received_Code2
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.M_ProductBrandPoints
                WHERE Brand_Code = @Brand_Code
                  AND MobileNo   = @MobileNo
            )
            BEGIN
                INSERT INTO dbo.M_ProductBrandPoints
                (
                    Comp_ID,
                    Pro_ID,
                    Brand_Code,
                    Code1,
                    Code2,
                    Points,
                    Created_By,
                    MobileNo
                )
                VALUES
                (
                    @Comp_ID,
                    @Pro_ID,
                    @Brand_Code,
                    @Received_Code1,
                    @Received_Code2,
                    @Points,
                    'PROC_UpdateM_CodeUse_Count',
                    @MobileNo
                );
            END
            ELSE
            BEGIN
                UPDATE dbo.M_ProductBrandPoints
                SET Points = ISNULL(Points, 0) + ISNULL(@Points, 0)
                WHERE Brand_Code = @Brand_Code
                  AND MobileNo   = @MobileNo;
            END
            
    END

END