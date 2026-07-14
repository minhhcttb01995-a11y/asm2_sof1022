/* =========================================================
   JobConnectDB11 - SEED STATUS CATALOG DATA
   Seed du lieu cho bang StatusCatalog
   ========================================================= */
USE JobConnectDB11;
GO

SET NOCOUNT ON;

/* ================= STATUS CATALOG DATA ================= */
INSERT INTO StatusCatalog (EntityType, Code, Name, ColorClass, SortOrder, IsActive, IsSystem) VALUES
-- Candidate
('Candidate', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Candidate', 'Pending', N'Chờ xác thực', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Candidate', 'Banned', N'Đã khóa', 'bg-red-100 text-red-700', 3, 1, 1),
('Candidate', 'Inactive', N'Không hoạt động', 'bg-gray-100 text-gray-700', 4, 1, 1),
('Candidate', 'Deleted', N'Đã xóa', 'bg-gray-100 text-gray-700', 5, 0, 1),

-- Employer
('Employer', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Employer', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Employer', 'Verified', N'Đã xác minh', 'bg-blue-100 text-blue-700', 3, 1, 1),
('Employer', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', 4, 1, 1),
('Employer', 'Suspended', N'Tạm dừng', 'bg-orange-100 text-orange-700', 5, 1, 1),
('Employer', 'Deleted', N'Đã xóa', 'bg-gray-100 text-gray-700', 6, 0, 1),

-- Staff
('Staff', 'Active', N'Đang làm việc', 'bg-green-100 text-green-700', 1, 1, 1),
('Staff', 'OnLeave', N'Đang nghỉ phép', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Staff', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', 3, 1, 1),
('Staff', 'Deleted', N'Đã xóa', 'bg-gray-100 text-gray-700', 4, 0, 1),

-- Company
('Company', 'Active', N'Đang hoạt động', 'bg-green-100 text-green-700', 1, 1, 1),
('Company', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('Company', 'Verified', N'Đã xác minh', 'bg-blue-100 text-blue-700', 3, 1, 1),
('Company', 'Locked', N'Đã khóa', 'bg-red-100 text-red-700', 4, 1, 1),
('Company', 'Deleted', N'Đã xóa', 'bg-gray-100 text-gray-700', 5, 0, 1),

-- JobPost
('JobPost', 'Open', N'Đang tuyển', 'bg-green-100 text-green-700', 1, 1, 1),
('JobPost', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 2, 1, 1),
('JobPost', 'Approved', N'Đã duyệt', 'bg-blue-100 text-blue-700', 3, 1, 1),
('JobPost', 'Closed', N'Đã đóng', 'bg-gray-100 text-gray-700', 4, 1, 1),
('JobPost', 'Draft', N'Bản nháp', 'bg-gray-100 text-gray-700', 5, 1, 1),
('JobPost', 'Rejected', N'Đã từ chối', 'bg-red-100 text-red-700', 6, 1, 1),
('JobPost', 'Expired', N'Đã hết hạn', 'bg-orange-100 text-orange-700', 7, 1, 1),
('JobPost', 'Archived', N'Đã lưu trữ', 'bg-gray-100 text-gray-700', 8, 0, 1),

-- BlogPost
('BlogPost', 'Published', N'Đã xuất bản', 'bg-green-100 text-green-700', 1, 1, 1),
('BlogPost', 'Draft', N'Bản nháp', 'bg-gray-100 text-gray-700', 2, 1, 1),
('BlogPost', 'Pending', N'Chờ duyệt', 'bg-yellow-100 text-yellow-700', 3, 1, 1),
('BlogPost', 'Archived', N'Đã lưu trữ', 'bg-gray-100 text-gray-700', 4, 0, 1),
('BlogPost', 'Deleted', N'Đã xóa', 'bg-gray-100 text-gray-700', 5, 0, 1);
GO

-- Kiem tra du lieu da seed
SELECT EntityType, Code, Name, IsActive, IsSystem 
FROM StatusCatalog 
ORDER BY EntityType, SortOrder;
GO
