-- =========================================================================================
-- Script Name: ALTER_HELPCATEGORIESQS_Drop_AutoCheckHandler_ActionType.sql
-- Description: Drops columns AutoCheckHandler and ActionType from table HELPCATEGORIESQS.
--              Includes dynamic dropping of default constraints if present.
-- Date: 2026-09-17
-- =========================================================================================

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'HELPCATEGORIESQS')
BEGIN
    -- 1. Drop Default Constraint for ActionType if exists
    DECLARE @ConstraintName NVARCHAR(200);

    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.HELPCATEGORIESQS')
      AND c.name = 'ActionType';

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [dbo].[HELPCATEGORIESQS] DROP CONSTRAINT [' + @ConstraintName + '];');
        PRINT 'Dropped default constraint: ' + @ConstraintName;
    END;

    -- 2. Drop Default Constraint for AutoCheckHandler if exists
    SET @ConstraintName = NULL;

    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.HELPCATEGORIESQS')
      AND c.name = 'AutoCheckHandler';

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [dbo].[HELPCATEGORIESQS] DROP CONSTRAINT [' + @ConstraintName + '];');
        PRINT 'Dropped default constraint: ' + @ConstraintName;
    END;

    -- 3. Drop column AutoCheckHandler if exists
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HELPCATEGORIESQS') AND name = 'AutoCheckHandler')
    BEGIN
        ALTER TABLE [dbo].[HELPCATEGORIESQS] DROP COLUMN [AutoCheckHandler];
        PRINT 'Dropped column AutoCheckHandler from HELPCATEGORIESQS.';
    END;

    -- 4. Drop column ActionType if exists
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.HELPCATEGORIESQS') AND name = 'ActionType')
    BEGIN
        ALTER TABLE [dbo].[HELPCATEGORIESQS] DROP COLUMN [ActionType];
        PRINT 'Dropped column ActionType from HELPCATEGORIESQS.';
    END;
END
GO
