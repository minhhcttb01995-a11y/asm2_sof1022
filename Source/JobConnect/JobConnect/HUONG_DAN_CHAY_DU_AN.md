# Hướng dẫn chạy dự án JobConnect

Dự án là website tuyển dụng viết bằng **ASP.NET Core MVC (.NET 10)**, mô hình
**Database First** (thiết kế database trước bằng SQL, model C# scaffold từ
database đó — KHÔNG dùng EF Core Migrations).

## 1. Yêu cầu cài đặt

- **.NET SDK 10.0** trở lên — kiểm tra bằng lệnh: `dotnet --version`
- **SQL Server** (SQL Server Express / Developer / LocalDB đều được) + **SQL Server
  Management Studio (SSMS)** để chạy script tạo database
- Visual Studio 2022 (17.10+) hoặc VS Code (có extension C#)

## 2. Tạo database

Toàn bộ script SQL nằm trong thư mục `JobConnect/Data/`. Mở SSMS, kết nối tới
SQL Server của bạn, rồi chạy lần lượt (theo đúng thứ tự):

1. `Data/CreateDatabase_JobConnectDB12.sql`
   → Tạo mới database `JobConnectDB12` cùng toàn bộ bảng, khóa chính/khóa ngoại.
   ⚠️ Script này sẽ **XÓA SẠCH** database cùng tên nếu đã tồn tại — chỉ chạy khi
   chắc chắn muốn làm lại từ đầu.
2. `Data/SeedData_JobConnectDB12.sql`
   → Chèn dữ liệu mẫu (tài khoản demo, tin tuyển dụng mẫu...).
3. `Data/SeedStatusCatalog.sql` và/hoặc `Data/SeedStatusCatalogData.sql`
   → Seed danh mục "Trạng thái" tùy chỉnh (StatusCatalog).

Các file còn lại (`AddEmployerGenderColumn.sql`, `AddEmployerStatusColumn.sql`,
`MakeStatusCatalogCodeNullable.sql`, `MigrateStaffStatus.sql`,
`CreateDatabaseJobConnectDB11.sql`) là các script **chỉnh sửa/di trú (migrate)**
cho phiên bản database cũ hơn (JobConnectDB11) — có thể bỏ qua nếu bạn tạo mới
hoàn toàn bằng `CreateDatabase_JobConnectDB12.sql`.

## 3. Cấu hình kết nối database

Mở file `appsettings.json`, sửa `ConnectionStrings:DefaultConnection` cho đúng
với SQL Server trên máy bạn, ví dụ:

```json
"ConnectionStrings": {
  "DefaultConnection": "Server=.\\SQLEXPRESS;Database=JobConnectDB12;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
}
```

- `Server=.\SQLEXPRESS` → thay bằng tên instance SQL Server của bạn (VD: `localhost`,
  `.\MSSQLSERVER`, hoặc tên máy như `DESKTOP-XXXX`).
- `Database=` → phải đúng tên database bạn vừa tạo ở bước 2.

⚠️ **Quan trọng về bảo mật**: file `appsettings.json` hiện đang chứa các **API
key / mật khẩu thật** (Google OAuth ClientSecret, Gemini API Key, Groq API Key,
mật khẩu Gmail gửi email). Nếu bạn định chia sẻ/đẩy code lên GitHub công khai,
**hãy đổi các key/mật khẩu này trước** và không commit file `appsettings.json`
gốc (nên đưa các giá trị nhạy cảm vào biến môi trường hoặc
`appsettings.Development.json` — file này đã được `.gitignore` ở nhiều dự án mẫu).

## 4. Các dịch vụ ngoài (tùy chọn, có thể bỏ trống nếu không cần)

Trong `appsettings.json`:

- `Authentication:Google` (ClientId/ClientSecret): cần để dùng tính năng "Đăng
  nhập bằng Google". Lấy tại https://console.cloud.google.com/apis/credentials.
- `GeminiSettings:ApiKey`: cần để dùng tính năng AI viết CV / chấm điểm phù hợp
  CV-JD (Google AI Studio: https://aistudio.google.com/apikey). Nếu để trống,
  các action liên quan sẽ trả lỗi rõ ràng thay vì crash.
- `EmailSettings`: cấu hình Gmail SMTP để gửi OTP xác thực email/quên mật khẩu.
  `SenderPassword` phải là **"Mật khẩu ứng dụng" (App Password)** của Gmail, không
  phải mật khẩu đăng nhập Gmail thường (Gmail yêu cầu bật xác thực 2 lớp trước).

## 5. Chạy dự án

### Cách 1 — dùng Visual Studio
1. Mở file `JobConnect.slnx` (hoặc mở thư mục `JobConnect/`).
2. Bấm **F5** (hoặc nút Run màu xanh) để build & chạy.

### Cách 2 — dùng dòng lệnh (Terminal)
```bash
cd JobConnect
dotnet restore
dotnet run
```

Ứng dụng sẽ chạy tại: **http://localhost:5002** (cấu hình trong
`Properties/launchSettings.json`, chỉ có profile HTTP, không có HTTPS ở local).

## 6. Đăng nhập thử

Nếu đã chạy đủ script seed data ở bước 2, sẽ có sẵn tài khoản mẫu trong
`SeedData_JobConnectDB12.sql` (mở file để xem email/mật khẩu mẫu).

Ngoài ra, khi chạy ở môi trường Development, ứng dụng có route debug:
`http://localhost:5002/gen` → trả về chuỗi hash BCrypt của mật khẩu
`Admin@123`, dùng để tự tạo/sửa tài khoản Admin trực tiếp trong SQL nếu cần
(copy chuỗi hash này vào cột `PasswordHash` của bảng `Users` bằng SSMS).

## 7. Cấu trúc thư mục chính (đã được chú thích chi tiết trong code)

```
JobConnect/
├── Program.cs            # Điểm khởi động: cấu hình DI + middleware pipeline
├── appsettings.json       # Cấu hình: connection string, API key, email...
├── Controllers/           # Xử lý HTTP request theo từng khu vực chức năng
├── Services/              # Toàn bộ logic nghiệp vụ (interface + implementation)
├── Models/                # Entity — mỗi class tương ứng 1 bảng trong database
├── ViewModels/             # DTO trung gian giữa View và Controller (form data...)
├── Data/
│   ├── AppDbContext.cs    # EF Core DbContext — cầu nối C# <-> SQL Server
│   └── *.sql              # Script tạo/seed database
├── Views/                 # Giao diện Razor (.cshtml), theo cấu trúc MVC chuẩn
├── Helpers/, Extensions/   # Hàm tiện ích dùng chung
└── wwwroot/                # File tĩnh: CSS/JS/ảnh, file upload (CV, avatar...)
```

Mỗi file `.cs` trong `Controllers/`, `Services/`, `Models/`, `Data/`,
`ViewModels/`, `Helpers/`, `Extensions/` đều đã được thêm **comment mở đầu**
giải thích file đó dùng để làm gì, và mỗi file View (`.cshtml`) có 1 dòng
comment `@* ... *@` ở đầu cho biết đây là giao diện của action/luồng nào.
