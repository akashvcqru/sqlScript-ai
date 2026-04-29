SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antigravity
-- Create date: 24-Apr-2026
-- Modified:    29-Apr-2026 (Use WarrantyId directly, remove WarrantyCode/MobileNo)
-- Description: Handle Warranty Claim Request
-- =============================================
ALTER PROCEDURE [dbo].[USP_WarrantClaimRequest_AI]
(
    @WarrantyId INT,
    @Comment NVARCHAR(MAX),
    @PrimaryImagePath NVARCHAR(MAX),
    @AdditionalImages NVARCHAR(MAX) = NULL -- Comma separated file paths
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Code NVARCHAR(50);
        DECLARE @Code1 NVARCHAR(10);
        DECLARE @Code2 NVARCHAR(15);
        DECLARE @CompID NVARCHAR(50);
        DECLARE @ProID NVARCHAR(50);
        DECLARE @MobileNo NVARCHAR(20);

        -- Validate Warranty ID exists
        SELECT TOP 1 @Code = code 
        FROM [dbo].[WarrentyDetails] 
        WHERE id = @WarrantyId;

        IF @Code IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS Success, 'Warranty details not found for the provided ID' AS Message;
            RETURN;
        END

        -- Split code to get Code1 and Code2
        IF CHARINDEX('-', @Code) > 0
        BEGIN
            SET @Code1 = LEFT(@Code, CHARINDEX('-', @Code) - 1);
            SET @Code2 = SUBSTRING(@Code, CHARINDEX('-', @Code) + 1, LEN(@Code));
        END
        ELSE IF LEN(@Code) >= 13
        BEGIN
            SET @Code1 = LEFT(@Code, 5);
            SET @Code2 = SUBSTRING(@Code, 6, 8);
        END

        -- Update Warranty Details
        UPDATE [dbo].[WarrentyDetails]
        SET [IsWarrantyClaimed] = 0,
            [Comment] = @Comment,
            [VendorClaimStatus] = 'Pending',
            [ImagePath] = @PrimaryImagePath,
            [claimdate] = GETDATE()
        WHERE id = @WarrantyId;

        -- Insert Primary Image into File table
        INSERT INTO [dbo].[File] ([Email], [Mobile], [FileName], [FilePath], [WarId])
        VALUES ('', ISNULL(@MobileNo, ''), REVERSE(LEFT(REVERSE(@PrimaryImagePath), CHARINDEX('/', REVERSE(@PrimaryImagePath)) - 1)), @PrimaryImagePath, @WarrantyId);

        -- Insert Additional Images
        IF @AdditionalImages IS NOT NULL AND LEN(@AdditionalImages) > 0
        BEGIN
            -- Using a simple string splitter for compatibility
            DECLARE @xml XML = CAST('<t>' + REPLACE(@AdditionalImages, ',', '</t><t>') + '</t>' AS XML);
            
            INSERT INTO [dbo].[File] ([Email], [Mobile], [FileName], [FilePath], [WarId])
            SELECT 
                '', 
                ISNULL(@MobileNo, ''), 
                REVERSE(LEFT(REVERSE(t.value('.', 'nvarchar(max)')), CHARINDEX('/', REVERSE(t.value('.', 'nvarchar(max)'))) - 1)),
                t.value('.', 'nvarchar(max)'), 
                @WarrantyId
            FROM @xml.nodes('/t') AS x(t)
            WHERE LEN(t.value('.', 'nvarchar(max)')) > 0;
        END

        -- Fetch Data for Email
        DECLARE @ConsumerName NVARCHAR(200);
        DECLARE @ConsumerEmail NVARCHAR(200);
        DECLARE @ProductName NVARCHAR(200);
        DECLARE @CompanyName NVARCHAR(200);

        -- Get CompID and ProID
        SELECT TOP 1 @ProID = Pro_ID FROM M_Code WHERE Code1 = @Code1 AND Code2 = @Code2;
        SELECT TOP 1 @CompID = Comp_ID, @ProductName = pro_name FROM Pro_Reg WHERE Pro_ID = @ProID;
        SELECT TOP 1 @CompanyName = comp_name FROM comp_reg WHERE Comp_ID = @CompID;

        -- Get Consumer Details and MobileNo from warranty activation
        SELECT TOP 1 @MobileNo = wd.Mobile, @ConsumerName = mc.ConsumerName, @ConsumerEmail = mc.Email
        FROM [dbo].[WarrentyDetails] wd
        LEFT JOIN M_Consumer mc ON RIGHT(mc.MobileNo, 10) = RIGHT(wd.Mobile, 10) AND mc.IsDelete = 0
        WHERE wd.id = @WarrantyId;

        COMMIT TRANSACTION;

        -- Return result for Backend processing
        SELECT 
            1 AS Success,
            'Warranty claimed successfully' AS Message,
            @WarrantyId AS Row_ID,
            ISNULL(@ConsumerName, 'User') AS ConsumerName,
            ISNULL(@ConsumerEmail, '') AS ConsumerEmail,
            ISNULL(@MobileNo, '') AS MobileNo,
            @ProductName AS ProductName,
            @CompID AS Comp_ID,
            @CompanyName AS CompanyName,
            @Comment AS Comment,
            @PrimaryImagePath AS PrimaryImagePath,
            @Code AS WarrantyCode;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
GO
