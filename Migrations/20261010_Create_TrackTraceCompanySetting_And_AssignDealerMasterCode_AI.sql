-- =========================================================================
-- Migration: 20261010_Create_TrackTraceCompanySetting_And_AssignDealerMasterCode_AI.sql
-- Description: 
--   1. Create tbl_TrackTraceCompanySetting for company-wise Track & Trace rules.
--   2. Alter codeassign_tractrac to support optional Master Code (drop PK on mastercode, set ID as PK, make mastercode nullable).
--   3. Create USP_GetTrackTraceCompanySetting_AI to fetch company settings (with safe defaults).
--   4. Create USP_SaveTrackTraceCompanySetting_AI to upsert company settings.
--   5. Create USP_AssignDealerAndMasterCode_AI dedicated solely to code mapping & dealer assignment.
-- =========================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================
-- 1. Create Table: tbl_TrackTraceCompanySetting
-- =========================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_TrackTraceCompanySetting]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tbl_TrackTraceCompanySetting](
        [Id]                               [int] IDENTITY(1,1) NOT NULL,
        [Comp_Id]                          [varchar](50) NOT NULL,

        -- Master Code Settings
        [IsMasterCodeEnabled]              [bit] NOT NULL CONSTRAINT [DF_TTCS_IsMasterCodeEnabled] DEFAULT ((1)),
        [IsMasterCodeRequired]             [bit] NOT NULL CONSTRAINT [DF_TTCS_IsMasterCodeRequired] DEFAULT ((0)),

        -- Dealer Settings
        [IsDealerEnabled]                  [bit] NOT NULL CONSTRAINT [DF_TTCS_IsDealerEnabled] DEFAULT ((1)),
        [IsDealerRequired]                 [bit] NOT NULL CONSTRAINT [DF_TTCS_IsDealerRequired] DEFAULT ((0)),
        
        -- Additional Metadata Settings
        [IsInvoiceEnabled]                 [bit] NOT NULL CONSTRAINT [DF_TTCS_IsInvoiceEnabled] DEFAULT ((1)),
        [IsInvoiceRequired]                [bit] NOT NULL CONSTRAINT [DF_TTCS_IsInvoiceRequired] DEFAULT ((0)),

        -- Audit Columns
        [IsActive]                         [bit] NOT NULL CONSTRAINT [DF_TTCS_IsActive] DEFAULT ((1)),
        [CreatedDate]                      [datetime] NOT NULL CONSTRAINT [DF_TTCS_CreatedDate] DEFAULT (getdate()),
        [UpdatedDate]                      [datetime] NULL,
        [UpdatedBy]                        [varchar](50) NULL,

        CONSTRAINT [PK_tbl_TrackTraceCompanySetting] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_tbl_TrackTraceCompanySetting_CompId] UNIQUE NONCLUSTERED ([Comp_Id] ASC)
    ) ON [PRIMARY];
END
ELSE
BEGIN
    IF COL_LENGTH('dbo.tbl_TrackTraceCompanySetting', 'IsInvoiceEnabled') IS NULL
    BEGIN
        ALTER TABLE [dbo].[tbl_TrackTraceCompanySetting] ADD [IsInvoiceEnabled] BIT NOT NULL CONSTRAINT [DF_TTCS_IsInvoiceEnabled] DEFAULT ((1));
    END
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_tbl_TrackTraceCompanySetting_CompId_Active' AND object_id = OBJECT_ID(N'[dbo].[tbl_TrackTraceCompanySetting]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tbl_TrackTraceCompanySetting_CompId_Active] 
    ON [dbo].[tbl_TrackTraceCompanySetting] ([Comp_Id], [IsActive]) 
    INCLUDE ([IsMasterCodeEnabled], [IsMasterCodeRequired], [IsDealerEnabled], [IsDealerRequired]);
END
GO

