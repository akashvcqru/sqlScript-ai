-- =========================================================================================
-- Script: USP_TrackAndTrace_NodeManagement_AI.sql
-- Description: Creates tables tbl_node_master and tbl_node_user, along with stored procedures
--              for Node and Node User CRUD with search, datePreset, fromDate, toDate, pagination.
-- =========================================================================================

-- 1. Table: [dbo].[tbl_node_master]
IF OBJECT_ID(N'[dbo].[tbl_node_master]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[tbl_node_master] (
        [NodeID]       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Comp_ID]      NVARCHAR(50) NOT NULL,
        [NodeName]     NVARCHAR(200) NOT NULL,
        [NodeDetail]   NVARCHAR(500) NULL,
        [Latitude]     NVARCHAR(50) NULL,
        [Longitude]    NVARCHAR(50) NULL,
        [IsActive]     BIT NOT NULL DEFAULT (1),
        [IsDelete]     BIT NOT NULL DEFAULT (0),
        [CreatedDate]  DATETIME NOT NULL DEFAULT (GETDATE()),
        [CreatedBy]    NVARCHAR(100) NULL,
        [UpdateDate]   DATETIME NULL
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_node_master_Comp_ID_IsDelete]
        ON [dbo].[tbl_node_master] ([Comp_ID], [IsDelete])
        INCLUDE ([NodeName], [IsActive], [CreatedDate]);
END
ELSE
BEGIN
    IF COL_LENGTH('dbo.tbl_node_master', 'UpdateDate') IS NULL
    BEGIN
        ALTER TABLE [dbo].[tbl_node_master] ADD [UpdateDate] DATETIME NULL;
    END
END
GO

-- 2. Table: [dbo].[tbl_node_user]
IF OBJECT_ID(N'[dbo].[tbl_node_user]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[tbl_node_user] (
        [NodeUserId]   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [NodeID]       INT NOT NULL,
        [Comp_ID]      NVARCHAR(50) NOT NULL,
        [Name]         NVARCHAR(150) NOT NULL,
        [Email]        NVARCHAR(150) NULL,
        [Contact]      NVARCHAR(20) NULL,
        [RoleType]     NVARCHAR(50) NOT NULL, -- 'PACKER', 'DISPATCHER', 'RECEIVER', 'SUPERVISOR'
        [IsActive]     BIT NOT NULL DEFAULT (1),
        [IsDelete]     BIT NOT NULL DEFAULT (0),
        [CreatedDate]  DATETIME NOT NULL DEFAULT (GETDATE()),
        [CreatedBy]    NVARCHAR(100) NULL,
        CONSTRAINT [FK_tbl_node_user_NodeMaster] FOREIGN KEY ([NodeID]) 
            REFERENCES [dbo].[tbl_node_master]([NodeID])
    );

    CREATE NONCLUSTERED INDEX [IX_tbl_node_user_Comp_ID_NodeID_IsDelete]
        ON [dbo].[tbl_node_user] ([Comp_ID], [NodeID], [IsDelete])
        INCLUDE ([RoleType], [IsActive], [CreatedDate]);
END
GO

