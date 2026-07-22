USE [Vcqru]
GO
/****** Object:  StoredProcedure [dbo].[USP_FillTempUPIPayoutReport_AllCompanies]    Script Date: 7/22/2026 2:39:05 PM ******/
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
        CompanyName NVARCHAR(200)
    );

    INSERT INTO @Companies (CompanyName)
    VALUES
    ('SHERKOTTI INDUSTRIES PRIVATE LIMITED'),
    ('PANKAJ PETRO CHEMICALS'),
    ('CHAUDHARY MARBLES'),
    ('SURIE POLEX INDUSTRIES LLP'),
    ('OCI Wires and Cables'),
    ('TYCON CABLES INDIA PRIVATE LIMITED'),
    ('Wembley');

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

        SELECT @CompanyName = CompanyName
        FROM @Companies
        WHERE ID = @i;

        SELECT @Comp_ID = Comp_ID
        FROM Comp_Reg
        WHERE Comp_Name LIKE '%' + @CompanyName + '%';

        IF @Comp_ID IS NOT NULL
        BEGIN
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
        END
        ELSE
        BEGIN
            PRINT 'Company Not Found : ' + @CompanyName;
        END

        SET @i = @i + 1;
    END
END