-- =========================================================================
-- 2. Alter Table: codeassign_tractrac (Allow Nullable Master Code & Set ID as PK)
-- =========================================================================
IF OBJECT_ID(N'[dbo].[codeassign_tractrac]', N'U') IS NOT NULL
BEGIN
    -- Drop PK on mastercode if it exists
    IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE [name] = 'PK_codeassign_tractrac')
    BEGIN
        ALTER TABLE [dbo].[codeassign_tractrac] DROP CONSTRAINT [PK_codeassign_tractrac];
    END

    -- Alter mastercode column to NULL
    IF EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'[dbo].[codeassign_tractrac]') 
          AND name = 'mastercode' 
          AND is_nullable = 0
    )
    BEGIN
        ALTER TABLE [dbo].[codeassign_tractrac] ALTER COLUMN [mastercode] VARCHAR(100) NULL;
    END

    -- Make ID the Primary Key if no PK exists
    IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE [parent_object_id] = OBJECT_ID(N'[dbo].[codeassign_tractrac]') AND [type] = 'PK')
    BEGIN
        ALTER TABLE [dbo].[codeassign_tractrac] ADD CONSTRAINT [PK_codeassign_tractrac_ID] PRIMARY KEY CLUSTERED ([ID] ASC);
    END

    -- Create Filtered Unique Index on mastercode (only enforce uniqueness when mastercode is provided)
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE [name] = 'IX_codeassign_tractrac_MasterCode' AND [object_id] = OBJECT_ID(N'[dbo].[codeassign_tractrac]'))
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX [IX_codeassign_tractrac_MasterCode] 
        ON [dbo].[codeassign_tractrac]([mastercode]) 
        WHERE [mastercode] IS NOT NULL AND [mastercode] <> '';
    END
END
GO

-- =========================================================================
-- 3. Stored Procedure: USP_GetTrackTraceCompanySetting_AI
-- =========================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_GetTrackTraceCompanySetting_AI]
    @Comp_ID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [dbo].[tbl_TrackTraceCompanySetting] WITH (NOLOCK) WHERE Comp_Id = @Comp_ID AND IsActive = 1)
    BEGIN
        SELECT TOP 1
            Id,
            Comp_Id,
            IsMasterCodeEnabled,
            IsMasterCodeRequired,
            IsDealerEnabled,
            IsDealerRequired,
            IsInvoiceEnabled,
            IsInvoiceRequired,
            IsActive,
            CreatedDate,
            UpdatedDate,
            UpdatedBy
        FROM [dbo].[tbl_TrackTraceCompanySetting] WITH (NOLOCK)
        WHERE Comp_Id = @Comp_ID AND IsActive = 1;
    END
    ELSE
    BEGIN
        -- Safe defaults when company hasn't customized settings
        SELECT 
            CAST(0 AS INT) AS Id,
            @Comp_ID AS Comp_Id,
            CAST(1 AS BIT) AS IsMasterCodeEnabled,
            CAST(0 AS BIT) AS IsMasterCodeRequired,
            CAST(1 AS BIT) AS IsDealerEnabled,
            CAST(0 AS BIT) AS IsDealerRequired,
            CAST(1 AS BIT) AS IsInvoiceEnabled,
            CAST(0 AS BIT) AS IsInvoiceRequired,
            CAST(1 AS BIT) AS IsActive,
            GETDATE() AS CreatedDate,
            NULL AS UpdatedDate,
            NULL AS UpdatedBy;
    END
END
GO

-- =========================================================================
-- 4. Stored Procedure: USP_SaveTrackTraceCompanySetting_AI
-- =========================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_SaveTrackTraceCompanySetting_AI]
    @Comp_ID                          VARCHAR(50),
    @IsMasterCodeEnabled              BIT = 1,
    @IsMasterCodeRequired             BIT = 0,
    @IsDealerEnabled                  BIT = 1,
    @IsDealerRequired                 BIT = 0,
    @IsInvoiceEnabled                 BIT = 1,
    @IsInvoiceRequired                BIT = 0,
    @UpdatedBy                        VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[tbl_TrackTraceCompanySetting] WHERE Comp_Id = @Comp_ID)
        BEGIN
            UPDATE [dbo].[tbl_TrackTraceCompanySetting]
            SET IsMasterCodeEnabled             = @IsMasterCodeEnabled,
                IsMasterCodeRequired            = @IsMasterCodeRequired,
                IsDealerEnabled                 = @IsDealerEnabled,
                IsDealerRequired                = @IsDealerRequired,
                IsInvoiceEnabled                = @IsInvoiceEnabled,
                IsInvoiceRequired               = @IsInvoiceRequired,
                IsActive                        = 1,
                UpdatedDate                     = GETDATE(),
                UpdatedBy                       = @UpdatedBy
            WHERE Comp_Id = @Comp_ID;

            SELECT 1 AS success, 'Track & Trace company settings updated successfully.' AS message;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[tbl_TrackTraceCompanySetting]
            (
                Comp_Id, IsMasterCodeEnabled, IsMasterCodeRequired,
                IsDealerEnabled, IsDealerRequired,
                IsInvoiceEnabled, IsInvoiceRequired,
                IsActive, CreatedDate, UpdatedBy
            )
            VALUES
            (
                @Comp_ID, @IsMasterCodeEnabled, @IsMasterCodeRequired,
                @IsDealerEnabled, @IsDealerRequired,
                @IsInvoiceEnabled, @IsInvoiceRequired,
                1, GETDATE(), @UpdatedBy
            );

            SELECT 1 AS success, 'Track & Trace company settings saved successfully.' AS message;
        END
    END TRY
    BEGIN CATCH
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO

