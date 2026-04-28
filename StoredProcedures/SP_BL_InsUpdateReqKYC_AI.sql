SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--exec [dbo].[SP_BL_InsUpdateReqKYC_AI] 'Comp-1727','{"AadharCard":"true","PANCard":"true","AccountDetails":"true","UPI":"true"}'
CREATE PROCEDURE [dbo].[SP_BL_InsUpdateReqKYC_AI]
    @Comp_Id        VARCHAR(15),
    @KycSetting     NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------
    -- Validate required parameters
    ------------------------------------------------------
    IF (@Comp_Id IS NULL OR @Comp_Id = ''
        OR @KycSetting IS NULL OR @KycSetting = '')
    BEGIN
        SELECT 'Missing required parameters' AS Message, 0 AS Success;
        RETURN;
    END;


    BEGIN TRY
        BEGIN TRAN;

        ------------------------------------------------------
        -- Check if record exists
        ------------------------------------------------------
        IF EXISTS (SELECT 1 FROM claimKycForWebMVC WHERE Comp_ID = @Comp_Id)
        BEGIN
            --------------------------------------------------
            -- UPDATE existing record
            --------------------------------------------------
            UPDATE claimKycForWebMVC
            SET 
                kyc_Details  = @KycSetting,
                Updated_Date = GETDATE()
            WHERE Comp_ID = @Comp_Id;
        END
        ELSE
        BEGIN
            --------------------------------------------------
            -- INSERT new record
            --------------------------------------------------
            INSERT INTO claimKycForWebMVC
            (
                Comp_ID,
                kyc_Details,
                Created_Date,
                Updated_Date
            )
            VALUES
            (
                @Comp_Id,
                @KycSetting,
                GETDATE(),      -- Created_Date
                GETDATE()       -- Updated_Date
            );
        END

        COMMIT TRAN;

        SELECT 'KYC Setting saved successfully' AS Message, 1 AS Success;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;

        SELECT 
            'Error updating KYC Setting: ' + ERROR_MESSAGE() AS Message,
            0 AS Success;
    END CATCH;
END
GO
