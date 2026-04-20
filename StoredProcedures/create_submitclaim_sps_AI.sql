USE [Vcqru]
GO

/****** Object:  StoredProcedure [dbo].[sp_get_Cunsumer_point_Vendorwise_BL_Dual_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_get_Cunsumer_point_Vendorwise_BL_Dual_AI]    
    @M_consumerid VARCHAR(10),  
    @Compid VARCHAR(10)  
AS    
BEGIN  
    -- Final total row (sum of both point types)
    SELECT 
        'Total' AS Compid,
        (
            ISNULL((
                SELECT SUM(bl.points) 
                FROM dbo.[BLoyaltyPointsEarned] bl     
                LEFT JOIN [dbo].[M_ServiceSubscriptionTrans] ms ON bl.sst_id = ms.sst_id     
                LEFT JOIN [dbo].M_ServiceSubscription mss ON mss.Subscribe_Id = ms.Subscribe_Id     
                WHERE bl.M_consumerid = @M_consumerid   
                  AND mss.Comp_ID = @Compid 
            ), 0)
            +
            ISNULL((
                SELECT SUM(points)
                FROM BLoyaltyPointsEarned 
                WHERE M_Consumerid = @M_consumerid 
                  AND compid = @Compid 
                  AND ServiceName = 'Referral'
            ), 0)
        ) AS point,
        (
            SELECT ISNULL(cl.p_cash, 0)
            FROM dbo.claimredeem cl
            WHERE cl.compid = @Compid 
        ) AS p_cash
END
GO

/****** Object:  StoredProcedure [dbo].[UpdateBankKycDetails_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[UpdateBankKycDetails_AI]
(
    @ConsumerID        INT,
    @IFSC_Code         VARCHAR(20),
    @AccountNo         VARCHAR(20),
    @ClaimMode         VARCHAR(20),
    @Comp_ID         VARCHAR(20),
    @NameAtBank        VARCHAR(70),
    @Aggred            BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @Now DATETIME = GETDATE(),
        @BankRefId VARCHAR(100),
        @IsVerified BIT,
        @ResponseCode VARCHAR(5);

	   INSERT INTO dbo.UserClaimPreferences
        (
            M_Consumerid,
            Comp_Id,
            ClaimMode
        )
        VALUES
        (
            @ConsumerID,
            @Comp_ID,
            @ClaimMode
        );

    SET @BankRefId = 'KYC-' + CONVERT(VARCHAR(20), @Now, 112)
                     + REPLACE(CONVERT(VARCHAR(8), @Now, 108), ':', '');

    SET @IsVerified = CASE WHEN @Aggred = 1 THEN 1 ELSE 0 END;
    SET @ResponseCode = CASE WHEN @Aggred = 1 THEN '200' ELSE '400' END;

    IF EXISTS (
        SELECT 1 
        FROM dbo.tblKycBankDataDetails
        WHERE M_Consumerid = @ConsumerID
    )
    BEGIN
        UPDATE dbo.tblKycBankDataDetails
        SET
            AccountHolderName     = @NameAtBank,
            BankRefrenceId        = @BankRefId,
            IsBankAccountVerify   = @IsVerified,
            BankReqdate           = @Now,
            BankRemarks           = CASE WHEN @Aggred = 1 
                                          THEN 'Valid Authentication'
                                          ELSE 'Not Valid Authentication' END,
            ResponseCode          = @ResponseCode,
            IFSC_Code             = @IFSC_Code,
            AccountNo             = @AccountNo,
            KycMode               = 'BANK_PENNY_DROP',
            created_at            = @Now
        WHERE M_Consumerid = @ConsumerID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblKycBankDataDetails
        (
            M_Consumerid,
            AccountHolderName,
            BankRefrenceId,
            IsBankAccountVerify,
            BankReqdate,
            BankReqCount,
            BankRemarks,
            ResponseCode,
            Status,
            ReqCount,
            IFSC_Code,
            AccountNo,
            KycMode,
            created_at
        )
        VALUES
        (
            @ConsumerID,
            @NameAtBank,
            @BankRefId,
            @IsVerified,
            @Now,
            '1',
            CASE WHEN @Aggred = 1 THEN 'Valid Authentication'
                 ELSE 'Not Valid Authentication' END,
            @ResponseCode,
            1,
            '1',
            @IFSC_Code,
            @AccountNo,
            'BANK_PENNY_DROP',
            @Now
        );
    END

    IF EXISTS (
        SELECT 1 
        FROM dbo.M_BankAccount
        WHERE M_Consumerid = @ConsumerID
    )
    BEGIN
        UPDATE dbo.M_BankAccount
        SET
            Account_HolderNm = @NameAtBank,
            IFSC_Code = @IFSC_Code,
            Account_No = @AccountNo,
            Entry_Date = @Now,
            TNC = @Aggred
        WHERE M_Consumerid = @ConsumerID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.M_BankAccount
        (
            Bank_ID,
            Account_HolderNm,
            Account_No,
            IFSC_Code,
            Entry_Date,
            Flag,
            M_Consumerid,
            TNC
        )
        VALUES
        (
            @BankRefId,
            @NameAtBank,
            @AccountNo,
            @IFSC_Code,
            @Now,
            1,
            @ConsumerID,
            @Aggred
        );
    END

	update M_Consumer set bankekycStatus = '1' where M_Consumerid = @ConsumerID

    SELECT 
        1 AS Success,
        'Bank KYC data saved successfully' AS Message,
        @BankRefId AS BankReferenceId;
END
GO

/****** Object:  StoredProcedure [dbo].[SP_AddOrUpdate_UserClaimPreference_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_AddOrUpdate_UserClaimPreference_AI]
(
    @M_Consumerid INT,
    @Comp_Id VARCHAR(20),
    @ClaimMode VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

        INSERT INTO UserClaimPreferences (M_Consumerid, Comp_Id, ClaimMode)
        VALUES (@M_Consumerid, @Comp_Id, @ClaimMode);
END
GO

/****** Object:  StoredProcedure [dbo].[GetKYBANKANDUPIConsumerDetails_BL_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetKYBANKANDUPIConsumerDetails_BL_AI]  
    @ConsumerID INT  
AS  
BEGIN  
    DECLARE @Result TABLE  
    (  
        UPIID VARCHAR(255),  
        BeneficiaryName VARCHAR(255),  
        UPIKYCStatus VARCHAR(50),  
        AccountHolderName VARCHAR(255),  
        IFSC_Code VARCHAR(20),  
        AccountNo VARCHAR(50),  
        BankKYCStatus VARCHAR(50)  
    )  
  
    INSERT INTO @Result (UPIID, BeneficiaryName, UPIKYCStatus)  
    SELECT TOP 1   
        upi.UPIID,  
        upi.Benificiryname,  
        mc.UPIKYCSTATUS  
    FROM   
        tbl_UPIVerificationdata upi  
    INNER JOIN   
        M_Consumer mc ON mc.M_Consumerid = upi.M_Consumer_id  
    WHERE   
        upi.M_Consumer_id = @ConsumerID  
        AND upi.Status = 'True'   
        AND upi.ResponseCode = 100   
        AND upi.Responsemsg = 'Valid Authentication';  

    IF NOT EXISTS (SELECT 1 FROM @Result)
    BEGIN
        INSERT INTO @Result (UPIID, BeneficiaryName, UPIKYCStatus)
        VALUES (NULL, NULL, NULL)
    END

    IF EXISTS (  
        SELECT 1  
        FROM   
            tblKycBankDataDetails b  
        INNER JOIN   
            M_Consumer mc ON mc.M_Consumerid = b.M_Consumerid  
        WHERE   
            b.M_Consumerid = @ConsumerID  
            AND b.IsBankAccountVerify = 1  
            AND b.BankRemarks = 'Valid Authentication'  
            AND b.ResponseCode = 100  
            AND b.Status = 1  
            AND b.KycMode = 'Online'  
    )  
    BEGIN  
        UPDATE r  
        SET   
            r.AccountHolderName = b.AccountHolderName,  
            r.IFSC_Code = b.IFSC_Code,  
            r.AccountNo = b.AccountNo,  
            r.BankKYCStatus = mc.bankekycStatus  
        FROM   
            @Result r  
        INNER JOIN   
            tblKycBankDataDetails b ON b.M_Consumerid = @ConsumerID  
        INNER JOIN   
            M_Consumer mc ON mc.M_Consumerid = b.M_Consumerid  
        WHERE   
            b.M_Consumerid = @ConsumerID;  
    END  
    ELSE  
    BEGIN  
        UPDATE r  
        SET   
            r.AccountHolderName = b.Account_HolderNm,  
            r.IFSC_Code = b.IFSC_Code,  
            r.AccountNo = b.Account_No,  
            r.BankKYCStatus = mc.bankekycStatus  
        FROM   
            @Result r  
        INNER JOIN   
            M_BankAccount b ON b.M_Consumerid = @ConsumerID  
        INNER JOIN   
            M_Consumer mc ON mc.M_Consumerid = b.M_Consumerid  
        WHERE   
            b.M_Consumerid = @ConsumerID  
            AND (mc.bankekycStatus = '1' OR mc.bankekycStatus = 'Online');  
    END  
  
    SELECT * FROM @Result;  
END  
GO

/****** Object:  StoredProcedure [dbo].[GetKYBANKANDUPIConsumerDetails_BL_IMPS_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetKYBANKANDUPIConsumerDetails_BL_IMPS_AI]  
    @ConsumerID INT  
AS  
BEGIN  
    DECLARE @Result TABLE  
    (  
        UPIID VARCHAR(255),  
        BeneficiaryName VARCHAR(255),  
        UPIKYCStatus VARCHAR(50),  
        AccountHolderName VARCHAR(255),  
        IFSC_Code VARCHAR(20),  
        AccountNo VARCHAR(50),  
        BankKYCStatus VARCHAR(50)  
    )  
  
    IF EXISTS (  
        SELECT 1  
        FROM   
            tblKycBankDataDetails b  
        INNER JOIN   
            M_Consumer mc ON mc.M_Consumerid = b.M_Consumerid  
        WHERE   
            b.M_Consumerid = @ConsumerID  
            AND b.IsBankAccountVerify = 1  
            AND b.BankRemarks = 'Valid Authentication'  
            AND b.ResponseCode in (100 ,200) 
            AND b.Status = 1  
            AND b.KycMode in ( 'Online' , 'BANK_PENNY_DROP')  
    )  
    BEGIN 
	INSERT INTO @Result (UPIID, BeneficiaryName, UPIKYCStatus)  
    SELECT TOP 1   
       '' AS UPIID,  
       '' AS Benificiryname,  
        '' AS UPIKYCSTATUS  
    FROM   
        tblKycBankDataDetails upi  
    INNER JOIN   
        M_Consumer mc ON mc.M_Consumerid = upi.M_Consumerid  
    WHERE   
        upi.M_Consumerid = @ConsumerID  
        AND upi.Status = 'True'   
        AND upi.ResponseCode in ( 100,200);  

        UPDATE r  
        SET   
            r.AccountHolderName = b.AccountHolderName,  
            r.IFSC_Code = b.IFSC_Code,  
            r.AccountNo = b.AccountNo,  
			r.BankKYCStatus = 
        CASE 
            WHEN mc.bankekycStatus = '1'
              OR mc.bankekycStatus = 'Online'
              OR (b.AccountNo IS NOT NULL and  b.IFSC_Code is not null)
            THEN '1'
            ELSE mc.bankekycStatus
        END
        FROM   
            @Result r  
        INNER JOIN   
            tblKycBankDataDetails b ON b.M_Consumerid = @ConsumerID  
        INNER JOIN   
            M_Consumer mc ON mc.M_Consumerid = b.M_Consumerid  
        WHERE   
            b.M_Consumerid = @ConsumerID;  
    END  
    ELSE  
    BEGIN  
	INSERT INTO @Result (UPIID, BeneficiaryName, UPIKYCStatus)  
    SELECT TOP 1   
       '' AS UPIID,  
       '' AS Benificiryname,  
        '' AS UPIKYCSTATUS  
    FROM   
        M_BankAccount upi  
    INNER JOIN   
        M_Consumer mc ON mc.M_Consumerid = upi.M_Consumerid  
    WHERE   
        upi.M_Consumerid = @ConsumerID  
        
        UPDATE r  
        SET   
            r.AccountHolderName = b.Account_HolderNm,  
            r.IFSC_Code = b.IFSC_Code,  
            r.AccountNo = b.Account_No,  
			r.BankKYCStatus = 
        CASE 
            WHEN mc.bankekycStatus = '1'
              OR mc.bankekycStatus = 'Online'
              OR (b.Account_No IS NOT NULL and  b.IFSC_Code is not null)
            THEN '1'
            ELSE mc.bankekycStatus
        END
        FROM   
            @Result r  
        INNER JOIN   
            M_BankAccount b ON b.M_Consumerid = @ConsumerID  
        INNER JOIN   
            M_Consumer mc ON mc.M_Consumerid = b.M_Consumerid  and mc.IsDelete=0
        WHERE   
            b.M_Consumerid = @ConsumerID  
            AND (mc.bankekycStatus = '1' OR mc.bankekycStatus = 'Online' OR b.Account_No is not null);  
    END  
  
    SELECT * FROM @Result;  
END  
GO

/****** Object:  StoredProcedure [dbo].[USP_Consumerpoint_ServiceWise_AI] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER procedure [dbo].[USP_Consumerpoint_ServiceWise_AI]
@CompId varchar(50),
@M_Consumerid varchar(50),
@Service_ID varchar(50)
as
begin

SELECT COALESCE(SUM(CAST(bp.Points AS INT)), 0) + 
       COALESCE(
           (SELECT COALESCE(SUM(CAST(bp2.Points AS INT)), 0)
            FROM BLoyaltyPointsEarned bp2
            WHERE bp2.M_Consumerid = @M_Consumerid AND (bp2.compid = @CompId   or (@compid IN ('Comp-1650', 'Comp-1567') and bp2.compid IN ('Comp-1650', 'Comp-1567') )) 
			AND bp2.ServiceName in ('Referral') 
           ), 0
       ) + isnull((select points from BLoyaltyPointsEarned bp3 where bp3.M_Consumerid = @M_consumerid and bp3.ServiceName = 'KYCRewards'),0) AS TotalPoints
FROM BLoyaltyPointsEarned bp
INNER JOIN M_ServiceSubscriptionTrans mss ON mss.SST_Id = bp.SST_id
INNER JOIN M_ServiceSubscription ms ON ms.Subscribe_Id = mss.Subscribe_Id
inner join M_Service msc on msc.Service_ID = ms.Service_ID
WHERE bp.M_Consumerid = @M_Consumerid and msc.Service_ID = @Service_ID AND (ms.Comp_ID = @CompId or (@compid IN ('Comp-1650', 'Comp-1567') and ms.Comp_ID IN ('Comp-1650', 'Comp-1567') ));

end
GO
