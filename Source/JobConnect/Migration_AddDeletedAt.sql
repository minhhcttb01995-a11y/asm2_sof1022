-- Chạy script này nếu database đã tồn tại từ trước (không cần chạy nếu tạo DB mới từ Database.sql)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[Users]') AND name = 'DeletedAt'
)
BEGIN
    ALTER TABLE [Users] ADD [DeletedAt] datetime2 NULL;
END
GO
