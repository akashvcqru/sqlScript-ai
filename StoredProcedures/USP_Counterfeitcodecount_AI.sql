SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[USP_Counterfeitcodecount_AI]
(
@M_consumerid int,
@comp_id varchar(10)=null
)
AS
BEGIN
    -- Counterfeit count
    SELECT COUNT(pe.[Received_Code1]) 
    FROM M_Consumer as mc                                 
    INNER JOIN Pro_Enq pe ON pe.MobileNo = mc.MobileNo                                
    INNER JOIN M_code ON CAST(M_Code.Code1 as nvarchar(5)) = pe.Received_Code1 AND CAST(M_Code.Code2 as nvarchar(8)) = pe.Received_Code2                                
    INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID                                
    INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID                                
    WHERE Comp_Reg.Comp_ID = @comp_id AND [M_Consumerid] = @M_consumerid AND Is_Success = 0

    UNION ALL

    -- Success/Authentic count
    SELECT COUNT(pe.[Received_Code1]) 
    FROM M_Consumer as mc                                 
    INNER JOIN Pro_Enq pe ON pe.MobileNo = mc.MobileNo                                
    INNER JOIN M_code ON CAST(M_Code.Code1 as nvarchar(5)) = pe.Received_Code1 AND CAST(M_Code.Code2 as nvarchar(8)) = pe.Received_Code2                                
    INNER JOIN Pro_Reg ON Pro_Reg.Pro_ID = M_Code.Pro_ID                                
    INNER JOIN Comp_Reg ON Comp_Reg.Comp_ID = Pro_Reg.Comp_ID                                
    WHERE Comp_Reg.Comp_ID = @comp_id AND [M_Consumerid] = @M_consumerid AND Is_Success = 1
end
GO
