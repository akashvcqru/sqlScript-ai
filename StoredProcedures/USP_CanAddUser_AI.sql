USE [Vcqru]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[USP_CanAddUser_AI]
    @M_ConsumerId VARCHAR(50),
    @UserType INT,
    @CompId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CanAddUser BIT = 0;
    DECLARE @v1 INT;
    DECLARE @level1 INT;
    DECLARE @level2 INT;

    IF @M_ConsumerId IS NULL OR LTRIM(RTRIM(@M_ConsumerId)) = ''
    BEGIN
        SET @CanAddUser = 1;
        SELECT @CanAddUser AS CanAddUser;
        RETURN;
    END

    SELECT TOP 1 @v1 = Vrkabel_User_Type
    FROM tbl_Vendorvisekycstatus
    WHERE M_consumerId = CAST(@M_ConsumerId AS INT) AND comp_id = @CompId;

    IF @v1 IS NULL
    BEGIN
        SET @CanAddUser = 0;
        SELECT @CanAddUser AS CanAddUser;
        RETURN;
    END

    SELECT TOP 1 @level1 = [Level] FROM User_Type WHERE Row_ID = @UserType;
    SELECT TOP 1 @level2 = [Level] FROM User_Type WHERE Row_ID = @v1;

    IF @level1 IS NULL OR @level2 IS NULL
    BEGIN
        SET @CanAddUser = 0;
        SELECT @CanAddUser AS CanAddUser;
        RETURN;
    END

    IF @level1 < @level2
        SET @CanAddUser = 1;
    ELSE
        SET @CanAddUser = 0;

    SELECT @CanAddUser AS CanAddUser;
END
GO
