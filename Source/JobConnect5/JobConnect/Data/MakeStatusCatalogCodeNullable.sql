-- Make StatusCatalog.Code nullable to support auto-generation
-- Database: JobConnectDB12
-- Date: 2026-07-04

USE [JobConnectDB12];
GO

-- Drop the unique constraint temporarily
IF EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_StatusCatalog_EntityType_Code' AND parent_object_id = OBJECT_ID('StatusCatalog'))
BEGIN
    ALTER TABLE StatusCatalog DROP CONSTRAINT UQ_StatusCatalog_EntityType_Code;
END
GO

-- Make Code column nullable
ALTER TABLE StatusCatalog ALTER COLUMN Code NVARCHAR(50) NULL;
GO

-- Re-add the unique constraint (will work with NULL values - SQL Server allows multiple NULLs in unique constraint)
ALTER TABLE StatusCatalog ADD CONSTRAINT UQ_StatusCatalog_EntityType_Code UNIQUE (EntityType, Code);
GO

PRINT 'StatusCatalog.Code column is now nullable';
GO
