USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_FillTempUPIPayoutReport_AllCompanies]    Script Date: 9/7/2026 4:05:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[USP_FillTempUPIPayoutReport_AllCompanies]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Companies TABLE
    (
        ID INT IDENTITY(1,1),
        Comp_ID VARCHAR(20)
    );

    INSERT INTO @Companies (Comp_ID)
    VALUES
    ('Comp-1726'),
    ('Comp-1823'),
    ('Comp-1863'),
    ('Comp-1727'),
    ('Comp-1466'),
    ('Comp-1896'),
    ('Comp-1750'),
    ('Comp-1684'),
    ('Comp-1702');

    DECLARE
        @i INT = 1,
        @MaxID INT,
        @CompanyName NVARCHAR(200),
        @Comp_ID VARCHAR(20),
        @FromDate DATETIME,
        @ToDate DATETIME;

    SET @MaxID = (SELECT MAX(ID) FROM @Companies);
    SET @ToDate = DATEADD(HOUR,10,CAST(CAST(GETDATE() AS DATE) AS DATETIME));

    WHILE @i <= @MaxID
    BEGIN
        SET @CompanyName = NULL;
        SET @Comp_ID = NULL;
        SET @FromDate = NULL;

        SELECT @Comp_ID = Comp_ID
        FROM @Companies
        WHERE ID = @i;

        SELECT @CompanyName = Comp_Name
        FROM Comp_Reg
        WHERE Comp_ID = @Comp_ID;

        IF @Comp_ID IS NOT NULL AND @CompanyName IS NOT NULL
        BEGIN
            BEGIN TRY
                -- Last imported date
                SELECT @FromDate = MAX(ReqDate)
                FROM TempUPIPayoutReport
                WHERE Comp_ID = @Comp_ID;

                -- First run
                IF @FromDate IS NULL
                BEGIN
                    SELECT @FromDate = Reg_Date
                    FROM Comp_Reg
                    WHERE Comp_ID = @Comp_ID;
                END
                ELSE
                BEGIN
                    SET @FromDate = DATEADD(SECOND,1,@FromDate);
                END

                PRINT 'Processing : ' + @CompanyName;
                PRINT 'Comp_ID     : ' + @Comp_ID;
                PRINT 'FromDate    : ' + CONVERT(VARCHAR(19),@FromDate,120);

                INSERT INTO dbo.TempUPIPayoutReport
                (
                    tblUPITransactionDetailsID,
                    Comp_ID,
                    Comp_Name,
                    ConsumerName,
                    MobileNo,
                    Code1,
                    Code2,
                    UPI_Id,
                    OldBal,
                    Amount,
                    FinalPayment,
                    tdsAmount,
                    tdsper,
                    ChargedAmount,
                    GstAmount,
                    NewBal,
                    OrderId,
                    BankStatus,
                    BankRemark,
                    ReqDate,
                    FinalStatus,
                    FinalRemark
                )
                EXEC dbo.GetUPIpayoutRportBL_AI_FillData
                    @Compid       = @Comp_ID,
                    @FromDate     = @FromDate,
                    @ToDate       = @ToDate,
                    @datePreset   = NULL,
                    @StatusFilter = NULL,
                    @MobileNo     = NULL,
                    @IsExport     = 1;

                DECLARE @InsertedCount INT = @@ROWCOUNT;

                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        PayoutReportCount = @InsertedCount,
                        PayoutFromDate = @FromDate,
                        PayoutToDate = @ToDate,
                        Status = 'Success',
                        ErrorMessage = NULL,
                        SyncDateTime = GETDATE()
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE);
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.TempDataSyncLog
                    (
                        Comp_ID,
                        Comp_Name,
                        PayoutReportCount,
                        PayoutFromDate,
                        PayoutToDate,
                        Status
                    )
                    VALUES
                    (
                        @Comp_ID,
                        @CompanyName,
                        @InsertedCount,
                        @FromDate,
                        @ToDate,
                        'Success'
                    );
                END
            END TRY
            BEGIN CATCH
                DECLARE @ErrorMsg NVARCHAR(1000) = ERROR_MESSAGE();
                PRINT 'Error Processing : ' + @CompanyName + ' - ' + @ErrorMsg;

                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        PayoutReportCount = 0,
                        PayoutFromDate = @FromDate,
                        PayoutToDate = @ToDate,
                        Status = 'Failed',
                        ErrorMessage = LEFT(@ErrorMsg, 1000),
                        SyncDateTime = GETDATE()
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE);
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.TempDataSyncLog
                    (
                        Comp_ID,
                        Comp_Name,
                        PayoutReportCount,
                        PayoutFromDate,
                        PayoutToDate,
                        Status,
                        ErrorMessage
                    )
                    VALUES
                    (
                        @Comp_ID,
                        @CompanyName,
                        0,
                        @FromDate,
                        @ToDate,
                        'Failed',
                        LEFT(@ErrorMsg, 1000)
                    );
                END
            END CATCH
        END
        ELSE
        BEGIN
            PRINT 'Company Not Found : ' + @CompanyName;
        END

        SET @i = @i + 1;
    END


	UPDATE a
      SET a.BankStatus = 'Success'
      FROM TempUPIPayoutReport a
      INNER JOIN tblUPITransactionDetails b
          ON a.tblUPITransactionDetailsID = b.Id
      WHERE b.Status = 'Success'
        AND ISNULL(a.BankStatus, '') <> 'Success' AND a.ReqDate >= DATEADD(DAY, -2, GETDATE()) ;

END