-- =========================================================================================
-- Stored Procedure: [dbo].[USP_ManageNodeMaster_AI]
-- Modes: INSERT, UPDATE, DELETE, SELECT
-- =========================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageNodeMaster_AI]
    @Action       VARCHAR(20),            -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT'
    @NodeID       INT            = NULL,
    @Comp_ID      NVARCHAR(50)   = NULL,
    @NodeName     NVARCHAR(200)  = NULL,
    @NodeDetail   NVARCHAR(500)  = NULL,
    @Latitude     NVARCHAR(50)   = NULL,
    @Longitude    NVARCHAR(50)   = NULL,
    @IsActive     BIT            = 1,
    @CreatedBy    NVARCHAR(100)  = NULL,
    @Search       NVARCHAR(200)  = NULL,
    @datePreset   NVARCHAR(50)   = NULL,
    @FromDate     DATETIME       = NULL,
    @ToDate       DATETIME       = NULL,
    @Page         INT            = 1,
    @Limit        INT            = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Act VARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@Action, ''))));

    -- ----------------------------------------------------
    -- 1. INSERT / ADD
    -- ----------------------------------------------------
    IF @Act IN ('INSERT', 'ADD')
    BEGIN
        IF @Comp_ID IS NULL OR LTRIM(RTRIM(@Comp_ID)) = ''
        BEGIN
            SELECT 0 AS Success, 'Company ID is required.' AS Message, 0 AS NodeID;
            RETURN;
        END

        IF @NodeName IS NULL OR LTRIM(RTRIM(@NodeName)) = ''
        BEGIN
            SELECT 0 AS Success, 'Node name is required.' AS Message, 0 AS NodeID;
            RETURN;
        END

        IF EXISTS (
            SELECT 1 FROM [dbo].[tbl_node_master] 
            WHERE [Comp_ID] = @Comp_ID 
              AND [IsDelete] = 0 
              AND LOWER([NodeName]) = LOWER(LTRIM(RTRIM(@NodeName)))
        )
        BEGIN
            SELECT 0 AS Success, 'A node with this name already exists for your company.' AS Message, 0 AS NodeID;
            RETURN;
        END

        INSERT INTO [dbo].[tbl_node_master] (
            [Comp_ID],
            [NodeName],
            [NodeDetail],
            [Latitude],
            [Longitude],
            [IsActive],
            [IsDelete],
            [CreatedDate],
            [CreatedBy]
        )
        VALUES (
            LTRIM(RTRIM(@Comp_ID)),
            LTRIM(RTRIM(@NodeName)),
            @NodeDetail,
            @Latitude,
            @Longitude,
            ISNULL(@IsActive, 1),
            0,
            GETDATE(),
            @CreatedBy
        );

        DECLARE @NewNodeID INT = SCOPE_IDENTITY();
        SELECT 1 AS Success, 'Node added successfully.' AS Message, @NewNodeID AS NodeID;
        RETURN;
    END

    -- ----------------------------------------------------
    -- 2. UPDATE / EDIT
    -- ----------------------------------------------------
    ELSE IF @Act IN ('UPDATE', 'EDIT')
    BEGIN
        IF @NodeID IS NULL OR @NodeID <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid NodeID is required.' AS Message, 0 AS NodeID;
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[tbl_node_master] 
            WHERE [NodeID] = @NodeID 
              AND [Comp_ID] = @Comp_ID 
              AND [IsDelete] = 0
        )
        BEGIN
            SELECT 0 AS Success, 'Node not found or unauthorized.' AS Message, @NodeID AS NodeID;
            RETURN;
        END

        IF @NodeName IS NOT NULL AND LTRIM(RTRIM(@NodeName)) <> ''
        BEGIN
            IF EXISTS (
                SELECT 1 FROM [dbo].[tbl_node_master] 
                WHERE [Comp_ID] = @Comp_ID 
                  AND [IsDelete] = 0 
                  AND [NodeID] <> @NodeID
                  AND LOWER([NodeName]) = LOWER(LTRIM(RTRIM(@NodeName)))
            )
            BEGIN
                SELECT 0 AS Success, 'Another node with this name already exists.' AS Message, @NodeID AS NodeID;
                RETURN;
            END
        END

        UPDATE [dbo].[tbl_node_master]
        SET [NodeName]   = ISNULL(LTRIM(RTRIM(@NodeName)), [NodeName]),
            [NodeDetail] = ISNULL(@NodeDetail, [NodeDetail]),
            [Latitude]   = ISNULL(@Latitude, [Latitude]),
            [Longitude]  = ISNULL(@Longitude, [Longitude]),
            [IsActive]   = ISNULL(@IsActive, [IsActive]),
            [UpdateDate] = GETDATE()
        WHERE [NodeID] = @NodeID AND [Comp_ID] = @Comp_ID AND [IsDelete] = 0;

        SELECT 1 AS Success, 'Node updated successfully.' AS Message, @NodeID AS NodeID;
        RETURN;
    END

    -- ----------------------------------------------------
    -- 3. DELETE / REMOVE
    -- ----------------------------------------------------
    ELSE IF @Act IN ('DELETE', 'REMOVE')
    BEGIN
        IF @NodeID IS NULL OR @NodeID <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid NodeID is required.' AS Message, 0 AS NodeID;
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[tbl_node_master] 
            WHERE [NodeID] = @NodeID 
              AND [Comp_ID] = @Comp_ID 
              AND [IsDelete] = 0
        )
        BEGIN
            SELECT 0 AS Success, 'Node not found or unauthorized.' AS Message, @NodeID AS NodeID;
            RETURN;
        END

        -- Soft delete node
        UPDATE [dbo].[tbl_node_master]
        SET [IsDelete] = 1
        WHERE [NodeID] = @NodeID AND [Comp_ID] = @Comp_ID;

        -- Soft delete associated operators
        UPDATE [dbo].[tbl_node_user]
        SET [IsDelete] = 1
        WHERE [NodeID] = @NodeID AND [Comp_ID] = @Comp_ID;

        SELECT 1 AS Success, 'Node deleted successfully.' AS Message, @NodeID AS NodeID;
        RETURN;
    END

    -- ----------------------------------------------------
    -- 4. SELECT / LIST / GET
    -- ----------------------------------------------------
    ELSE IF @Act IN ('SELECT', 'LIST', 'GET')
    BEGIN
        IF @Page < 1 SET @Page = 1;
        IF @Limit < 1 SET @Limit = 10;
        IF @Search IS NULL SET @Search = '';
        SET @Search = LTRIM(RTRIM(@Search));

        -- Date range calculation based on datePreset or explicit dates
        DECLARE @CalculatedFromDate DATETIME = NULL;
        DECLARE @CalculatedToDate   DATETIME = NULL;
        DECLARE @Preset NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

        IF @Preset = 'TODAY'
        BEGIN
            SET @CalculatedFromDate = CONVERT(DATETIME, CONVERT(DATE, GETDATE()));
            SET @CalculatedToDate   = GETDATE();
        END
        ELSE IF @Preset IN ('LASTDAY', 'YESTERDAY')
        BEGIN
            SET @CalculatedFromDate = DATEADD(DAY, -1, CONVERT(DATETIME, CONVERT(DATE, GETDATE())));
            SET @CalculatedToDate   = DATEADD(SECOND, -1, CONVERT(DATETIME, CONVERT(DATE, GETDATE())));
        END
        ELSE IF @Preset IN ('WEEK', 'THIS WEEK')
        BEGIN
            SET @CalculatedFromDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
            SET @CalculatedToDate   = GETDATE();
        END
        ELSE IF @Preset IN ('LASTWEEK', 'PREVIOUS WEEK')
        BEGIN
            SET @CalculatedFromDate = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
            SET @CalculatedToDate   = DATEADD(SECOND, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0));
        END
        ELSE IF @Preset IN ('MONTH', 'THIS MONTH')
        BEGIN
            SET @CalculatedFromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
            SET @CalculatedToDate   = GETDATE();
        END
        ELSE IF @Preset IN ('LASTMONTH', 'PREVIOUS MONTH')
        BEGIN
            SET @CalculatedFromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @CalculatedToDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0));
        END
        ELSE IF @Preset = 'QUARTER'
        BEGIN
            SET @CalculatedFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @CalculatedToDate   = GETDATE();
        END
        ELSE IF @Preset IN ('YEAR', 'THIS YEAR')
        BEGIN
            SET @CalculatedFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @CalculatedToDate   = GETDATE();
        END
        ELSE IF @Preset = 'LASTYEAR'
        BEGIN
            SET @CalculatedFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @CalculatedToDate   = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END
        ELSE IF @FromDate IS NOT NULL OR @ToDate IS NOT NULL
        BEGIN
            SET @CalculatedFromDate = @FromDate;
            SET @CalculatedToDate   = ISNULL(DATEADD(DAY, 1, @ToDate), GETDATE());
        END

        -- Fetch single node
        IF @NodeID IS NOT NULL AND @NodeID > 0
        BEGIN
            SELECT 
                n.[NodeID],
                n.[Comp_ID],
                n.[NodeName],
                n.[NodeDetail],
                n.[Latitude],
                n.[Longitude],
                n.[IsActive],
                n.[CreatedDate],
                n.[CreatedBy],
                n.[UpdateDate],
                ISNULL((SELECT COUNT(1) FROM [dbo].[tbl_node_user] u WHERE u.[NodeID] = n.[NodeID] AND u.[IsDelete] = 0), 0) AS [UserCount],
                1 AS [TotalRecords]
            FROM [dbo].[tbl_node_master] n
            WHERE n.[NodeID] = @NodeID 
              AND n.[Comp_ID] = @Comp_ID 
              AND n.[IsDelete] = 0;
            RETURN;
        END

        -- Fetch paginated list
        SELECT 
            n.[NodeID],
            n.[Comp_ID],
            n.[NodeName],
            n.[NodeDetail],
            n.[Latitude],
            n.[Longitude],
            n.[IsActive],
            n.[CreatedDate],
            n.[CreatedBy],
            n.[UpdateDate],
            ISNULL((SELECT COUNT(1) FROM [dbo].[tbl_node_user] u WHERE u.[NodeID] = n.[NodeID] AND u.[IsDelete] = 0), 0) AS [UserCount],
            COUNT(1) OVER() AS [TotalRecords]
        FROM [dbo].[tbl_node_master] n
        WHERE n.[Comp_ID] = @Comp_ID 
          AND n.[IsDelete] = 0
          AND (@IsActive IS NULL OR n.[IsActive] = @IsActive)
          AND (@Search = '' OR (n.[NodeName] LIKE '%' + @Search + '%' OR ISNULL(n.[NodeDetail], '') LIKE '%' + @Search + '%'))
          AND (@CalculatedFromDate IS NULL OR n.[CreatedDate] >= @CalculatedFromDate)
          AND (@CalculatedToDate IS NULL OR n.[CreatedDate] <= @CalculatedToDate)
        ORDER BY n.[CreatedDate] DESC
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;
        RETURN;
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid Action specified. Allowed: INSERT, UPDATE, DELETE, SELECT.' AS Message, 0 AS NodeID;
        RETURN;
    END
