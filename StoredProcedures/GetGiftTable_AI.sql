SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[GetGiftTable_AI]          
(          
    @companyid varchar(20)          
)          
as          
begin          
    SET NOCOUNT ON;

    -- Fetch base gift data into temp table
    select 
        a.gift_id,
        a.Gift_name, 
        a.Gift_value,
        a.Gift_point,
        a.UserType,
        a.Gift_desc,
        a.Gift_image,
        a.IsServiceWise,
        aa.ServiceName as ServiceName,
        a.status,
        a.CompID, 
        a.IsCashConvertible,
        a.CashType,
        CASE 
            WHEN b.gift_images IS NULL OR b.gift_images = '' THEN ''
            WHEN b.gift_images LIKE '%,' THEN LEFT(b.gift_images, LEN(b.gift_images) - 1)
            ELSE b.gift_images 
        END AS gift_images,
        a.Brand_Code,
        a.Service_id
    into #temp    
    from Claim_gift AS a 
    LEFT JOIN gifttable_images AS b ON a.gift_id = b.gift_id     
    left join M_Service aa on aa.Service_ID = a.Service_id
    where a.CompID = @companyid  
      AND (a.IsDelete IS NULL OR a.IsDelete = 0)
    order by a.gift_id desc;
        
    -- Final select with brand and user type names
    select t.*, b.Brand_Name, ut.User_Type as UserTypeName
    from #temp t    
    left join tbl_MasterBrand b on t.Brand_Code = b.Brand_Code AND b.Comp_id = @companyid AND b.IsDelete = 0
    left join User_type ut on ut.Row_ID = t.UserType AND ut.Comp_ID = @companyid AND ut.IsDeleted = 0
        
    drop table #temp    
end 
GO
