SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_Insert_ConsumerPointsCashDetails]
(
    @CompId NVARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;					   
    DECLARE 
        --@CompId NVARCHAR(50) = 'Comp-1152',
        @Enq_Date DATETIME  ;
	   
    DROP TABLE IF EXISTS #temp1
    DROP TABLE IF EXISTS #temp2
    DROP TABLE IF EXISTS #AKTEST
    DROP TABLE IF EXISTS #Finaljourney_detail2
	   

    ;WITH CTE AS
    (
        SELECT 
            a.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY a.Code1, a.Code2
                ORDER BY a.Entry_Date DESC
            ) AS RN
        FROM m_code_loyalty a
        INNER JOIN Pro_Reg b 
            ON a.Pro_ID = b.Pro_ID
        WHERE b.Comp_ID = @CompId
    )
    SELECT *
    INTO #m_code_loyalty
    FROM CTE
    WHERE RN = 1;


    -- Look back 30 days dynamically to handle late-registered or out-of-order scans
    SELECT     @Enq_Date = DATEADD(DAY, -30, ISNULL(MAX(Enq_Date), '1900-01-01')) FROM ConsumerPointsCashDetails WHERE Comp_id = @CompId;

    ;WITH cte AS
    (
        SELECT  sst.SST_Id, sst.Points,  sst.IsCash,  ss.Pro_ID,  ss.start_order,  ss.start_series, ss.end_order, ss.end_series,  sst.IsActive, ss.Service_ID,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    ss.start_order,  ss.start_series, ss.end_order, ss.end_series, ss.Pro_ID
                ORDER BY 
                    sst.Entry_Date DESC   -- choose latest / priority record
            ) AS rn
        FROM M_ServiceSubscriptionTrans sst
        INNER JOIN M_ServiceSubscription ss ON sst.Subscribe_Id = ss.Subscribe_Id
        INNER JOIN Pro_reg pr ON pr.Pro_id = ss.Pro_ID 
        INNER JOIN Comp_reg cr ON cr.Comp_ID = pr.Comp_ID
        WHERE pr.Comp_ID = @CompId AND (@CompId <> 'Comp-1152' OR ss.Service_ID = 'SRV1005')
    )
    SELECT
        SST_Id, Points, IsCash, Pro_ID, start_order, start_series, end_order, end_series, IsActive, Service_ID
    INTO #temp1
    FROM cte
    WHERE rn = 1;
    
    ; WITH Ranked AS (
        SELECT  PE.Row_ID AS PE_ID, PE.Dial_Mode,mcc.MobileNo,Code1, Code2 ,pe.Enq_Date, mc.Pro_id,mc.Series_Order,Series_Serial,pr.Comp_id,mcc.M_Consumerid,Pro_Name,Longitude,Latitude,mcc.employeeID,mcc.distributorID,
                pe.Is_Success AS pe_Is_Success,
                ROW_NUMBER() OVER
                (
                    PARTITION BY pe.Received_Code1, pe.Received_Code2
                    ORDER BY 
                        CASE WHEN pe.Is_Success = 1 THEN 0 ELSE 1 END,  -- success first
                        pe.Enq_Date ASC                                -- oldest first
                ) AS RowNum
        FROM Pro_Enq pe inner join M_Code mc on mc.Code1 = TRY_CAST(pe.Received_Code1 AS NUMERIC(18,0)) and mc.code2 = TRY_CAST(pe.Received_Code2 AS NUMERIC(18,0)) 
                        inner join Pro_Reg pr on pr.Pro_id = mc.Pro_ID 
                        inner join M_Consumer mcc ON mcc.MobileLast10 = RIGHT(pe.MobileNo, 10)
        WHERE  pr.Comp_ID = @CompId and mcc.IsDelete not in (1) and (pe.Enq_Date>= @Enq_Date or mcc.Entry_Date >= @Enq_Date) and mc.Use_Count is not null
    )
    SELECT * INTO #temp2 FROM Ranked

    ;WITH RankedSST AS
    (
        SELECT 
            r.MobileNo,
            r.Code1,
            r.Code2,
            r.Enq_Date,
            sd.SST_Id,
    
            CASE 
                WHEN r.RowNum = 1 AND r.pe_Is_Success = 1
                THEN COALESCE(q.loyalty, sd.Points, 0) 
                ELSE 0 
            END AS Points,
    
            CASE 
                WHEN r.RowNum = 1 AND r.pe_Is_Success = 1
                THEN COALESCE(q.loyalty, sd.IsCash, 0) 
                ELSE 0 
            END AS IsCash,
    
            r.Pro_id,
            r.Comp_id,
            sd.IsActive,
            r.M_Consumerid,
            sd.Service_ID,
            r.employeeID,
            r.distributorID,
    
            CASE 
                WHEN r.RowNum = 1 AND r.pe_Is_Success = 1 THEN '1'
                ELSE '2'
            END AS Is_Success,
    
            r.PE_ID,
            r.Dial_Mode,
            r.Pro_Name,
            r.Longitude,
            r.Latitude,
    
            ROW_NUMBER() OVER
            (
                PARTITION BY r.Code1, r.Code2, r.PE_ID
                ORDER BY sd.SST_Id DESC   -- pick latest / highest SST
            ) AS rn
    
        FROM #temp2 r
        JOIN #temp1 sd 
            ON sd.Pro_ID = r.Pro_id
           AND (
               sd.start_order IS NULL 
               OR 
               (r.Series_Order * 10000 + r.Series_Serial) BETWEEN (sd.start_order * 10000 + sd.start_series) AND (sd.end_order * 10000 + sd.end_series)
           )
    
        LEFT JOIN #m_code_loyalty q 
            ON r.Code1 = q.code1 
           AND r.Code2 = q.code2
    )
    SELECT *
    INTO #Finaljourney_detail2
    FROM RankedSST
    WHERE rn = 1;
      
    INSERT INTO dbo.ConsumerPointsCashDetails 
    (
        MobileNo,
        M_ConsumerId,
        Code1,
        Code2,
        Enq_Date,
        SST_Id,
        Points,
        Cash,
        expireCodeAmount,
        Pro_id,
        Comp_id,
        Pro_Name,
        Is_Success,
        Service_ID,
        Latitude,
        Longitude,
        Dial_Mode,
        PE_ID,
        employeedid,
        distributedid
    )
    SELECT  
        f.MobileNo,
        f.M_ConsumerId,
        f.Code1,
        f.Code2,
        f.Enq_Date,
        f.SST_Id,
        /* ZERO points after expiry */
        CASE 
            WHEN p.Pro_ID IS NOT NULL 
                 AND f.Enq_Date >= DATEADD(DAY, 1, p.ExpiryDate)
            THEN 0
            ELSE f.Points
        END AS Points,

        /* ZERO cash after expiry */
        CASE 
            WHEN p.Pro_ID IS NOT NULL 
                 AND f.Enq_Date >= DATEADD(DAY, 1, p.ExpiryDate)
            THEN 0
            ELSE f.IsCash
        END AS Cash,
        /* STORE expired amount */
        CASE 
            WHEN p.Pro_ID IS NOT NULL
                 AND f.Enq_Date >= DATEADD(DAY, 1, p.ExpiryDate)
            THEN ISNULL(f.IsCash, 0)
            ELSE 0
        END AS expireCodeAmount,

        f.Pro_id,
        f.Comp_id,
        f.Pro_Name,
        f.Is_Success AS Is_Success,
        f.Service_ID,
        f.Latitude,
        f.Longitude,
        f.Dial_Mode,
        f.PE_ID,
        f.employeeID,
        f.distributorID
    FROM #Finaljourney_detail2 f
    LEFT JOIN Pro_Expiry_Master p
        ON p.Pro_ID = f.Pro_id
       AND p.Comp_Id = f.Comp_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.ConsumerPointsCashDetails c
        WHERE c.PE_ID = f.PE_ID
    );
END;
GO
