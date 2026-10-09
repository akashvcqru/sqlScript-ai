USE [Vcqru];
GO
 
SET NOCOUNT ON;
 
-- Choose ONE index: 1 to 7.
DECLARE @IndexNumber int = 1;
 
-- 0 = Preview only; 1 = Create the selected index.
DECLARE @Execute bit = 0;
 
DECLARE @OriginalLockTimeout int = @@LOCK_TIMEOUT;
 
DECLARE @Plan TABLE
(
    IndexNumber int PRIMARY KEY,
    TableName sysname,
    IndexName sysname,
    KeyColumns nvarchar(1000),
    IncludeColumns nvarchar(2000)
);
 
INSERT INTO @Plan
    (IndexNumber, TableName, IndexName, KeyColumns, IncludeColumns)
VALUES
(1, N'ConsumerPointsCashDetails',
    N'IX_CPCD_EnqDate_Cover',
    N'Enq_Date',
    N'MobileNo,Cash,Points,Is_Success'),
 
(2, N'ConsumerPointsCashDetails',
    N'IX_CPCD_MobileNo_EnqDate_Cover',
    N'MobileNo,Enq_Date',
    N'Code1,Code2,Cash,Is_Success,Pro_Name,Service_ID'),
 
(3, N'ConsumerPointsCashDetails',
    N'IX_CPCD_PE_ID',
    N'PE_ID',
    N''),
 
(4, N'GeoLocationData',
    N'IX_GeoLocationData_Code1_Code2_EnqDate',
    N'Code1,Code2,Enq_Date',
    N'MobileNo,City,State'),
 
(5, N'm_dealermaster_mahindra_emp',
    N'IX_MahindraEmp_DealerCode_TechnicianId',
    N'DealerCode,DealerTechnicianId',
    N''),
 
(6, N'dealer_credit_limits',
    N'IX_DealerCredit_Consumer_Company',
    N'M_Consumerid,Comp_id',
    N''),
 
(7, N'dealer_security_deposits',
    N'IX_DealerSecurity_Consumer_Company',
    N'M_Consumerid,Comp_id',
    N'');
 
DECLARE
    @TableName sysname,
    @IndexName sysname,
    @QualifiedTable nvarchar(517),
    @Keys nvarchar(1000),
    @Includes nvarchar(2000),
    @ObjectID int,
    @ExistingIndex sysname,
    @KeyCount int,
    @IncludeXML xml,
    @AllColumnsXML xml,
    @SQL nvarchar(max);
 
