# Hướng dẫn sử dụng StatusCatalog - Quản lý Trạng thái

## Tổng quan

StatusCatalog là hệ thống quản lý trạng thái tập trung cho JobConnect, cho phép Admin và Staff tùy chỉnh các trạng thái của các entity trong hệ thống một cách linh hoạt.

## Entity Types được hỗ trợ

- **Candidate** - Ứng viên
- **Employer** - Nhà tuyển dụng
- **Staff** - Nhân viên
- **Company** - Công ty
- **JobPost** - Tin tuyển dụng
- **BlogPost** - Bài viết Blog

## Cài đặt ban đầu

### 1. Chạy script seed dữ liệu

Mở SQL Server Management Studio (SSMS) và chạy file `Data/SeedStatusCatalog.sql`:

```sql
USE JobConnectDB11;
GO
-- Chạy nội dung file SeedStatusCatalog.sql
```

Script này sẽ tạo các trạng thái mặc định cho tất cả entity types.

### 2. Kiểm tra service đã được đăng ký

Service `IStatusCatalogService` đã được đăng ký trong `Program.cs`:

```csharp
builder.Services.AddScoped<IStatusCatalogService, StatusCatalogService>();
```

## Sử dụng StatusCatalog

### 1. Quản lý trạng thái (Admin/Staff)

Truy cập vào menu "Trạng thái" trong:
- Admin Panel: `/StatusCatalog`
- Staff Dashboard: `/StatusCatalog`

**Các chức năng:**
- **Thêm trạng thái mới**: Tạo trạng thái tùy chỉnh cho từng entity type
- **Sửa trạng thái**: Cập nhật tên, màu badge, thứ tự sắp xếp
- **Xóa trạng thái**: Xóa trạng thái (không áp dụng cho trạng thái hệ thống mặc định)
- **Bật/Tắt**: Tạm thời ẩn/hiện trạng thái

**Lưu ý:**
- Trạng thái hệ thống (IsSystem = true) không thể xóa
- Mã trạng thái (Code) phải là duy nhất cho mỗi entity type
- ColorClass sử dụng Tailwind CSS, ví dụ: `bg-green-100 text-green-700`

### 2. Sử dụng TagHelper hiển thị badge trạng thái

Trong các view Razor, sử dụng tag helper `<status-badge>`:

```html
<status-badge entity-type="Candidate" code="Active" />
<status-badge entity-type="JobPost" code="Open" />
<status-badge entity-type="BlogPost" code="Published" />
```

Tag helper sẽ tự động:
- Lấy thông tin từ StatusCatalog
- Áp dụng màu badge theo ColorClass
- Hiển thị tên trạng thái (Name)
- Fallback về Code nếu không tìm thấy

### 3. Thay đổi trạng thái entity trong Controller

#### AdminController

```csharp
// Đổi trạng thái người dùng
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeUserStatus(int userId, string newStatus)
{
    // Validation tự động từ StatusCatalog
    // ...
}

// Đổi trạng thái nhà tuyển dụng
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeEmployerStatus(int employerId, string newStatus)
{
    // ...
}

// Đổi trạng thái tin tuyển dụng
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeJobStatus(int jobId, string newStatus)
{
    // ...
}

// Đổi trạng thái bài viết Blog
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeBlogStatus(int postId, string newStatus)
{
    // ...
}
```

#### StaffDashboardController

```csharp
// Đổi trạng thái ứng viên
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeCandidateStatus(int profileId, string newStatus)
{
    // ...
}

// Đổi trạng thái nhà tuyển dụng
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeEmployerStatus(int employerId, string newStatus)
{
    // ...
}

// Đổi trạng thái tin tuyển dụng
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeJobStatus(int jobId, string newStatus)
{
    // ...
}

// Đổi trạng thái công ty
[HttpPost, ValidateAntiForgeryToken]
public async Task<IActionResult> ChangeCompanyStatus(int employerId, string newStatus)
{
    // ...
}
```

#### BlogController

```csharp
// Đổi trạng thái bài viết
[HttpPost, ValidateAntiForgeryToken]
[Authorize(Roles = "Admin,Staff")]
public async Task<IActionResult> ChangeStatus(int postId, string newStatus)
{
    // ...
}
```

### 4. Lấy danh sách trạng thái cho dropdown

Trong Controller:

```csharp
ViewBag.Statuses = await _db.StatusCatalogs
    .Where(s => s.EntityType == StatusEntityTypes.JobPost && s.IsActive)
    .OrderBy(s => s.SortOrder)
    .ToListAsync();
```

Trong View:

```html
<select asp-for="Status" class="form-select">
    @foreach (var status in ViewBag.Statuses)
    {
        <option value="@status.Code">@status.Name</option>
    }
</select>
```

### 5. Lấy tên hiển thị trạng thái

