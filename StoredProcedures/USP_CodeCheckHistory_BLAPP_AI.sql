USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_CodeCheckHistory_BLAPP_AI]    Script Date: 6/10/2026 6:24:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_CodeCheckHistory_BLAPP_AI]  
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
            CASE 
                WHEN bl.cash IS NOT NULL AND bl.cash <> '' AND bl.cash <> '0' THEN CONCAT('+', bl.cash)
                ELSE '0'
            END AS Points,  
            ms.ServiceName,  
            ms.ServiceName AS ServiceNameNew,
            CASE  
                WHEN bl.Is_Success = 1 THEN 'Green'  
                WHEN bl.Is_Success = 0 THEN 'Red'  
                ELSE 'Red'  
            END AS ColourCode,
            CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
        FROM [dbo].[ConsumerPointsCashDetails] bl
        LEFT JOIN M_Service ms ON ms.Service_ID = bl.Service_ID
        WHERE bl.MobileNo = @MobileNo
          AND (@Year IS NULL OR YEAR(bl.Enq_Date) = @Year)
          AND (@Month IS NULL OR MONTH(bl.Enq_Date) = @Month) and Enq_Date >='2022-08-04 00:00:00.000'
        ORDER BY bl.Enq_Date DESC;
        RETURN;
    END

    IF @Comp_ID = 'comp-1274' OR @Comp_ID = 'Comp-1274'
    BEGIN
        ;WITH ScansWithRn AS (
            SELECT 
                pe.Is_Success,
                pe.Enq_Date,
                pe.Received_Code1,
                pe.Received_Code2,
                pe.MobileNo,
                ROW_NUMBER() OVER (PARTITION BY pe.Received_Code1, pe.Received_Code2, pe.Is_Success ORDER BY pe.Enq_Date) as rn
            FROM Pro_Enq pe WITH (NOLOCK)
            WHERE pe.MobileNo = @MobileNo
              AND (@Year IS NULL OR YEAR(pe.Enq_Date) = @Year)
              AND (@Month IS NULL OR MONTH(pe.Enq_Date) = @Month)
        )
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
            CASE 
                WHEN pe.Is_Success = 1 AND ISNULL(sst.IsCash, 0) <> 0 
                THEN CONCAT('+', CAST(CAST(sst.IsCash * 1.10 AS INT) AS VARCHAR(50))) 
                ELSE '0' 
            END AS Points,  
            s.ServiceName,  
            s.ServiceName AS ServiceNameNew,
            CASE  
                WHEN pe.Is_Success = 1 THEN 'Green'  
                WHEN pe.Is_Success = 0 THEN 'Red'  
                ELSE 'Red'  
            END AS ColourCode,
            CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
        FROM ScansWithRn pe
        INNER JOIN M_Code m WITH (NOLOCK)
            ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1
            AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2
        INNER JOIN M_ServiceSubscription ss WITH (NOLOCK)
            ON m.Pro_id = ss.Pro_id 
            AND ss.IsActive = 1 AND ss.IsDelete = 0
            AND (
                m.Series_Order > ss.start_order 
                OR (m.Series_Order = ss.start_order AND m.Series_Serial >= ss.start_series)
            )
            AND (
                m.Series_Order < ss.end_order 
                OR (m.Series_Order = ss.end_order AND m.Series_Serial <= ss.end_series)
            )
        INNER JOIN M_ServiceSubscriptionTrans sst WITH (NOLOCK)
            ON sst.Subscribe_Id = ss.Subscribe_Id
            AND sst.IsActive = 1 AND sst.IsDelete = 0
        INNER JOIN M_Service s WITH (NOLOCK)
            ON ss.Service_ID = s.Service_ID
        LEFT JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = m.Pro_ID
        LEFT JOIN Comp_Reg cr WITH (NOLOCK)
            ON cr.Comp_ID = pr.Comp_ID
        WHERE pr.Comp_ID = @Comp_ID
          AND (pe.Is_Success != 1 OR pe.rn <= ISNULL(sst.Frequency, 1))
        ORDER BY pe.Enq_Date DESC;
        RETURN;
    END

    -- Get Config Points and Frequency for fallback
    IF OBJECT_ID('tempdb..#ConfigPoints') IS NOT NULL DROP TABLE #ConfigPoints;

    SELECT 
        m.Row_ID AS M_Codeid,
        SS.Service_ID,
        MAX(ISNULL(SST.Frequency, 1)) AS Frequency
    INTO #ConfigPoints
    FROM Pro_Enq pe WITH (NOLOCK)
    INNER JOIN M_Code m WITH (NOLOCK) 
        ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1 
       AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2
    INNER JOIN Pro_Reg pr WITH (NOLOCK) ON pr.Pro_ID = m.Pro_ID
    INNER JOIN M_ServiceSubscription SS WITH (NOLOCK) ON SS.Pro_ID = m.Pro_ID
    INNER JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SST.Subscribe_Id = SS.Subscribe_Id
    WHERE pe.MobileNo = @MobileNo 
      AND pr.Comp_ID = @Comp_ID
      AND SS.IsActive = 1 AND SS.IsDelete = 0
      AND SST.IsActive = 1 AND SST.IsDelete = 0
      AND SS.Service_ID IN ('SRV1001', 'SRV1005', 'SRV1029', 'SRV1023')
      AND (m.Series_Order > SS.start_order OR (m.Series_Order = SS.start_order AND m.Series_Serial >= SS.start_series))
      AND (m.Series_Order < SS.end_order OR (m.Series_Order = SS.end_order AND m.Series_Serial <= SS.end_series))
    GROUP BY m.Row_ID, SS.Service_ID;

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
            pe.Enq_Date AS Sort_Date,
            ISNULL(cr.Comp_Name, 'N/A') AS Comp_Name,  
            ISNULL(pr.Pro_Name, 'N/A') AS Pro_Name,  
            CONCAT(pe.Received_Code1, pe.Received_Code2) AS [Code],  
            TRY_CAST(pe.Received_Code1 AS INT) AS Code1,  
            TRY_CAST(pe.Received_Code2 AS INT) AS Code2,  
            pe.MobileNo,
            m.Row_ID AS M_Codeid,
            ROW_NUMBER() OVER (PARTITION BY pe.Received_Code1, pe.Received_Code2, pe.Is_Success ORDER BY pe.Enq_Date) as rn,
            pe.Is_Success
        FROM Pro_Enq pe WITH (NOLOCK)
        LEFT JOIN M_Code m WITH (NOLOCK)
            ON TRY_CAST(pe.Received_Code1 AS INT) = m.Code1   
            AND TRY_CAST(pe.Received_Code2 AS INT) = m.Code2  
        LEFT JOIN Pro_Reg pr WITH (NOLOCK)
            ON pr.Pro_ID = m.Pro_ID  
        LEFT JOIN Comp_Reg cr WITH (NOLOCK)
            ON cr.Comp_ID = pr.Comp_ID  
        WHERE pe.MobileNo = @MobileNo   
          AND pr.Comp_ID = @Comp_ID  
    )
    SELECT   
        t.*,  
        mc.M_Consumerid   
    INTO #ConsumerData 
    FROM EnquiryData t  
    INNER JOIN M_Consumer mc WITH (NOLOCK) ON mc.MobileNo = t.MobileNo   
    LEFT JOIN (
        SELECT M_Codeid, MAX(Frequency) AS Frequency
        FROM #ConfigPoints
        GROUP BY M_Codeid
    ) CP ON CP.M_Codeid = t.M_Codeid
    WHERE mc.IsDelete = 0  
      AND (t.Is_Success != 1 OR t.rn <= ISNULL(CP.Frequency, 1));  
  
    SELECT   
        t2.Status,  
        t2.Service_ID,  
        t2.Enq_Date,  
        t2.Comp_Name,  
        t2.Pro_Name,  
        t2.Code,  
        t2.Code1,  
        t2.Code2,  
        t2.MobileNo,  
        t2.M_Consumerid,  
        t2.Sort_Date,
        CASE 
            WHEN sst.Points IS NOT NULL AND sst.Points <> 0 THEN CONCAT('+', CAST(sst.Points AS VARCHAR(50)))
            ELSE '0'
        END AS Points,
        c.ServiceName,  
        c.ServiceName AS ServiceNameNew,
        'Green' AS ColourCode,
        CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
    FROM #ConsumerData t2  
    INNER JOIN M_Code m 
        ON t2.Code1 = m.Code1
        AND t2.Code2 = m.Code2
    INNER JOIN M_ServiceSubscription ss 
        ON m.Pro_id = ss.Pro_id 
        AND ss.IsActive = 1 AND ss.IsDelete = 0
        AND (m.Series_Order > ss.start_order OR (m.Series_Order = ss.start_order AND m.Series_Serial >= ss.start_series))
        AND (m.Series_Order < ss.end_order OR (m.Series_Order = ss.end_order AND m.Series_Serial <= ss.end_series))
    INNER JOIN M_ServiceSubscriptionTrans sst 
        ON sst.Subscribe_Id = ss.Subscribe_Id
        AND sst.IsActive = 1 AND sst.IsDelete = 0
    INNER JOIN M_Service c 
        ON ss.Service_ID = c.Service_ID
    WHERE t2.Status = 'Success'  
  
    UNION

	SELECT   
    t2.Status,  
    t2.Service_ID,  
    t2.Enq_Date,  
    t2.Comp_Name,  
    t2.Pro_Name,  
    t2.Code,  
    t2.Code1,  
    t2.Code2,  
    t2.MobileNo,  
    t2.M_Consumerid,  
    t2.Sort_Date,
    '0' AS Points,   
    s.ServiceName AS ServiceName,  
    s.ServiceName AS ServiceNameNew,
    CASE  
        WHEN t2.Status = 'Success' THEN 'Green'  
        WHEN t2.Status = 'Pending' THEN 'Yellow'  
        ELSE 'Red'  
    END AS ColourCode,
    CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
