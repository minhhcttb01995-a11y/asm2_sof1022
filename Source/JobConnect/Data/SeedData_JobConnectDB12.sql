-- Seed Data for JobConnectDB12
-- Run after CreateDatabase_JobConnectDB12.sql and AddEmployerStatusColumn.sql

USE [JobConnectDB12];
GO

-- 1. USERS (Admin + 20 Staff + 20 Employers + 20 Candidates = 61 users)
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('admin@jobconnect.vn', '$2a$12$xEdibtJ6BHiCSdnXA9EWK.fSTt/Zi8Op3YdzvtyzBDOXxIabpHEgS', 'Admin', N'Quản Trị Viên', '0901000001', 'Active');
GO

-- Staff (20)
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('staff01@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Nguyễn Thị Hà', '0901000010', 'Active'),
('staff02@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Trần Văn Bảo', '0901000011', 'Active'),
('staff03@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Lê Thị Cúc', '0901000012', 'Active'),
('staff04@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Phạm Văn Dũng', '0901000013', 'Active'),
('staff05@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Hoàng Thị Em', '0901000014', 'Active'),
('staff06@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Vũ Văn Phát', '0901000015', 'Active'),
('staff07@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Đặng Thị Giang', '0901000016', 'Active'),
('staff08@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Bùi Văn Hải', '0901000017', 'Active'),
('staff09@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Ngô Thị Ích', '0901000018', 'Active'),
('staff10@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Đỗ Văn Khang', '0901000019', 'Active'),
('staff11@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Đinh Thị Lan', '0901000020', 'Active'),
('staff12@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Trương Văn Minh', '0901000021', 'Active'),
('staff13@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Lý Thị Ngọc', '0901000022', 'Active'),
('staff14@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Phan Văn Oai', '0901000023', 'Active'),
('staff15@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Tô Thị Phượng', '0901000024', 'Active'),
('staff16@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Cao Văn Quang', '0901000025', 'Active'),
('staff17@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Hà Thị Rin', '0901000026', 'Active'),
('staff18@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Lương Văn Sinh', '0901000027', 'Active'),
('staff19@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Trịnh Thị Thảo', '0901000028', 'Active'),
('staff20@jobconnect.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Staff', N'Dương Văn Út', '0901000029', 'Active');
GO

