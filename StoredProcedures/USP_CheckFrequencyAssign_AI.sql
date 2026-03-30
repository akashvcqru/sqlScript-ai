CREATE PROCEDURE [dbo].[USP_CheckFrequencyAssign_AI]  
@Comp_ID VARCHAR(100),  
@Code1 VARCHAR(5),  
@Code2 VARCHAR(8),  
@Mobileno VARCHAR(50)  
AS  
BEGIN  
    -- Check if the user exists and is associated with the provided company  
    IF EXISTS (  
        SELECT 1  
        FROM M_Consumer mc  
        INNER JOIN User_Type u ON mc.Vrkabel_User_Type = u.Row_ID  
        WHERE mc.Mobileno = @Mobileno AND u.Comp_ID = @Comp_ID  
    )  
    BEGIN  
  
  
 declare @countfreq int;  
  select @countfreq=count (1) from tbl_M_Code_USERFrequency where Code1=@Code1 and Code2=@Code2 and Use_count=0  
  if(@countfreq>1)  
  begin  
  update M_Code set Use_Count=null where Code1=@Code1 and Code2=@Code2  
  end  
  
  
        -- Retrieve the frequency, user type role, and assignment points for the given codes and user type  
        SELECT  
            f.Frequency,  
            f.UserTypeRole,  
            f.AssignPoint,  
            f.Use_count  
        FROM tbl_M_Code_USERFrequency f  
        INNER JOIN M_Code m ON m.Code1 = f.Code1 AND m.Code2 = f.Code2  
        WHERE f.Comp_ID = @Comp_ID  
        AND m.Code1 = @Code1  
        AND m.Code2 = @Code2  
        AND f.Use_count = 0  
        AND f.UserTypeRole = (  
            SELECT u.User_Type  
            FROM M_Consumer mc  
            INNER JOIN User_Type u ON mc.Vrkabel_User_Type = u.Row_ID  
            WHERE mc.Mobileno = @Mobileno AND u.Comp_ID = @Comp_ID  
        );  
  
    END  
END
GO