END
GO

-- =========================================================================================
-- Stored Procedure: [dbo].[USP_ManageNodeUser_AI]
-- Modes: INSERT, UPDATE, DELETE, SELECT
-- =========================================================================================
CREATE OR ALTER PROCEDURE [dbo].[USP_ManageNodeUser_AI]
    @Action       VARCHAR(20),            -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT'
    @NodeUserId   INT            = NULL,
    @NodeID       INT            = NULL,
    @Comp_ID      NVARCHAR(50)   = NULL,
    @Name         NVARCHAR(150)  = NULL,
    @Email        NVARCHAR(150)  = NULL,
    @Contact      NVARCHAR(20)   = NULL,
    @RoleType     NVARCHAR(50)   = NULL,  -- 'PACKER', 'DISPATCHER', 'RECEIVER', 'SUPERVISOR'
    @IsActive     BIT            = 1,
    @CreatedBy    NVARCHAR(100)  = NULL,
    @Search       NVARCHAR(200)  = NULL,
    @datePreset   NVARCHAR(50)   = NULL,
    @FromDate     DATETIME       = NULL,
    @ToDate       DATETIME       = NULL,
    @Page         INT            = 1,
    @Limit        INT            = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Act VARCHAR(20) = UPPER(LTRIM(RTRIM(ISNULL(@Action, ''))));

    -- ----------------------------------------------------
    -- 1. INSERT / ADD
    -- ----------------------------------------------------
    IF @Act IN ('INSERT', 'ADD')
    BEGIN
        IF @Comp_ID IS NULL OR LTRIM(RTRIM(@Comp_ID)) = ''
        BEGIN
            SELECT 0 AS Success, 'Company ID is required.' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        IF @NodeID IS NULL OR @NodeID <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid NodeID is required.' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[tbl_node_master] 
            WHERE [NodeID] = @NodeID 
              AND [Comp_ID] = @Comp_ID 
              AND [IsDelete] = 0
        )
        BEGIN
            SELECT 0 AS Success, 'Selected Node does not exist or is unauthorized.' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
        BEGIN
            SELECT 0 AS Success, 'User Name is required.' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        IF @RoleType IS NULL OR LTRIM(RTRIM(@RoleType)) = ''
        BEGIN
            SELECT 0 AS Success, 'RoleType is required (e.g., PACKER, DISPATCHER, RECEIVER, SUPERVISOR).' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        -- Check duplicate contact within the same company if provided
        IF @Contact IS NOT NULL AND LTRIM(RTRIM(@Contact)) <> ''
        BEGIN
            IF EXISTS (
                SELECT 1 FROM [dbo].[tbl_node_user]
                WHERE [Comp_ID] = @Comp_ID
                  AND [IsDelete] = 0
                  AND [Contact] = LTRIM(RTRIM(@Contact))
            )
            BEGIN
                SELECT 0 AS Success, 'A node user with this contact number already exists.' AS Message, 0 AS NodeUserId;
                RETURN;
            END
        END

        -- Check duplicate email within the same company if provided
        IF @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> ''
        BEGIN
            IF EXISTS (
                SELECT 1 FROM [dbo].[tbl_node_user]
                WHERE [Comp_ID] = @Comp_ID
                  AND [IsDelete] = 0
                  AND LOWER([Email]) = LOWER(LTRIM(RTRIM(@Email)))
            )
            BEGIN
                SELECT 0 AS Success, 'A node user with this email already exists.' AS Message, 0 AS NodeUserId;
                RETURN;
            END
        END

        INSERT INTO [dbo].[tbl_node_user] (
            [NodeID],
            [Comp_ID],
            [Name],
            [Email],
            [Contact],
            [RoleType],
            [IsActive],
            [IsDelete],
            [CreatedDate],
            [CreatedBy]
        )
        VALUES (
            @NodeID,
            LTRIM(RTRIM(@Comp_ID)),
            LTRIM(RTRIM(@Name)),
            LTRIM(RTRIM(@Email)),
            LTRIM(RTRIM(@Contact)),
            UPPER(LTRIM(RTRIM(@RoleType))),
            ISNULL(@IsActive, 1),
            0,
            GETDATE(),
            @CreatedBy
        );

        DECLARE @NewNodeUserId INT = SCOPE_IDENTITY();
        SELECT 1 AS Success, 'Node user added successfully.' AS Message, @NewNodeUserId AS NodeUserId;
        RETURN;
    END

    -- ----------------------------------------------------
    -- 2. UPDATE / EDIT
    -- ----------------------------------------------------
    ELSE IF @Act IN ('UPDATE', 'EDIT')
    BEGIN
        IF @NodeUserId IS NULL OR @NodeUserId <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid NodeUserId is required.' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[tbl_node_user] 
            WHERE [NodeUserId] = @NodeUserId 
              AND [Comp_ID] = @Comp_ID 
              AND [IsDelete] = 0
        )
        BEGIN
            SELECT 0 AS Success, 'Node user not found or unauthorized.' AS Message, @NodeUserId AS NodeUserId;
            RETURN;
        END

        -- If NodeID is being changed/provided, verify it
        IF @NodeID IS NOT NULL AND @NodeID > 0
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[tbl_node_master] 
                WHERE [NodeID] = @NodeID 
                  AND [Comp_ID] = @Comp_ID 
                  AND [IsDelete] = 0
            )
            BEGIN
                SELECT 0 AS Success, 'Specified Node does not exist or is unauthorized.' AS Message, @NodeUserId AS NodeUserId;
                RETURN;
            END
        END

        -- Check duplicate contact
        IF @Contact IS NOT NULL AND LTRIM(RTRIM(@Contact)) <> ''
        BEGIN
            IF EXISTS (
                SELECT 1 FROM [dbo].[tbl_node_user]
                WHERE [Comp_ID] = @Comp_ID
                  AND [IsDelete] = 0
                  AND [NodeUserId] <> @NodeUserId
                  AND [Contact] = LTRIM(RTRIM(@Contact))
            )
            BEGIN
                SELECT 0 AS Success, 'Another node user with this contact number already exists.' AS Message, @NodeUserId AS NodeUserId;
                RETURN;
            END
        END

        -- Check duplicate email
        IF @Email IS NOT NULL AND LTRIM(RTRIM(@Email)) <> ''
        BEGIN
            IF EXISTS (
                SELECT 1 FROM [dbo].[tbl_node_user]
                WHERE [Comp_ID] = @Comp_ID
                  AND [IsDelete] = 0
                  AND [NodeUserId] <> @NodeUserId
                  AND LOWER([Email]) = LOWER(LTRIM(RTRIM(@Email)))
            )
            BEGIN
                SELECT 0 AS Success, 'Another node user with this email already exists.' AS Message, @NodeUserId AS NodeUserId;
                RETURN;
            END
        END

        UPDATE [dbo].[tbl_node_user]
        SET [NodeID]    = ISNULL(@NodeID, [NodeID]),
            [Name]      = ISNULL(LTRIM(RTRIM(@Name)), [Name]),
            [Email]     = ISNULL(LTRIM(RTRIM(@Email)), [Email]),
            [Contact]   = ISNULL(LTRIM(RTRIM(@Contact)), [Contact]),
            [RoleType]  = CASE WHEN @RoleType IS NOT NULL AND LTRIM(RTRIM(@RoleType)) <> '' 
                               THEN UPPER(LTRIM(RTRIM(@RoleType))) ELSE [RoleType] END,
            [IsActive]  = ISNULL(@IsActive, [IsActive])
        WHERE [NodeUserId] = @NodeUserId AND [Comp_ID] = @Comp_ID AND [IsDelete] = 0;

        SELECT 1 AS Success, 'Node user updated successfully.' AS Message, @NodeUserId AS NodeUserId;
        RETURN;
    END

    -- ----------------------------------------------------
    -- 3. DELETE / REMOVE
    -- ----------------------------------------------------
    ELSE IF @Act IN ('DELETE', 'REMOVE')
    BEGIN
        IF @NodeUserId IS NULL OR @NodeUserId <= 0
        BEGIN
            SELECT 0 AS Success, 'Valid NodeUserId is required.' AS Message, 0 AS NodeUserId;
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[tbl_node_user] 
            WHERE [NodeUserId] = @NodeUserId 
              AND [Comp_ID] = @Comp_ID 
              AND [IsDelete] = 0
        )
        BEGIN
            SELECT 0 AS Success, 'Node user not found or unauthorized.' AS Message, @NodeUserId AS NodeUserId;
            RETURN;
        END

        UPDATE [dbo].[tbl_node_user]
        SET [IsDelete] = 1
        WHERE [NodeUserId] = @NodeUserId AND [Comp_ID] = @Comp_ID;

        SELECT 1 AS Success, 'Node user deleted successfully.' AS Message, @NodeUserId AS NodeUserId;
        RETURN;
    END

    -- ----------------------------------------------------
    -- 4. SELECT / LIST / GET
    -- ----------------------------------------------------
    ELSE IF @Act IN ('SELECT', 'LIST', 'GET')
    BEGIN
        IF @Page < 1 SET @Page = 1;
        IF @Limit < 1 SET @Limit = 10;
        IF @Search IS NULL SET @Search = '';
        SET @Search = LTRIM(RTRIM(@Search));

        -- Date range calculation based on datePreset or explicit dates
        DECLARE @UserFromDate DATETIME = NULL;
        DECLARE @UserToDate   DATETIME = NULL;
        DECLARE @UserPreset   NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@datePreset, ''))));

        IF @UserPreset = 'TODAY'
        BEGIN
            SET @UserFromDate = CONVERT(DATETIME, CONVERT(DATE, GETDATE()));
            SET @UserToDate   = GETDATE();
        END
        ELSE IF @UserPreset IN ('LASTDAY', 'YESTERDAY')
        BEGIN
            SET @UserFromDate = DATEADD(DAY, -1, CONVERT(DATETIME, CONVERT(DATE, GETDATE())));
            SET @UserToDate   = DATEADD(SECOND, -1, CONVERT(DATETIME, CONVERT(DATE, GETDATE())));
        END
        ELSE IF @UserPreset IN ('WEEK', 'THIS WEEK')
        BEGIN
            SET @UserFromDate = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0);
            SET @UserToDate   = GETDATE();
        END
        ELSE IF @UserPreset IN ('LASTWEEK', 'PREVIOUS WEEK')
        BEGIN
            SET @UserFromDate = DATEADD(WEEK, DATEDIFF(WEEK, 7, GETDATE()), 0);
            SET @UserToDate   = DATEADD(SECOND, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0));
        END
        ELSE IF @UserPreset IN ('MONTH', 'THIS MONTH')
        BEGIN
            SET @UserFromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);
            SET @UserToDate   = GETDATE();
        END
        ELSE IF @UserPreset IN ('LASTMONTH', 'PREVIOUS MONTH')
        BEGIN
            SET @UserFromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
            SET @UserToDate   = DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0));
        END
        ELSE IF @UserPreset = 'QUARTER'
        BEGIN
            SET @UserFromDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, GETDATE()), 0);
            SET @UserToDate   = GETDATE();
        END
        ELSE IF @UserPreset IN ('YEAR', 'THIS YEAR')
        BEGIN
            SET @UserFromDate = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
            SET @UserToDate   = GETDATE();
        END
        ELSE IF @UserPreset = 'LASTYEAR'
        BEGIN
            SET @UserFromDate = DATEFROMPARTS(YEAR(GETDATE()) - 1, 1, 1);
            SET @UserToDate   = DATEFROMPARTS(YEAR(GETDATE()) - 1, 12, 31);
        END
        ELSE IF @FromDate IS NOT NULL OR @ToDate IS NOT NULL
        BEGIN
            SET @UserFromDate = @FromDate;
            SET @UserToDate   = ISNULL(DATEADD(DAY, 1, @ToDate), GETDATE());
        END

        -- Single user fetch
        IF @NodeUserId IS NOT NULL AND @NodeUserId > 0
        BEGIN
            SELECT 
                u.[NodeUserId],
                u.[NodeID],
                ISNULL(m.[NodeName], '') AS [NodeName],
                u.[Comp_ID],
                u.[Name],
                u.[Email],
                u.[Contact],
                u.[RoleType],
                u.[IsActive],
                u.[CreatedDate],
                u.[CreatedBy],
                1 AS [TotalRecords]
            FROM [dbo].[tbl_node_user] u
            LEFT JOIN [dbo].[tbl_node_master] m ON u.[NodeID] = m.[NodeID]
            WHERE u.[NodeUserId] = @NodeUserId 
              AND u.[Comp_ID] = @Comp_ID 
              AND u.[IsDelete] = 0;
            RETURN;
        END

        -- Paginated user list
        SELECT 
            u.[NodeUserId],
            u.[NodeID],
            ISNULL(m.[NodeName], '') AS [NodeName],
            u.[Comp_ID],
            u.[Name],
            u.[Email],
            u.[Contact],
            u.[RoleType],
            u.[IsActive],
            u.[CreatedDate],
            u.[CreatedBy],
            COUNT(1) OVER() AS [TotalRecords]
        FROM [dbo].[tbl_node_user] u
        LEFT JOIN [dbo].[tbl_node_master] m ON u.[NodeID] = m.[NodeID]
        WHERE u.[Comp_ID] = @Comp_ID 
          AND u.[IsDelete] = 0
          AND (@NodeID IS NULL OR u.[NodeID] = @NodeID)
          AND (@RoleType IS NULL OR @RoleType = '' OR u.[RoleType] = UPPER(LTRIM(RTRIM(@RoleType))))
          AND (@IsActive IS NULL OR u.[IsActive] = @IsActive)
          AND (@Search = '' OR (
                u.[Name] LIKE '%' + @Search + '%' OR 
                ISNULL(u.[Email], '') LIKE '%' + @Search + '%' OR 
                ISNULL(u.[Contact], '') LIKE '%' + @Search + '%' OR 
                u.[RoleType] LIKE '%' + @Search + '%' OR
                ISNULL(m.[NodeName], '') LIKE '%' + @Search + '%'
          ))
          AND (@UserFromDate IS NULL OR u.[CreatedDate] >= @UserFromDate)
          AND (@UserToDate IS NULL OR u.[CreatedDate] <= @UserToDate)
        ORDER BY u.[CreatedDate] DESC
        OFFSET (@Page - 1) * @Limit ROWS
        FETCH NEXT @Limit ROWS ONLY;
        RETURN;
    END
    ELSE
    BEGIN
        SELECT 0 AS Success, 'Invalid Action specified. Allowed: INSERT, UPDATE, DELETE, SELECT.' AS Message, 0 AS NodeUserId;
        RETURN;
    END
END
GO
