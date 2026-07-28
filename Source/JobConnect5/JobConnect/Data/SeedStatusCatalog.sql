-- =========================================================
-- JobConnectDB11 - SEED STATUS CATALOG DATA
-- Script này tạo dữ liệu mặc định cho bảng StatusCatalog
-- =========================================================

USE JobConnectDB11;
GO

-- Xóa dữ liệu cũ (nếu có)
DELETE FROM StatusCatalog;
GO

-- ================= CANDIDATE STATUSES =================
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Candidate', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Candidate', 'Pending', N'Chờ xác thực', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Candidate', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', 3, 1, 1),
('Candidate', 'Inactive', N'Không hoạt động', 'bg-gray-100 text-gray-700', 4, 1, 1),
('Candidate', 'Deleted', N'Đã xóa', 'bg-gray-200 text-gray-600', 5, 1, 1);
GO

-- ================= EMPLOYER STATUSES =================
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Employer', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Employer', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Employer', 'Verified', N'Đã xác minh', 'bg-blue-100 text-blue-700', 3, 1, 1),
('Employer', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', 4, 1, 1),
('Employer', 'Suspended', N'Tạm dừng', 'bg-orange-100 text-orange-700', 5, 1, 1),
('Employer', 'Deleted', N'Đã xóa', 'bg-gray-200 text-gray-600', 6, 1, 1);
GO

-- ================= STAFF STATUSES =================
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Staff', 'Active', N'Đang làm việc', 'bg-green-100 text-green-700', 1, 1, 1),
('Staff', 'OnLeave', N'Đang nghỉ phép', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Staff', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', 3, 1, 1),
('Staff', 'Deleted', N'Đã xóa', 'bg-gray-200 text-gray-600', 4, 1, 1);
GO

-- ================= COMPANY STATUSES =================
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('Company', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Company', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Company', 'Verified', N'Đã xác minh', 'bg-blue-100 text-blue-700', 3, 1, 1),
('Company', 'Unverified', N'Chưa xác minh', 'bg-gray-100 text-gray-700', 4, 1, 1),
('Company', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', 5, 1, 1),
('Company', 'Deleted', N'Đã xóa', 'bg-gray-200 text-gray-600', 6, 1, 1);
GO

-- ================= JOB POST STATUSES =================
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('JobPost', 'Open', N'Đang tuyển', 'bg-green-100 text-green-700', 1, 1, 1),
('JobPost', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('JobPost', 'Approved', N'Đã duyệt', 'bg-blue-100 text-blue-700', 3, 1, 1),
('JobPost', 'Closed', N'Đã đóng', 'bg-gray-100 text-gray-700', 4, 1, 1),
('JobPost', 'Draft', N'Bản nháp', 'bg-purple-100 text-purple-700', 5, 1, 1),
('JobPost', 'Rejected', N'Đã từ chối', 'bg-red-100 text-red-700', 6, 1, 1),
('JobPost', 'Expired', N'Đã hết hạn', 'bg-orange-100 text-orange-700', 7, 1, 1),
('JobPost', 'Archived', N'Đã lưu trữ', 'bg-gray-200 text-gray-600', 8, 1, 1);
GO

-- ================= BLOG POST STATUSES =================
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
('BlogPost', 'Published', N'Đã xuất bản', 'bg-green-100 text-green-700', 1, 1, 1),
('BlogPost', 'Draft', N'Bản nháp', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('BlogPost', 'Pending', N'Chờ duyệt', 'bg-blue-100 text-blue-700', 3, 1, 1),
('BlogPost', 'Archived', N'Đã lưu trữ', 'bg-gray-100 text-gray-700', 4, 1, 1),
('BlogPost', 'Deleted', N'Đã xóa', 'bg-red-100 text-red-700', 5, 1, 1);
GO

-- Kiểm tra kết quả
SELECT EntityType, COUNT(*) AS StatusCount 
FROM StatusCatalog 
GROUP BY EntityType 
ORDER BY EntityType;
GO

PRINT 'Đã seed dữ liệu StatusCatalog thành công!';
GO