FROM #ConsumerData t2  
INNER JOIN M_Code m 
    ON t2.Code1 = m.Code1
    AND t2.Code2 = m.Code2
INNER JOIN M_ServiceSubscription ss 
    ON m.Pro_id = ss.Pro_id 
    AND ss.IsActive = 1 
    AND ss.IsDelete = 0
INNER JOIN M_Service s 
    ON ss.Service_ID = s.Service_ID
WHERE t2.Status IN ('Invalid', 'Unsuccess')  and s.Service_ID = 'SRV1018'
	 

    UNION  
  
    SELECT   
        t2.Status,  
        t2.Service_ID,  
        t2.Enq_Date,  
        t2.Comp_Name,  
        t2.Pro_Name,  
        t2.Code,  
        t2.Code1,  
        t2.Code2,  
        t2.MobileNo,  
        t2.M_Consumerid,  
        t2.Sort_Date,
        '0' AS Points,   
        'buildloyalty' AS ServiceName,  
        'buildloyalty' AS ServiceNameNew,
        CASE  
            WHEN t2.Status = 'Success' THEN 'Green'  
            WHEN t2.Status = 'Pending' THEN 'Yellow'  
            ELSE 'Red'  
        END AS ColourCode,
        CAST(NULL AS DECIMAL(18,2)) AS InvoiceAmount  
    FROM #ConsumerData t2  
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
        bll.UpdateDate AS Sort_Date,
        CASE 
            WHEN bll.Points IS NOT NULL AND bll.Points <> '' AND bll.Points <> '0' THEN CONCAT('+', bll.Points)
            WHEN bll.cash IS NOT NULL AND bll.cash <> '' AND bll.cash <> '0' THEN CONCAT('+', bll.cash)
            ELSE '0'
        END AS Points,  
        bll.ServiceName,  
        CASE 
            WHEN bll.ServiceName = 'Referral' THEN 'Referral'
            WHEN bll.ServiceName = 'KYCRewards' THEN 'KYC Rewards'
            WHEN bll.ServiceName = 'Supervisor' THEN 'Supervisor'
            WHEN bll.ServiceName = 'InvoiceBenifit' THEN 'Invoice Benefit'
            WHEN bll.ServiceName = 'InvoiceRewards' THEN 'Invoice Rewards'
            WHEN bll.ServiceName = 'Transfer From User' THEN 
                CONCAT('Transfer From User, ', ISNULL(u.ConsumerName, ''), ', ', ISNULL(RIGHT(pth.fromMobileno, 10), ''), ', ', COALESCE(ut_u.User_Type, ut_u2.User_Type, u.Other_Role, ''))
            ELSE bll.ServiceName 
        END AS ServiceNameNew,
        'Green' AS ColourCode,
        CASE 
            WHEN bll.ServiceName = 'InvoiceBenifit' THEN 
                COALESCE(
                    (SELECT TOP 1 invoiceAmount FROM Namrata_RetailerInvoiceData_AI WHERE id = bll.TransacionID),
                    (SELECT TOP 1 invoiceAmount FROM Namrata_RetailerInvoiceData_AI WHERE M_Consumerid = bll.M_Consumerid AND comp_id = bll.compid AND points = bll.Points AND ABS(DATEDIFF(SECOND, createdate, bll.UpdateDate)) <= 5),
                    (SELECT TOP 1 invoiceAmount FROM Namrata_RetailerInvoiceData_AI WHERE M_Consumerid = bll.M_Consumerid AND comp_id = bll.compid AND points = bll.Points ORDER BY createdate DESC)
                )
            WHEN bll.ServiceName = 'InvoiceRewards' THEN 
                COALESCE(
                    (SELECT TOP 1 Amount FROM tblInvoiceData_AI WHERE Id = bll.TransacionID),
                    (SELECT TOP 1 Amount FROM tblInvoiceData_AI WHERE M_Consumerid = bll.M_Consumerid AND Comp_id = bll.compid AND Status = 1 ORDER BY Created_Date DESC)
                )
            ELSE NULL
        END AS InvoiceAmount  
    FROM BLoyaltyPointsEarned bll  
    INNER JOIN Comp_Reg cr ON cr.Comp_ID = bll.compid  
    LEFT JOIN PointsTransferHistory pth WITH (NOLOCK) ON bll.BLoyalty_PointEarnedID = pth.BLoyaltyPointsEarnedId
    LEFT JOIN M_Consumer u WITH (NOLOCK) ON RIGHT(pth.fromMobileno, 10) = RIGHT(u.MobileNo, 10) AND u.IsDelete = 0
    LEFT JOIN tbl_Vendorvisekycstatus vk_u WITH (NOLOCK) ON u.M_Consumerid = vk_u.M_consumerId AND vk_u.Comp_id = bll.compid AND vk_u.IsDelete = 0
    LEFT JOIN User_Type ut_u WITH (NOLOCK) ON CAST(vk_u.Vrkabel_User_Type AS VARCHAR) = CAST(ut_u.Row_ID AS VARCHAR) AND ut_u.Comp_ID = bll.compid
    LEFT JOIN User_Type ut_u2 WITH (NOLOCK) ON CAST(u.Vrkabel_User_Type AS VARCHAR) = CAST(ut_u2.Row_ID AS VARCHAR) AND ut_u2.Comp_ID = bll.compid
    WHERE bll.M_Consumerid = @M_Consumer_id   
      AND bll.ServiceName IN ('Referral', 'KYCRewards', 'Supervisor', 'InvoiceBenifit', 'InvoiceRewards', 'Transfer From User')   
      AND bll.compid = @Comp_ID  
  
    ORDER BY Sort_Date DESC;  
END