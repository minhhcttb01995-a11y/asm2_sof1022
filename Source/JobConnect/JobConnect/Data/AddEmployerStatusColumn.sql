-- Seed StatusCatalog for all entity types
-- Database: JobConnectDB12
-- Date: 2026-07-04

USE [JobConnectDB12];
GO

-- Clear existing StatusCatalog data (for fresh database)
DELETE FROM [StatusCatalog];
GO

-- Seed StatusCatalog for User entity
INSERT INTO [StatusCatalog] (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('User', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('User', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('User', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', 3, 1, 1);
GO

-- Seed StatusCatalog for Employer entity
INSERT INTO [StatusCatalog] (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Employer', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Employer', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Employer', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', 3, 1, 1);
GO

-- Seed StatusCatalog for JobPost entity
INSERT INTO [StatusCatalog] (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('JobPost', 'Open', N'Mở tuyển', 'bg-green-100 text-green-700', 1, 1, 1),
('JobPost', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('JobPost', 'Rejected', N'Đã từ chối', 'bg-red-100 text-red-700', 3, 1, 1),
('JobPost', 'Closed', N'Đã đóng', 'bg-gray-100 text-gray-700', 4, 1, 1),
('JobPost', 'Draft', N'Bản nháp', 'bg-blue-100 text-blue-700', 5, 1, 1);
GO

-- Seed StatusCatalog for BlogPost entity
INSERT INTO [StatusCatalog] (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('BlogPost', 'Published', N'Đã xuất bản', 'bg-green-100 text-green-700', 1, 1, 1),
('BlogPost', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('BlogPost', 'Rejected', N'Đã từ chối', 'bg-red-100 text-red-700', 3, 1, 1),
('BlogPost', 'Draft', N'Bản nháp', 'bg-blue-100 text-blue-700', 4, 1, 1);
GO

-- Seed StatusCatalog for Application entity
INSERT INTO [StatusCatalog] (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Application', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 1, 1, 1),
('Application', 'Reviewing', N'Đang xem xét', 'bg-blue-100 text-blue-700', 2, 1, 1),
('Application', 'Interview', N'Phỏng vấn', 'bg-purple-100 text-purple-700', 3, 1, 1),
('Application', 'Approved', N'Đã chấp nhận', 'bg-green-100 text-green-700', 4, 1, 1),
('Application', 'Rejected', N'Đã từ chối', 'bg-red-100 text-red-700', 5, 1, 1);
GO

-- Seed StatusCatalog for Staff entity
INSERT INTO [StatusCatalog] (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Staff', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Staff', 'OnLeave', N'Đang nghỉ phép', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Staff', 'Suspended', N'Đã đình chỉ', 'bg-red-100 text-red-700', 3, 1, 1),
('Staff', 'Resigned', N'Đã nghỉ việc', 'bg-gray-100 text-gray-700', 4, 1, 1);
GO

PRINT 'StatusCatalog seeded successfully';
GO
