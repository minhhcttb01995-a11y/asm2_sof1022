// [MODEL-HEADER-ADDED]
// Bảng LỊCH PHỎNG VẤN: gắn với 1 Application (đơn ứng tuyển) cụ thể, có thời gian,
// địa điểm, ghi chú. Thuộc tính Application dùng [ValidateNever] để MVC không bắt
// buộc submit navigation property này khi validate form tạo/sửa lịch phỏng vấn.
using System;
using System.Collections.Generic;

namespace JobConnect.Models;

public partial class Interview
{
    public int InterviewId { get; set; }

    public int AppID { get; set; }

    public DateTime InterviewDate { get; set; }

    public string Location { get; set; } = null!;

    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }

    // [ValidateNever]: đây là navigation property của EF, không được (và không cần) submit từ form.
    // Vì project bật <Nullable>enable</Nullable>, ASP.NET Core mặc định coi các property
    // reference-type không-nullable là "required" khi validate model — khiến property này
    // luôn bị coi là thiếu dữ liệu và làm ModelState.IsValid = false dù người dùng đã điền đủ form.
    [Microsoft.AspNetCore.Mvc.ModelBinding.Validation.ValidateNever]
    public virtual Application Application { get; set; } = null!;

    // Compatibility alias for InterviewID
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int InterviewID
    {
        get => InterviewId;
        set => InterviewId = value;
    }

    // Backwards-compatible alias (some views/controllers use AppId)
    [System.ComponentModel.DataAnnotations.Schema.NotMapped]
    public int AppId
    {
        get => AppID;
        set => AppID = value;
    }
}
