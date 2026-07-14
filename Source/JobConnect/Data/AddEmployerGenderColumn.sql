-- Them cot Gender (Gioi tinh) va CCCD cho bang Employers
-- Database: JobConnectDB20
-- Chay script nay trong SSMS.

USE [JobConnectDB20];
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.Employers') AND name = 'Gender'
)
BEGIN
    ALTER TABLE dbo.Employers ADD Gender NVARCHAR(20) NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.Employers') AND name = 'CCCD'
)
BEGIN
    ALTER TABLE dbo.Employers ADD CCCD NVARCHAR(20) NULL;
END
GO

PRINT N'Da them cot Gender va CCCD vao bang Employers.';
GO
