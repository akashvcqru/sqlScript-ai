USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_FillTempCodesActivityReport_AllCompanies]    Script Date: 7/22/2026 2:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[USP_FillTempCodesActivityReport_AllCompanies]
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
                -- Last imported date for this company
                SELECT @FromDate = MAX(Enq_Date)
                FROM TempCodesActivityReport
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

                INSERT INTO TempCodesActivityReport
                (
                    Comp_ID,
                    Comp_Name,
                    UniqueCode,
                    Enq_Date,
                    Dial_Mode,
                    ConsumerName,
                    MobileNo,
                    State,
                    City,
                    Pro_Name,
                    Points,
                    Result,
                    Latitude,
                    Longitude,
                    AssignPoint,
                    WornPoint,
                    ReferralPoints,
                    PE_ID
                )
                EXEC dbo.SP_BL_GetCodesActivityReport_AI_FillData
                    @Comp_Id    = @Comp_ID,
                    @datePreset = NULL,
                    @FromDate   = @FromDate,
                    @ToDate     = @ToDate,
                    @IsExport   = 1;

                DECLARE @InsertedCount INT = @@ROWCOUNT;

                INSERT INTO dbo.TempCodesActivityReport
                (
                    Comp_ID,
                    Comp_Name,
                    UniqueCode,
                    Enq_Date,
                    Dial_Mode,
                    ConsumerName,
                    MobileNo,
                    State,
                    City,
                    Pro_Name,
                    Points,
                    Result,
                    Latitude,
                    Longitude,
                    AssignPoint,
                    WornPoint,
                    ReferralPoints,
                    PE_ID
                )
                SELECT
                    b.compid,
                    cr.Comp_Name,
                    b.Code1,
                    b.UpdateDate,
                    b.ServiceName,
                    mc.ConsumerName,
                    mc.MobileNo,
                    mc.State,
                    mc.City,
                    b.ServiceName,
                    ISNULL(b.Points,0),
                    'Success',
                    NULL,
                    NULL,
                    ISNULL(b.Points,0),
                    ISNULL(b.Points,0),
                    0,
                    NULL
                FROM dbo.BLoyaltyPointsEarned b
                INNER JOIN dbo.M_Consumer mc
                    ON mc.M_Consumerid = b.M_Consumerid
                LEFT JOIN dbo.Comp_Reg cr
                    ON cr.Comp_ID = b.compid
                WHERE b.ServiceName IN
                (
                    'InvoiceBenifit',
                    'InvoiceRewards',
                    'KYCRewards',
                    'MounthlyBenifits',
                    'Supervisor'
                ) AND ISNULL(b.Points,0) > 0
                AND b.compid = @Comp_ID
                AND b.UpdateDate >= @FromDate
                AND b.UpdateDate <= @ToDate;

                SET @InsertedCount = @InsertedCount + @@ROWCOUNT;

                IF EXISTS (
                    SELECT 1 
                    FROM dbo.TempDataSyncLog 
                    WHERE Comp_ID = @Comp_ID 
                      AND CAST(SyncDateTime AS DATE) = CAST(GETDATE() AS DATE)
                )
                BEGIN
                    UPDATE dbo.TempDataSyncLog
                    SET 
                        CodeActivityCount = @InsertedCount,
                        CodeActivityFromDate = @FromDate,
                        CodeActivityToDate = @ToDate,
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
                        CodeActivityCount,
                        CodeActivityFromDate,
                        CodeActivityToDate,
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
                        CodeActivityCount = 0,
                        CodeActivityFromDate = @FromDate,
                        CodeActivityToDate = @ToDate,
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
                        CodeActivityCount,
                        CodeActivityFromDate,
                        CodeActivityToDate,
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
END
