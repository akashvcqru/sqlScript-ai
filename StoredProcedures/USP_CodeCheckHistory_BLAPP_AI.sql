USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_CodeCheckHistory_BLAPP_AI]    Script Date: 4/29/2026 10:15:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_CodeCheckHistory_BLAPP_AI]  
    @MobileNo VARCHAR(15),  
    @Comp_ID VARCHAR(100),  
    @M_Consumer_id INT  
AS  
BEGIN  
    WITH EnquiryData AS (  
        SELECT   
            CASE   
                WHEN pe.Is_Success = 1 THEN 'Success'   
                WHEN pe.Is_Success = 2 THEN 'Unsuccess'   
                WHEN pe.Is_Success = 0 THEN 'Invalid'
                ELSE 'Invalid'   
            END AS Status,  '' as Service_ID,
            FORMAT(pe.Enq_Date, 'dd-MM-yyyy hh:mm:ss tt') AS Enq_Date,  
            ISNULL(cr.Comp_Name, 'N/A') AS Comp_Name,  
            ISNULL(pr.Pro_Name, 'N/A') AS Pro_Name,  
            CONCAT(pe.Received_Code1, pe.Received_Code2) AS [Code],  
            TRY_CAST(pe.Received_Code1 AS INT) AS Code1,  
            TRY_CAST(pe.Received_Code2 AS INT) AS Code2,  
            pe.MobileNo  
        FROM Pro_Enq pe  
        LEFT JOIN M_Code m   
            ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1   
            AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2  
        LEFT JOIN Pro_Reg pr   
            ON pr.Pro_ID = m.Pro_ID  
        LEFT JOIN Comp_Reg cr   
            ON cr.Comp_ID = pr.Comp_ID  
        WHERE pe.MobileNo = @MobileNo   
          AND pe.Comp_ID = @Comp_ID  
    ),  
    ConsumerData AS (  
        SELECT   
            t.*,  
            mc.M_Consumerid   
        FROM EnquiryData t  
        INNER JOIN M_Consumer mc   
            ON mc.MobileNo = t.MobileNo   
        WHERE mc.IsDelete = 0  
    )  
  
    SELECT   
        t2.*,  
        CONCAT('+', bl.Points) AS Points,  
        bl.ServiceName,  
        c.ServiceName AS ServiceNameNew,
        CASE  
            WHEN t2.Status = 'Success' THEN 'Green'  
            WHEN t2.Status = 'Pending' THEN 'Yellow'  
            ELSE 'Red'  
        END AS ColourCode  
    FROM ConsumerData t2  
    INNER JOIN BLoyaltyPointsEarned bl  
	inner join M_ServiceSubscriptionTrans a on bl.SST_id = a.SST_Id 
	inner join M_ServiceSubscription b on a.Subscribe_Id = b.Subscribe_Id 
	inner join M_Service c on b.Service_ID = c.Service_ID
        ON t2.M_Consumerid = bl.M_Consumerid  
    WHERE t2.Status = 'Success'  
      AND t2.Code1 = bl.Code1   
      AND t2.Code2 = bl.Code2  
  
    UNION  
  
    SELECT   
        t2.*,   
        CONCAT('+', 0) AS Points,   
        'buildloyalty' AS ServiceName,  
        'buildloyalty' AS ServiceNameNew,
        CASE  
            WHEN t2.Status = 'Success' THEN 'Green'  
            WHEN t2.Status = 'Pending' THEN 'Yellow'  
            ELSE 'Red'  
        END AS ColourCode  
    FROM ConsumerData t2  
    WHERE t2.Status IN ('Invalid', 'Unsuccess')  
  
    UNION  
  
    SELECT   
        'Success' AS Status,  '' as Service_ID,
        FORMAT(bll.UpdateDate, 'dd-MM-yyyy hh:mm:ss tt') AS Enq_Date,  
        cr.Comp_Name,  
        '' AS Pro_Name,  
        '' AS Code,  
        '' AS Code1,  
        '' AS Code2,  
        @MobileNo AS MobileNo,  
        @M_Consumer_id AS M_Consumerid,  
        CONCAT('+', bll.Points) AS Points,  
        bll.ServiceName,  
        bll.ServiceName AS ServiceNameNew,
        'Green' AS ColourCode  
    FROM BLoyaltyPointsEarned bll  
    INNER JOIN Comp_Reg cr   
        ON cr.Comp_ID = bll.compid  
    WHERE bll.M_Consumerid = @M_Consumer_id   
      AND bll.ServiceName = 'Referral'   
      AND bll.compid = @Comp_ID  
  
    ORDER BY Enq_Date DESC;  
END