-- Employers (20)
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('employer01@company1.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Nguyễn Văn An', '0901111001', 'Active'),
('employer02@company2.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Trần Thị Bình', '0901111002', 'Active'),
('employer03@company3.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Lê Minh Cường', '0901111003', 'Active'),
('employer04@company4.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Phạm Thị Dung', '0901111004', 'Active'),
('employer05@company5.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Hoàng Văn Em', '0901111005', 'Active'),
('employer06@company6.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Vũ Thị Phương', '0901111006', 'Active'),
('employer07@company7.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đặng Văn Giàu', '0901111007', 'Active'),
('employer08@company8.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Bùi Thị Hoa', '0901111008', 'Active'),
('employer09@company9.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Ngô Văn Inh', '0901111009', 'Active'),
('employer10@company10.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đỗ Thị Kim', '0901111010', 'Active'),
('employer11@company11.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Đinh Văn Long', '0901111011', 'Active'),
('employer12@company12.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Trương Thị Mỹ', '0901111012', 'Active'),
('employer13@company13.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Lý Văn Nghĩa', '0901111013', 'Active'),
('employer14@company14.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Phan Thị Oanh', '0901111014', 'Active'),
('employer15@company15.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Tô Văn Phú', '0901111015', 'Active'),
('employer16@company16.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Cao Thị Quyên', '0901111016', 'Active'),
('employer17@company17.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Hà Văn Rồng', '0901111017', 'Active'),
('employer18@company18.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Lương Thị Sang', '0901111018', 'Active'),
('employer19@company19.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Trịnh Văn Tài', '0901111019', 'Active'),
('employer20@company20.vn', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Employer', N'Dương Thị Uyên', '0901111020', 'Active');
GO

-- Candidates (20)
INSERT INTO Users (Email, PasswordHash, Role, FullName, PhoneNumber, Status) VALUES
('candidate01@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đỗ Thị Phương', '0912000001', 'Active'),
('candidate02@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Vũ Quang Huy', '0912000002', 'Active'),
('candidate03@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Ngô Thị Lan', '0912000003', 'Active'),
('candidate04@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Bùi Văn Khoa', '0912000004', 'Active'),
('candidate05@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lý Thị Mai', '0912000005', 'Active'),
('candidate06@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Đinh Văn Nam', '0912000006', 'Active'),
('candidate07@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Phan Thị Oanh', '0912000007', 'Active'),
('candidate08@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Tô Minh Phúc', '0912000008', 'Active'),
('candidate09@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Cao Thị Quỳnh', '0912000009', 'Active'),
('candidate10@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Hà Văn Sơn', '0912000010', 'Active'),
('candidate11@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lương Thị Trang', '0912000011', 'Active'),
('candidate12@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Mai Văn Uy', '0912000012', 'Active'),
('candidate13@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Trịnh Thị Vân', '0912000013', 'Active'),
('candidate14@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Dương Văn Xuân', '0912000014', 'Active'),
('candidate15@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Nguyễn Thị Yến', '0912000015', 'Active'),
('candidate16@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Trần Văn Ánh', '0912000016', 'Active'),
('candidate17@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Lê Thị Bích', '0912000017', 'Active'),
('candidate18@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Phạm Văn Cảnh', '0912000018', 'Active'),
('candidate19@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Hoàng Thị Duyên', '0912000019', 'Active'),
('candidate20@gmail.com', '$2a$12$qHYQz/8TrI66IHqV8UG0d.B6e/VTTu7le6mUSJm5EDt3YyT.uErhC', 'Candidate', N'Vũ Văn Giang', '0912000020', 'Active');
GO

-- 2. STAFF (20) - Status changed from int to string
INSERT INTO Staff (ApplicationUserId, EmployeeCode, CCCD, FullName, Email, Phone, Gender, Position, Department, Status) VALUES
(2, 'EMP-002', '030099056000', N'Nguyễn Thị Hà', 'staff01@jobconnect.vn', '0901000010', N'Nữ', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(3, 'EMP-003', '031099056037', N'Trần Văn Bảo', 'staff02@jobconnect.vn', '0901000011', N'Nam', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(4, 'EMP-004', '032099056074', N'Lê Thị Cúc', 'staff03@jobconnect.vn', '0901000012', N'Nữ', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(5, 'EMP-005', '033099056111', N'Phạm Văn Dũng', 'staff04@jobconnect.vn', '0901000013', N'Nam', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(6, 'EMP-006', '034099056148', N'Hoàng Thị Em', 'staff05@jobconnect.vn', '0901000014', N'Nữ', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(7, 'EMP-007', '035099056185', N'Vũ Văn Phát', 'staff06@jobconnect.vn', '0901000015', N'Nam', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(8, 'EMP-008', '036099056222', N'Đặng Thị Giang', 'staff07@jobconnect.vn', '0901000016', N'Nữ', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(9, 'EMP-009', '037099056259', N'Bùi Văn Hải', 'staff08@jobconnect.vn', '0901000017', N'Nam', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(10, 'EMP-010', '038099056296', N'Ngô Thị Ích', 'staff09@jobconnect.vn', '0901000018', N'Nữ', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(11, 'EMP-011', '039099056333', N'Đỗ Văn Khang', 'staff10@jobconnect.vn', '0901000019', N'Nam', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(12, 'EMP-012', '040099056370', N'Đinh Thị Lan', 'staff11@jobconnect.vn', '0901000020', N'Nữ', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(13, 'EMP-013', '041099056407', N'Trương Văn Minh', 'staff12@jobconnect.vn', '0901000021', N'Nam', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(14, 'EMP-014', '042099056444', N'Lý Thị Ngọc', 'staff13@jobconnect.vn', '0901000022', N'Nữ', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(15, 'EMP-015', '043099056481', N'Phan Văn Oai', 'staff14@jobconnect.vn', '0901000023', N'Nam', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(16, 'EMP-016', '044099056518', N'Tô Thị Phượng', 'staff15@jobconnect.vn', '0901000024', N'Nữ', N'Chuyên viên vận hành', N'Kinh doanh', 'Active'),
(17, 'EMP-017', '045099056555', N'Cao Văn Quang', 'staff16@jobconnect.vn', '0901000025', N'Nam', N'Chuyên viên tuyển dụng', N'Nhân sự', 'Active'),
(18, 'EMP-018', '046099056592', N'Hà Thị Rin', 'staff17@jobconnect.vn', '0901000026', N'Nữ', N'Chuyên viên hỗ trợ', N'Chăm sóc KH', 'Active'),
(19, 'EMP-019', '047099056629', N'Lương Văn Sinh', 'staff18@jobconnect.vn', '0901000027', N'Nam', N'Trưởng nhóm CSKH', N'Kiểm duyệt nội dung', 'Active'),
(20, 'EMP-020', '048099056666', N'Trịnh Thị Thảo', 'staff19@jobconnect.vn', '0901000028', N'Nữ', N'Chuyên viên kiểm duyệt', N'Vận hành hệ thống', 'Active'),
(21, 'EMP-021', '049099056703', N'Dương Văn Út', 'staff20@jobconnect.vn', '0901000029', N'Nam', N'Chuyên viên vận hành', N'Kinh doanh', 'Active');
GO

-- 3. CATEGORIES (20)
INSERT INTO Categories (ParentID, Name, Type, Slug, Description) VALUES
(NULL, N'Công nghệ thông tin', 'Industry', 'cong-nghe-thong-tin', N'Ngành IT, phần mềm, lập trình'),
(NULL, N'Tài chính - Kế toán', 'Industry', 'tai-chinh-ke-toan', N'Ngành tài chính, ngân hàng, kế toán'),
(NULL, N'Marketing - Truyền thông', 'Industry', 'marketing-truyen-thong', N'Ngành marketing, quảng cáo'),
(NULL, N'Kinh doanh - Bán hàng', 'Industry', 'kinh-doanh-ban-hang', N'Ngành sales, kinh doanh'),
(NULL, N'Nhân sự - Hành chính', 'Industry', 'nhan-su-hanh-chinh', N'Ngành HR, hành chính'),
(NULL, N'Sản xuất - Vận hành', 'Industry', 'san-xuat-van-hanh', N'Ngành sản xuất, vận hành nhà máy'),
(NULL, N'Vận tải - Logistics', 'Industry', 'van-tai-logistics', N'Ngành vận tải, kho vận'),
(NULL, N'Y tế - Dược phẩm', 'Industry', 'y-te-duoc-pham', N'Ngành y tế, chăm sóc sức khỏe'),
(1, N'Backend Developer', 'JobType', 'backend-developer', N'Lập trình viên backend'),
(1, N'Frontend Developer', 'JobType', 'frontend-developer', N'Lập trình viên frontend'),
(1, N'DevOps / Cloud', 'JobType', 'devops-cloud', N'DevOps, Cloud engineer'),
(1, N'Mobile Developer', 'JobType', 'mobile-developer', N'Lập trình viên di động'),
(1, N'Data Engineer / Analyst', 'JobType', 'data-engineer-analyst', N'Kỹ sư/Chuyên viên dữ liệu'),
(2, N'Kế toán tổng hợp', 'JobType', 'ke-toan-tong-hop', N'Kế toán tổng hợp'),
(2, N'Chuyên viên tài chính', 'JobType', 'chuyen-vien-tai-chinh', N'Chuyên viên phân tích tài chính'),
(3, N'Digital Marketing', 'JobType', 'digital-marketing', N'Digital Marketing specialist'),
(3, N'Content Creator', 'JobType', 'content-creator', N'Sáng tạo nội dung'),
(4, N'Nhân viên kinh doanh', 'JobType', 'nhan-vien-kinh-doanh', N'Sales, kinh doanh'),
(5, N'Chuyên viên tuyển dụng', 'JobType', 'chuyen-vien-tuyen-dung', N'Tuyển dụng nhân sự'),
(5, N'Hành chính nhân sự', 'JobType', 'hanh-chinh-nhan-su', N'Hành chính - Nhân sự tổng hợp');
GO

-- 4. SKILLS (20)
INSERT INTO Skills (Name, Description, CategoryID, IsActive) VALUES
(N'C#', N'Ngôn ngữ lập trình C#', 1, 1),
(N'Java', N'Ngôn ngữ lập trình Java', 1, 1),
(N'Python', N'Ngôn ngữ lập trình Python', 1, 1),
(N'ReactJS', N'Thư viện JavaScript ReactJS', 1, 1),
(N'Angular', N'Framework Angular', 1, 1),
(N'SQL Server', N'Hệ quản trị cơ sở dữ liệu SQL Server', 1, 1),
(N'Docker', N'Công nghệ container Docker', 1, 1),
(N'Kubernetes', N'Công nghệ điều phối container', 1, 1),
(N'Node.js', N'Môi trường chạy JavaScript phía server', 1, 1),
(N'AWS', N'Nền tảng điện toán đám mây Amazon', 1, 1),
(N'Excel nâng cao', N'Kỹ năng Excel nâng cao', 2, 1),
(N'Phân tích tài chính', N'Kỹ năng phân tích báo cáo tài chính', 2, 1),
(N'Google Ads', N'Quảng cáo Google Ads', 3, 1),
(N'SEO', N'Tối ưu hóa công cụ tìm kiếm', 3, 1),
(N'Facebook Ads', N'Quảng cáo Facebook Ads', 3, 1),
(N'Đàm phán', N'Kỹ năng đàm phán kinh doanh', 4, 1),
(N'Chăm sóc khách hàng', N'Kỹ năng chăm sóc khách hàng', 4, 1),
(N'Tuyển dụng', N'Kỹ năng tuyển dụng nhân sự', 5, 1),
(N'Quản lý dự án', N'Kỹ năng quản lý dự án', 1, 1),
(N'Kiểm thử phần mềm', N'Kỹ năng kiểm thử phần mềm (QA/QC)', 1, 1);
GO

-- 5. EMPLOYERS (20, UserId 22-41)
INSERT INTO Employers (UserId, CompanyName, TaxCode, Industry, CompanySize, Address, Website, IsVerified, Status, Description) VALUES
(22, N'FPT Software', '0101248141', N'Công nghệ thông tin', '1000+', N'Tòa nhà FPT, Hà Nội', 'https://fptsoftware.com', 1, 'Active', N'Công ty phần mềm hàng đầu Việt Nam'),
(23, N'VNG Corporation', '0309936024', N'Công nghệ thông tin', '1000+', N'Tòa nhà VNG, TP. Hồ Chí Minh', 'https://vng.com.vn', 1, 'Active', N'Tập đoàn công nghệ VNG - ZaloPay, Zalo'),
(24, N'MoMo (M_Service)', '0309166941', N'Fintech', '500-1000', N'Quận 3, TP. Hồ Chí Minh', 'https://momo.vn', 1, 'Active', N'Ví điện tử MoMo hàng đầu Việt Nam'),
(25, N'Tiki Corporation', '0312425758', N'Thương mại điện tử', '500-1000', N'Quận 10, TP. Hồ Chí Minh', 'https://tiki.vn', 1, 'Active', N'Sàn thương mại điện tử Tiki'),
(26, N'Shopee Vietnam', '0312992108', N'Thương mại điện tử', '1000+', N'Quận 4, TP. Hồ Chí Minh', 'https://shopee.vn', 1, 'Active', N'Sàn thương mại điện tử Shopee'),
(27, N'Viettel Group', '0100109106', N'Viễn thông', '1000+', N'Cầu Giấy, Hà Nội', 'https://viettel.com.vn', 1, 'Active', N'Tập đoàn viễn thông quân đội Viettel'),
(28, N'Vinamilk', '0300588569', N'Thực phẩm - Đồ uống', '1000+', N'Quận 7, TP. Hồ Chí Minh', 'https://vinamilk.com.vn', 1, 'Active', N'Công ty sữa hàng đầu Việt Nam'),
(29, N'Techcombank', '0100230800', N'Ngân hàng - Tài chính', '1000+', N'Hoàn Kiếm, Hà Nội', 'https://techcombank.com.vn', 1, 'Active', N'Ngân hàng TMCP Kỹ Thương Việt Nam'),
(30, N'Vingroup', '0201888569', N'Bất động sản', '1000+', N'Long Biên, Hà Nội', 'https://vingroup.net', 1, 'Active', N'Tập đoàn đa ngành hàng đầu Việt Nam'),
(31, N'Grab Vietnam', '0313818500', N'Công nghệ - Vận tải', '500-1000', N'Quận 1, TP. Hồ Chí Minh', 'https://grab.com/vn', 1, 'Active', N'Nền tảng gọi xe công nghệ Grab'),
(32, N'CMC Corporation', '0101519718', N'Công nghệ thông tin', '500-1000', N'Cầu Giấy, Hà Nội', 'https://cmc.com.vn', 1, 'Active', N'Tập đoàn công nghệ CMC'),
(33, N'Masan Group', '0303576146', N'Hàng tiêu dùng', '1000+', N'Quận 1, TP. Hồ Chí Minh', 'https://masangroup.com', 1, 'Active', N'Tập đoàn hàng tiêu dùng Masan'),
(34, N'Sacombank', '0301103908', N'Ngân hàng - Tài chính', '1000+', N'Quận 3, TP. Hồ Chí Minh', 'https://sacombank.com.vn', 1, 'Active', N'Ngân hàng TMCP Sài Gòn Thương Tín'),
(35, N'Vietjet Air', '0309282045', N'Hàng không', '500-1000', N'Tân Bình, TP. Hồ Chí Minh', 'https://vietjetair.com', 1, 'Active', N'Hãng hàng không Vietjet'),
(36, N'NashTech Vietnam', '0106983946', N'Công nghệ thông tin', '500-1000', N'Đống Đa, Hà Nội', 'https://nashtechglobal.com', 1, 'Active', N'Công ty phần mềm NashTech'),
(37, N'KMS Technology', '0313164851', N'Công nghệ thông tin', '100-500', N'Quận 3, TP. Hồ Chí Minh', 'https://kms-technology.com', 1, 'Active', N'Công ty phần mềm KMS Technology'),
(38, N'Axon Active Vietnam', '0313018800', N'Công nghệ thông tin', '100-500', N'Quận 3, TP. Hồ Chí Minh', 'https://axonactive.com', 1, 'Active', N'Công ty phần mềm Thụy Sĩ Axon Active'),
(39, N'TMA Solutions', '0300123456', N'Công nghệ thông tin', '1000+', N'Tân Bình, TP. Hồ Chí Minh', 'https://tmasolutions.com', 1, 'Active', N'Công ty gia công phần mềm TMA'),
(40, N'VinFast', '0201888588', N'Sản xuất ô tô', '1000+', N'Hải Phòng', 'https://vinfast.vn', 1, 'Active', N'Công ty sản xuất ô tô điện VinFast'),
(41, N'Be Group', '0314727627', N'Công nghệ - Vận tải', '500-1000', N'Quận 10, TP. Hồ Chí Minh', 'https://be.com.vn', 1, 'Active', N'Nền tảng gọi xe công nghệ Be');
GO

PRINT 'Seed data completed successfully';
GO
