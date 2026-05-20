USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_CodeCheckHistory_BLAPP_AI]  
    @MobileNo VARCHAR(15),  
    @Comp_ID VARCHAR(100),  
    @M_Consumer_id INT,
    @Year INT = NULL,
    @Month INT = NULL
AS  
BEGIN  
    IF @Comp_ID = 'comp-1152' OR @Comp_ID = 'Comp-1152'
    BEGIN
        SELECT   
            CASE   
                WHEN bl.Is_Success = 1 THEN 'Success'   
                WHEN bl.Is_Success = 0 THEN 'Invalid'   
                WHEN bl.Is_Success = 2 THEN 'Unsuccess'
                ELSE 'Unsuccess'   
            END AS Status,  
            bl.Service_ID,
            FORMAT(bl.Enq_Date, 'dd-MM-yyyy hh:mm:ss tt') AS Enq_Date,  
            'MAHINDRA AND MAHINDRA LTD' AS Comp_Name,  
            Pro_Name AS Pro_Name,  
            CONCAT(bl.Code1, bl.Code2) AS [Code],  
            bl.Code1,  
            bl.Code2,  
            bl.MobileNo,
            @M_Consumer_id AS M_Consumerid,
            CONCAT('+', bl.cash) AS Points,  
            ms.ServiceName,  
            ms.ServiceName AS ServiceNameNew,
            CASE  
                WHEN bl.Is_Success = 1 THEN 'Green'  
                WHEN bl.Is_Success = 0 THEN 'Red'  
                ELSE 'Red'  
            END AS ColourCode  
        FROM [dbo].[ConsumerPointsCashDetails] bl
        LEFT JOIN M_Service ms ON ms.Service_ID = bl.Service_ID
        WHERE bl.MobileNo = @MobileNo
          AND (@Year IS NULL OR YEAR(bl.Enq_Date) = @Year)
          AND (@Month IS NULL OR MONTH(bl.Enq_Date) = @Month)
        ORDER BY bl.Enq_Date DESC;
        RETURN;
    END

    IF @Comp_ID = 'comp-1274' OR @Comp_ID = 'Comp-1274'
    BEGIN
        SELECT   
            CASE   
                WHEN pe.Is_Success = 1 THEN 'Success'   
                WHEN pe.Is_Success = 0 THEN 'Invalid'   
                WHEN pe.Is_Success = 2 THEN 'Unsuccess'
                ELSE 'Unsuccess'   
            END AS Status,  
            ss.Service_ID,
            FORMAT(pe.Enq_Date, 'dd-MM-yyyy hh:mm:ss tt') AS Enq_Date,  
            ISNULL(cr.Comp_Name, 'N/A') AS Comp_Name,  
            ISNULL(pr.Pro_Name, 'N/A') AS Pro_Name,  
            CONCAT(pe.Received_Code1, pe.Received_Code2) AS [Code],  
            pe.Received_Code1 AS Code1,  
            pe.Received_Code2 AS Code2,  
            pe.MobileNo,
            @M_Consumer_id AS M_Consumerid,
            CONCAT('+', CASE WHEN pe.Is_Success = 1 THEN CAST(CAST(ISNULL(sst.IsCash, 0) * 1.10 AS INT) AS VARCHAR(50)) ELSE '0' END) AS Points,  
            s.ServiceName,  
            s.ServiceName AS ServiceNameNew,
            CASE  
                WHEN pe.Is_Success = 1 THEN 'Green'  
                WHEN pe.Is_Success = 0 THEN 'Red'  
                ELSE 'Red'  
            END AS ColourCode  
        FROM Pro_Enq pe
        INNER JOIN M_Code m 
            ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1
            AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2
        INNER JOIN M_ServiceSubscription ss 
            ON m.Pro_id = ss.Pro_id 
            AND ss.IsActive = 1 AND ss.IsDelete = 0
            AND CONCAT(FORMAT(m.Series_Order, '000#'), FORMAT(m.Series_Serial, '000#')) 
                BETWEEN CONCAT(FORMAT(ss.start_order, '000#'), FORMAT(ss.start_series, '000#')) 
                    AND CONCAT(FORMAT(ss.end_order, '000#'), FORMAT(ss.end_series, '000#'))
        INNER JOIN M_ServiceSubscriptionTrans sst 
            ON sst.Subscribe_Id = ss.Subscribe_Id
            AND sst.IsActive = 1 AND sst.IsDelete = 0
        INNER JOIN M_Service s 
            ON ss.Service_ID = s.Service_ID
        LEFT JOIN Pro_Reg pr 
            ON pr.Pro_ID = m.Pro_ID
        LEFT JOIN Comp_Reg cr 
            ON cr.Comp_ID = pr.Comp_ID
        WHERE pe.MobileNo = @MobileNo
          AND pe.Comp_ID = @Comp_ID
          AND (@Year IS NULL OR YEAR(pe.Enq_Date) = @Year)
          AND (@Month IS NULL OR MONTH(pe.Enq_Date) = @Month)
        ORDER BY pe.Enq_Date DESC;
        RETURN;
    END

    ;WITH EnquiryData AS (  
        SELECT   
            CASE   
                WHEN pe.Is_Success = 1 THEN 'Success'   
                WHEN pe.Is_Success = 2 THEN 'Unsuccess'   
                WHEN pe.Is_Success = 0 THEN 'Invalid'
                ELSE 'Invalid'   
            END AS Status,
            '' as Service_ID,
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
    INNER JOIN BLoyaltyPointsEarned bl ON t2.M_Consumerid = bl.M_Consumerid
    INNER JOIN M_ServiceSubscriptionTrans a ON bl.SST_id = a.SST_Id 
    INNER JOIN M_ServiceSubscription b ON a.Subscribe_Id = b.Subscribe_Id 
    INNER JOIN M_Service c ON b.Service_ID = c.Service_ID
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
        'Success' AS Status,
        '' as Service_ID,
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
    INNER JOIN Comp_Reg cr ON cr.Comp_ID = bll.compid  
    WHERE bll.M_Consumerid = @M_Consumer_id   
      AND bll.ServiceName = 'Referral'   
      AND bll.compid = @Comp_ID  
  
    ORDER BY Enq_Date DESC;  
END
GO