BEGIN TRY
    IF DB_NAME() <> N'Vcqru'
        THROW 50001, 'Wrong database. Expected Vcqru.', 1;
 
    IF @@TRANCOUNT > 0
        THROW 50002,
            'Use a session without an open transaction.', 1;
 
    IF (@@OPTIONS & 2) = 2
        THROW 50003,
            'Turn IMPLICIT_TRANSACTIONS OFF before running this script.', 1;
 
    IF @Execute IS NULL
        THROW 50004, 'Execute must be 0 or 1.', 1;
 
    SELECT
        @TableName = TableName,
        @IndexName = IndexName,
        @Keys = KeyColumns,
        @Includes = IncludeColumns
    FROM @Plan
    WHERE IndexNumber = @IndexNumber;
 
    IF @TableName IS NULL
        THROW 50005, 'Choose an IndexNumber between 1 and 7.', 1;
 
    SET @QualifiedTable =
        QUOTENAME(N'dbo') + N'.' + QUOTENAME(@TableName);
 
    SET @ObjectID = OBJECT_ID(@QualifiedTable, N'U');
 
    IF @ObjectID IS NULL
        THROW 50006,
            'Target table was not found or is not visible to this login.', 1;
 
    IF ISNULL(
        HAS_PERMS_BY_NAME(
            @QualifiedTable, N'OBJECT', N'VIEW DEFINITION'
        ), 0
    ) <> 1
        THROW 50007,
            'VIEW DEFINITION permission is required to inspect existing indexes.', 1;
 
    IF @Execute = 1
       AND ISNULL(
           HAS_PERMS_BY_NAME(
               @QualifiedTable, N'OBJECT', N'ALTER'
           ), 0
       ) <> 1
        THROW 50008,
            'ALTER permission on the target table is required.', 1;
 
    SET @KeyCount =
        1 + LEN(@Keys) - LEN(REPLACE(@Keys, N',', N''));
 
    SET @IncludeXML = CONVERT(xml,
        N'<c>' + REPLACE(@Includes, N',', N'</c><c>') + N'</c>');
 
    SET @AllColumnsXML = CONVERT(xml,
        N'<c>' + REPLACE(
            @Keys
            + CASE WHEN @Includes = N'' THEN N''
                   ELSE N',' + @Includes END,
            N',', N'</c><c>'
        ) + N'</c>');
 
    -- Verify every proposed column exists.
    IF EXISTS
    (
        SELECT 1
        FROM @AllColumnsXML.nodes('/c') AS x(n)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM sys.columns AS c
            WHERE c.object_id = @ObjectID
              AND c.name = x.n.value('.', 'sysname')
        )
    )
        THROW 50009,
            'One or more proposed columns do not exist.', 1;
 
    -- Find an enabled, unfiltered rowstore index with:
    -- 1. The proposed leading keys in the same ascending order.
    -- 2. All proposed INCLUDE columns available.
    --
    -- This checks column coverage, not equivalent performance.
    SELECT TOP (1)
        @ExistingIndex = i.name
    FROM sys.indexes AS i
    CROSS APPLY
    (
        SELECT
        (
            SELECT c.name + N','
            FROM sys.index_columns AS ic
            INNER JOIN sys.columns AS c
                ON c.object_id = ic.object_id
               AND c.column_id = ic.column_id
            WHERE ic.object_id = i.object_id
              AND ic.index_id = i.index_id
              AND ic.key_ordinal > 0
            ORDER BY ic.key_ordinal
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)') AS KeyList
    ) AS k
    WHERE i.object_id = @ObjectID
      AND i.type IN (1, 2)
      AND i.is_disabled = 0
      AND i.is_hypothetical = 0
      AND i.has_filter = 0
      AND LEFT(k.KeyList, LEN(@Keys + N',')) = @Keys + N','
      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.index_columns AS sortcol
          WHERE sortcol.object_id = i.object_id
            AND sortcol.index_id = i.index_id
            AND sortcol.key_ordinal BETWEEN 1 AND @KeyCount
            AND sortcol.is_descending_key = 1
      )
      AND
      (
          i.type = 1
          OR NOT EXISTS
          (
              SELECT 1
              FROM @IncludeXML.nodes('/c') AS x(n)
              WHERE x.n.value('.', 'sysname') <> N''
                AND NOT EXISTS
                (
                    SELECT 1
                    FROM sys.index_columns AS ic
                    INNER JOIN sys.columns AS c
                        ON c.object_id = ic.object_id
                       AND c.column_id = ic.column_id
                    INNER JOIN sys.indexes AS ci
                        ON ci.object_id = ic.object_id
                       AND ci.index_id = ic.index_id
                    WHERE ic.object_id = @ObjectID
                      AND c.name = x.n.value('.', 'sysname')
                      AND
                      (
                          ic.index_id = i.index_id
                          OR
                          (
                              ci.type = 1
                              AND ci.is_disabled = 0
                              AND ic.key_ordinal > 0
                          )
                      )
                )
          )
      )
    ORDER BY i.index_id;
 
    IF @ExistingIndex IS NOT NULL
    BEGIN
        SELECT
            N'SKIPPED: existing index provides column coverage; review performance before adding another.'
                AS Result,
            @TableName AS TableName,
            @ExistingIndex AS ExistingIndex;
    END
    ELSE
    BEGIN
        -- Never overwrite an existing same-name index.
        IF EXISTS
        (
            SELECT 1
            FROM sys.indexes
            WHERE object_id = @ObjectID
              AND name = @IndexName
        )
            THROW 50010,
                'The index name already exists. Review its definition/status; no changes made.', 1;
 
        SET @SQL =
            N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(@IndexName)
            + N' ON ' + @QualifiedTable
            + N' ([' + REPLACE(@Keys, N',', N'],[') + N'])'
            + CASE
                WHEN @Includes = N'' THEN N''
                ELSE N' INCLUDE (['
                     + REPLACE(@Includes, N',', N'],[') + N'])'
              END
            + N' WITH (MAXDOP = 2, ONLINE = OFF);';
 
        SELECT
            DB_NAME() AS DatabaseName,
            @IndexNumber AS IndexNumber,
            CASE WHEN @Execute = 1
                 THEN N'EXECUTE'
                 ELSE N'PREVIEW ONLY'
            END AS RunMode,
            @SQL AS StatementToExecute;
 
        IF @Execute = 1
        BEGIN
            -- Limits lock waiting, NOT total build time.
            SET LOCK_TIMEOUT 15000;
 
            EXEC sys.sp_executesql @SQL;
 
            SELECT
                N'CREATED' AS Result,
                @TableName AS TableName,
                @IndexName AS IndexName;
        END;
    END;
 
    SET LOCK_TIMEOUT @OriginalLockTimeout;
END TRY
BEGIN CATCH
    SET LOCK_TIMEOUT @OriginalLockTimeout;
    THROW;
END CATCH;