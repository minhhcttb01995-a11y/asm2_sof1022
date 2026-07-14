-- Migration Script: Convert Staff.Status from INT to NVARCHAR(50)
-- Database: JobConnectDB12
-- Date: 2026-07-04

USE [JobConnectDB12];
GO

-- Step 1: Add temporary column for new status values
ALTER TABLE [Staff] ADD [Status_New] NVARCHAR(50) NULL;
GO

-- Step 2: Migrate data from INT to NVARCHAR based on StaffStatus enum values
-- Assuming StaffStatus enum: Active = 0, Inactive = 1, Suspended = 2, etc.
-- Adjust the mapping based on your actual enum values
UPDATE [Staff]
SET [Status_New] = CASE 
    WHEN [Status] = 0 THEN 'Active'
    WHEN [Status] = 1 THEN 'Inactive'
    WHEN [Status] = 2 THEN 'Suspended'
    WHEN [Status] = 3 THEN 'OnLeave'
    ELSE 'Unknown'
END;
GO

-- Step 3: Drop the old Status column
ALTER TABLE [Staff] DROP COLUMN [Status];
GO

-- Step 4: Rename the new column to Status
EXEC sp_rename '[Staff].[Status_New]', 'Status', 'COLUMN';
GO

-- Step 5: Make the Status column NOT NULL with default value
ALTER TABLE [Staff] ALTER COLUMN [Status] NVARCHAR(50) NOT NULL;
GO

-- Step 6: Add default constraint
ALTER TABLE [Staff] ADD CONSTRAINT [DF_Staff_Status] DEFAULT ('Active') FOR [Status];
GO

-- Step 7: Update Staff model in C# to use string instead of int
-- Change in Models/Staff.cs:
-- public string Status { get; set; } = "Active";
-- Remove or comment out the StatusEnum property

PRINT 'Migration completed successfully: Staff.Status converted from INT to NVARCHAR(50)';
GO
