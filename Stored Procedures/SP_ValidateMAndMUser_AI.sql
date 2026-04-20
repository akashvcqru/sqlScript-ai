USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[SP_ValidateMAndMUser_AI]
    @DealerCode VARCHAR(50),
    @TechId VARCHAR(50),
    @UserType INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @UserTypeName VARCHAR(50), @Exists INT, @Used INT;

    -- Check if ID and Dealer Code are already used
    SELECT @Used = COUNT(*) FROM M_Consumer WHERE employeeID = @TechId AND distributorID = @DealerCode;
    IF (@Used > 0)
    BEGIN
        SELECT 'Invalid Id and Dealer Code, It is Already Used' AS Status;
        RETURN;
    END

    SELECT @UserTypeName = User_Type FROM User_Type WHERE Row_id = @UserType;

    IF (@UserTypeName <> 'M Star')
    BEGIN
        IF (@UserTypeName = 'Tech Master')
        BEGIN 
            SELECT @Exists = COUNT(*) FROM m_dealermaster WHERE DealerCode = @DealerCode AND DealerTechnicianId = @TechId AND DealerCode <> 'SBUTEAM';
            IF (@Exists = 0)
            BEGIN
                SELECT 'Invalid Tech Master Id and Dealer Code' AS Status;
                RETURN;
            END
            ELSE
            BEGIN
                SELECT 'True' AS Status;
                RETURN;
            END
        END

        IF (@UserTypeName = 'SBU')
        BEGIN 
            SELECT @Exists = COUNT(*) FROM m_dealermaster WHERE DealerCode = @DealerCode AND DealerTechnicianId = @TechId AND DealerCode = 'SBUTEAM';
            IF (@Exists = 0)
            BEGIN
                SELECT 'Invalid SBU Id and Dealer Code' AS Status;
                RETURN;
            END
            ELSE
            BEGIN
                SELECT 'True' AS Status;
                RETURN;
            END
        END
    END
    ELSE
    BEGIN
        SELECT @Exists = COUNT(*) FROM m_dealermaster_mahindra_emp WHERE DealerCode = @DealerCode AND DealerTechnicianId = @TechId;
        IF (@Exists = 0)
        BEGIN
            SELECT 'Invalid M Star and Dealer Code' AS Status;
            RETURN;
        END
        ELSE
        BEGIN
            SELECT 'True' AS Status;
            RETURN;
        END
    END
END
GO