Sử dụng service:

```csharp
var displayName = await _statusSvc.GetDisplayNameAsync("JobPost", "Open");
// Kết quả: "Đang tuyển"
```

## Trạng thái mặc định

### Candidate (Ứng viên)
- Active - Đang hoạt động (bg-green-100 text-green-700)
- Pending - Chờ xác thực (bg-yellow-100 text-yellow-700)
- Banned - Đã khóa (bg-red-100 text-red-700)
- Inactive - Không hoạt động (bg-gray-100 text-gray-700)
- Deleted - Đã xóa (bg-gray-200 text-gray-600)

### Employer (Nhà tuyển dụng)
- Active - Đang hoạt động (bg-green-100 text-green-700)
- Pending - Chờ duyệt (bg-yellow-100 text-yellow-700)
- Verified - Đã xác minh (bg-blue-100 text-blue-700)
- Locked - Đã khóa (bg-red-100 text-red-700)
- Suspended - Tạm dừng (bg-orange-100 text-orange-700)
- Deleted - Đã xóa (bg-gray-200 text-gray-600)

### Staff (Nhân viên)
- Active - Đang làm việc (bg-green-100 text-green-700)
- OnLeave - Đang nghỉ phép (bg-yellow-100 text-yellow-700)
- Locked - Đã khóa (bg-red-100 text-red-700)
- Deleted - Đã xóa (bg-gray-200 text-gray-600)

### Company (Công ty)
- Active - Đang hoạt động (bg-green-100 text-green-700)
- Pending - Chờ duyệt (bg-yellow-100 text-yellow-700)
- Verified - Đã xác minh (bg-blue-100 text-blue-700)
- Unverified - Chưa xác minh (bg-gray-100 text-gray-700)
- Locked - Đã khóa (bg-red-100 text-red-700)
- Deleted - Đã xóa (bg-gray-200 text-gray-600)

### JobPost (Tin tuyển dụng)
- Open - Đang tuyển (bg-green-100 text-green-700)
- Pending - Chờ duyệt (bg-yellow-100 text-yellow-700)
- Approved - Đã duyệt (bg-blue-100 text-blue-700)
- Closed - Đã đóng (bg-gray-100 text-gray-700)
- Draft - Bản nháp (bg-purple-100 text-purple-700)
- Rejected - Đã từ chối (bg-red-100 text-red-700)
- Expired - Đã hết hạn (bg-orange-100 text-orange-700)
- Archived - Đã lưu trữ (bg-gray-200 text-gray-600)

### BlogPost (Bài viết Blog)
- Published - Đã xuất bản (bg-green-100 text-green-700)
- Draft - Bản nháp (bg-yellow-100 text-yellow-700)
- Pending - Chờ duyệt (bg-blue-100 text-blue-700)
- Archived - Đã lưu trữ (bg-gray-100 text-gray-700)
- Deleted - Đã xóa (bg-red-100 text-red-700)

## Validation

Tất cả các action thay đổi trạng thái đều có validation:
1. Kiểm tra trạng thái tồn tại trong StatusCatalog
2. Kiểm tra trạng thái đang active (IsActive = true)
3. Kiểm tra entity type khớp với loại đối tượng

Nếu validation thất bại, sẽ hiển thị thông báo lỗi và không thực hiện thay đổi.

## Logging

StaffDashboardController tự động ghi log khi thay đổi trạng thái:
```csharp
await LogActivityAsync(currentStaff, "CHANGE_JOB_STATUS", $"Đổi trạng thái tin tuyển dụng {jobId} thành {newStatus}");
```

## Mở rộng

### Thêm entity type mới

1. Thêm constant vào `StatusEntityTypes` trong `Models/StatusCatalog.cs`:

```csharp
public const string NewEntity = "NewEntity";
```

2. Thêm label vào dictionary:

```csharp
[NewEntity] = "Tên hiển thị mới"
```

3. Thêm vào array `All`:

```csharp
public static readonly string[] All = { Candidate, Employer, Staff, Company, JobPost, BlogPost, NewEntity };
```

4. Seed dữ liệu trong SQL script
5. Thêm controller action tương ứng

## Troubleshooting

### Badge không hiển thị đúng màu
- Kiểm tra ColorClass trong StatusCatalog
- Đảm bảo Tailwind CSS được load
- Kiểm tra tag helper đã được đăng ký trong `_ViewImports.cshtml`

### Trạng thái không được cập nhật
- Kiểm tra validation error trong TempData
- Đảm bảo trạng thái tồn tại và active trong StatusCatalog
- Kiểm tra quyền truy cập (Admin/Staff)

### Dropdown không hiển thị trạng thái
- Đảm bảo ViewBag.Statuses được set trong controller
- Kiểm tra query lọc đúng entity type và IsActive
