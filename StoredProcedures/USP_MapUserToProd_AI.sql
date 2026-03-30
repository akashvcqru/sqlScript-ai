/****** Object:  StoredProcedure [dbo].[USP_MapUserToProd_AI]    Script Date: 3/2/2026 12:27:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_MapUserToProd_AI]  
    @code1 NVARCHAR(20),  
    @code2 NVARCHAR(20),  
    @Mobileno NVARCHAR(13)  
AS  
BEGIN  
Declare  @ProId varchar(10)= '',
         @Comp_id varchar(10)= null,
         @Count1 INT= 0,
         @Count2 INT= 0,
         @UserType varchar(10)= null,
         @ProductMapped varchar(1000)= null,
		 @UserType2 int;

        select @ProId = Pro_ID from M_code where CAST(code1 AS NVARCHAR(50))= @code1 and CAST(code2 AS NVARCHAR(50)) = @code2
		select @Comp_id = comp_id from Pro_Reg where Pro_ID = @ProId

		 SELECT @UserType2 = 
             CASE 
                 WHEN vk.Vrkabel_User_Type IS NULL OR vk.Vrkabel_User_Type = 0 
                 THEN mc.Vrkabel_User_Type 
                 ELSE vk.Vrkabel_User_Type 
             END
         FROM M_Consumer  mc
         left JOIN tbl_Vendorvisekycstatus  vk ON mc.M_Consumerid = vk.M_consumerid where mc.MobileNo = @Mobileno;
         
		 select @ProductMapped = ProductMapped from User_Type where Row_ID = @UserType2

		 select @Count1 = count(Row_id) from  User_Type where  Comp_id = @Comp_id
		 SELECT @Count2 = count(Row_id) FROM User_Type  WHERE Comp_id = @Comp_id
		 AND (ProductMapped IS  NULL OR LTRIM(RTRIM(ProductMapped)) = '')

		IF (@Count1 = @Count2)
        BEGIN
            SELECT 'OK' AS Msg;
            RETURN;
        END

		IF @ProductMapped IS NULL
        BEGIN
            SELECT 'User Type is not mapped to this product' AS Msg;
            RETURN;
        END

		IF EXISTS (
            SELECT 1 
            WHERE ',' + @ProductMapped + ',' LIKE '%,' + @ProId + ',%'
        )
        BEGIN
            SELECT 'OK' AS Msg;  
            RETURN;
        END
        ELSE
        BEGIN
            SELECT 'User Type is not mapped to this product' AS Msg;
            RETURN;
        END
END
GO
