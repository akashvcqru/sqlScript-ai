USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_Counterfeitcodecount_AI]  
(  
@M_Consumerid int,  
@Comp_id varchar(10)
)  
AS  
BEGIN  
    SET NOCOUNT ON;
    SELECT cast(pe.Received_Code1 as int) Received_Code1, cast(pe.Received_Code2 as int) Received_Code2, Is_Success 
    INTO #pro 
    FROM pro_enq pe 
    INNER JOIN m_consumer m on pe.[MobileNo] = m.[MobileNo] 
    WHERE m.M_Consumerid = @M_Consumerid;

    SELECT count(pe.received_code1) as codes  
    FROM #pro pe   
    INNER JOIN M_Code mc on mc.code1 = pe.received_code1 and mc.code2 = pe.received_code2  
    INNER JOIN pro_reg pr on pr.pro_id = mc.pro_id  
    INNER JOIN m_servicesubscription ms on ms.pro_id = pr.pro_id and ms.comp_id = pr.comp_id 
    WHERE ms.Service_ID = 'SRV1018' AND ms.Comp_ID = @Comp_id
    UNION ALL  
    SELECT count(pe.received_code1)  
    FROM #pro pe   
    INNER JOIN M_Code mc on mc.code1 = pe.received_code1 and mc.code2 = pe.received_code2  
    INNER JOIN pro_reg pr on pr.pro_id = mc.pro_id  
    INNER JOIN m_servicesubscription ms on ms.pro_id = pr.pro_id and ms.comp_id = pr.comp_id 
    WHERE ms.Service_ID = 'SRV1018' AND pe.Is_Success = 1 AND ms.Comp_ID = @Comp_id;

    DROP TABLE #pro;
END