-- =========================================================================
-- 5. Stored Procedure: USP_AssignDealerAndMasterCode_AI
--    (Dedicated only for Assigning Dealer & Mapping Master Code)
--    (Does NOT re-create T_Pro or overwrite M_Code.Batch_No!)
-- =========================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_AssignDealerAndMasterCode_AI]
    @Comp_ID         VARCHAR(50),
    @Pro_ID          VARCHAR(50),
    @Batch_No        VARCHAR(100)   = NULL,
    @BatchSize       INT            = NULL,
    @SeriesStart     VARCHAR(100),
    @SeriesEnd       VARCHAR(100),
    @MasterCode      VARCHAR(100)   = NULL,
    @Dealer_Name     NVARCHAR(150)  = NULL,
    @Dealer_Location NVARCHAR(150)  = NULL,
    @Mobile          NVARCHAR(150)  = NULL,
    @Email           NVARCHAR(150)  = NULL,
    @Invoice_Number  NVARCHAR(50)   = NULL,
    @MRP             NUMERIC(18, 2) = NULL,
    @Mfd_Date        VARCHAR(50)    = NULL,
    @Exp_Date        VARCHAR(50)    = NULL,
    @Comments        NVARCHAR(1000) = NULL,
    @SST_Id          BIGINT         = NULL,
    @Subscribe_Id    VARCHAR(50)    = NULL,
    @DealerId        BIGINT         = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Check Company Configuration Rules
        DECLARE @IsMasterCodeEnabled BIT = 1;
        DECLARE @IsMasterCodeRequired BIT = 0;
        DECLARE @IsDealerEnabled BIT = 1;
        DECLARE @IsDealerRequired BIT = 0;
        DECLARE @IsInvoiceEnabled BIT = 1;
        DECLARE @IsInvoiceRequired BIT = 0;

        SELECT TOP 1
            @IsMasterCodeEnabled             = IsMasterCodeEnabled,
            @IsMasterCodeRequired            = IsMasterCodeRequired,
            @IsDealerEnabled                 = IsDealerEnabled,
            @IsDealerRequired                = IsDealerRequired,
            @IsInvoiceEnabled                = IsInvoiceEnabled,
            @IsInvoiceRequired               = IsInvoiceRequired
        FROM [dbo].[tbl_TrackTraceCompanySetting] WITH (NOLOCK)
        WHERE Comp_Id = @Comp_ID AND IsActive = 1;

        -- 2. Validate Dealer details (auto-lookup from M_Dealer_AI if DealerId passed)
        IF @DealerId IS NOT NULL AND @DealerId > 0
        BEGIN
            SELECT TOP 1 
                @Dealer_Name     = ISNULL(@Dealer_Name, Dealer_Name),
                @Dealer_Location = ISNULL(@Dealer_Location, Dealer_Location),
                @Mobile          = ISNULL(@Mobile, mobile),
                @Email           = ISNULL(@Email, email),
                @Invoice_Number  = ISNULL(@Invoice_Number, Invoice_Number)
            FROM M_Dealer_AI WITH (NOLOCK) 
            WHERE ID = @DealerId AND (Comp_ID = @Comp_ID OR @Comp_ID IS NULL);
        END

        IF @IsDealerRequired = 1 AND (ISNULL(@Dealer_Name, '') = '')
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'Dealer assignment is mandatory for your company.' AS message;
            RETURN;
        END

        -- 3. Validate Invoice Number if required
        IF @IsInvoiceRequired = 1 AND (ISNULL(@Invoice_Number, '') = '')
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'Invoice Number is mandatory for your company.' AS message;
            RETURN;
        END

        -- 4. Validate Master Code
        IF @IsMasterCodeRequired = 1 AND (ISNULL(@MasterCode, '') = '')
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'Master Code is mandatory for your company.' AS message;
            RETURN;
        END

        -- If MasterCode is provided, validate uniqueness and existence
        IF ISNULL(@MasterCode, '') <> ''
        BEGIN
            IF EXISTS (SELECT 1 FROM [dbo].[codeassign_tractrac] WITH (NOLOCK) WHERE mastercode = @MasterCode)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS success, CONCAT('Master code ''', @MasterCode, ''' is already mapped to another batch/series.') AS message;
                RETURN;
            END
        END

        -- 5. Validate Series Range
        DECLARE @StartOrder INT = NULL, @StartSerial INT = NULL;
        DECLARE @EndOrder INT = NULL, @EndSerial INT = NULL;

        IF @SeriesStart LIKE '%-%-%'
        BEGIN
            DECLARE @StartP2 VARCHAR(50) = SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart));
            SET @StartOrder = TRY_CAST(LEFT(@StartP2, CHARINDEX('-', @StartP2) - 1) AS INT);
            SET @StartSerial = TRY_CAST(SUBSTRING(@StartP2, CHARINDEX('-', @StartP2) + 1, LEN(@StartP2)) AS INT);
        END
        ELSE IF @SeriesStart LIKE '%-%'
        BEGIN
            SET @StartOrder = TRY_CAST(LEFT(@SeriesStart, CHARINDEX('-', @SeriesStart) - 1) AS INT);
            SET @StartSerial = TRY_CAST(SUBSTRING(@SeriesStart, CHARINDEX('-', @SeriesStart) + 1, LEN(@SeriesStart)) AS INT);
        END

        IF @SeriesEnd LIKE '%-%-%'
        BEGIN
            DECLARE @EndP2 VARCHAR(50) = SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd));
            SET @EndOrder = TRY_CAST(LEFT(@EndP2, CHARINDEX('-', @EndP2) - 1) AS INT);
            SET @EndSerial = TRY_CAST(SUBSTRING(@EndP2, CHARINDEX('-', @EndP2) + 1, LEN(@EndP2)) AS INT);
        END
        ELSE IF @SeriesEnd LIKE '%-%'
        BEGIN
            SET @EndOrder = TRY_CAST(LEFT(@SeriesEnd, CHARINDEX('-', @SeriesEnd) - 1) AS INT);
            SET @EndSerial = TRY_CAST(SUBSTRING(@SeriesEnd, CHARINDEX('-', @SeriesEnd) + 1, LEN(@SeriesEnd)) AS INT);
        END

        IF @StartOrder IS NULL OR @StartSerial IS NULL OR @EndOrder IS NULL OR @EndSerial IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS success, 'Invalid series format. Expected: PROD-ORDER-SERIAL or ORDER-SERIAL.' AS message;
            RETURN;
        END

        -- 6. Read existing batch info from T_Pro if available (NO RE-INSERTION!)
        IF @Batch_No IS NOT NULL AND @Batch_No <> ''
        BEGIN
            SELECT TOP 1 
                @MRP = ISNULL(@MRP, MRP),
                @Mfd_Date = ISNULL(@Mfd_Date, CONVERT(VARCHAR(50), Mfd_Date, 120)),
                @Exp_Date = ISNULL(@Exp_Date, CONVERT(VARCHAR(50), Exp_Date, 120))
            FROM [dbo].[T_Pro] WITH (NOLOCK)
            WHERE Pro_ID = @Pro_ID AND (Batch_No = @Batch_No OR Row_ID = TRY_CAST(@Batch_No AS BIGINT));
        END

        -- 7. Find active Track & Trace Subscription if SST_Id / Subscribe_Id not provided
        IF @SST_Id IS NULL OR @Subscribe_Id IS NULL
        BEGIN
            SELECT TOP 1 
                @Subscribe_Id = SS.Subscribe_Id,
                @SST_Id = SST.SST_Id
            FROM M_ServiceSubscription SS WITH (NOLOCK)
            LEFT JOIN M_ServiceSubscriptionTrans SST WITH (NOLOCK) ON SS.Subscribe_Id = SST.Subscribe_Id
            WHERE SS.Comp_ID = @Comp_ID 
              AND SS.Pro_ID = @Pro_ID 
              AND SS.Service_ID = 'SRV1021'
              AND (
                  (SS.start_order <= @StartOrder AND SS.end_order >= @EndOrder)
                  OR SS.start_order IS NULL
              )
            ORDER BY SS.EntryDate DESC;
        END

        -- 8. Check if already assigned in codeassign_tractrac for this range
        IF EXISTS (
            SELECT 1 FROM [dbo].[codeassign_tractrac] WITH (NOLOCK)
            WHERE Pro_ID = @Pro_ID 
              AND SeriesStart = @SeriesStart 
              AND SeriesEnd = @SeriesEnd
              AND (isdelete = 0 OR isdelete IS NULL)
        )
        BEGIN
            -- Update existing assignment
            UPDATE [dbo].[codeassign_tractrac]
            SET mastercode       = NULLIF(@MasterCode, ''),
                Dealer_Name      = ISNULL(@Dealer_Name, Dealer_Name),
                Dealer_Location  = ISNULL(@Dealer_Location, Dealer_Location),
                Mobile           = ISNULL(@Mobile, Mobile),
                Email            = ISNULL(@Email, Email),
                Invoice_Number   = ISNULL(@Invoice_Number, Invoice_Number),
                Batch_No         = ISNULL(@Batch_No, Batch_No),
                BatchSize        = ISNULL(@BatchSize, BatchSize),
                MRP              = ISNULL(@MRP, MRP),
                Mfd_Date         = CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE Mfd_Date END,
                Exp_Date         = CASE WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) ELSE Exp_Date END,
                SST_Id           = ISNULL(@SST_Id, SST_Id),
                Subscribe_Id     = ISNULL(@Subscribe_Id, Subscribe_Id),
                Dispatch_Date    = GETDATE()
            WHERE Pro_ID = @Pro_ID 
              AND SeriesStart = @SeriesStart 
              AND SeriesEnd = @SeriesEnd;

            COMMIT TRANSACTION;
            SELECT 1 AS success, 'Track & Trace dealer and master code mapping updated successfully.' AS message;
            RETURN;
        END

        -- 9. INSERT into codeassign_tractrac
        DECLARE @InsertedID BIGINT;

        INSERT INTO [dbo].[codeassign_tractrac]
        (
            mastercode,
            Pro_ID,
            MRP,
            Mfd_Date,
            Exp_Date,
            Batch_No,
            SeriesStart,
            SeriesEnd,
            entry_date,
            Dealer_Name,
            Dealer_Location,
            Mobile,
            Email,
            Dispatch_Date,
            Invoice_Number,
            SST_Id,
            Subscribe_Id,
            BatchSize,
            status,
            isdelete
        )
        VALUES
        (
            NULLIF(@MasterCode, ''),
            @Pro_ID,
            @MRP,
            CASE WHEN ISDATE(@Mfd_Date) = 1 THEN CAST(@Mfd_Date AS DATETIME) ELSE NULL END,
            CASE WHEN ISDATE(@Exp_Date) = 1 THEN CAST(@Exp_Date AS DATETIME) ELSE NULL END,
            @Batch_No,
            @SeriesStart,
            @SeriesEnd,
            GETDATE(),
            @Dealer_Name,
            @Dealer_Location,
            @Mobile,
            @Email,
            GETDATE(),
            @Invoice_Number,
            @SST_Id,
            @Subscribe_Id,
            @BatchSize,
            0,
            0
        );

        SET @InsertedID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT 
            1 AS success, 
            'Track & Trace dealer and master code mapped successfully.' AS message,
            @InsertedID AS TrackTrace_ID,
            @MasterCode AS MasterCode,
            @Dealer_Name AS Dealer_Name;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS success, ERROR_MESSAGE() AS message;
    END CATCH
END
GO
