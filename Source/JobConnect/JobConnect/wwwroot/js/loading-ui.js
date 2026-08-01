/*
 * JobConnect Loading UI
 * ----------------------------------------------------------------
 * Tự động hiện hiệu ứng "đang tải" (spinner + disable nút) mỗi khi
 * người dùng bấm nút submit 1 form bất kỳ trên toàn site, trong lúc
 * chờ server xử lý (thêm/sửa/xoá dữ liệu, đăng bài, gửi form...).
 *
 * - Dùng chung thanh loading trên cùng (#jc-progress-bar) với
 *   smooth-nav.js để đồng bộ, không cần cấu hình thêm cho từng trang.
 * - Tự động BỎ QUA những form đã tự xử lý AJAX riêng bằng JS (những
 *   form gọi e.preventDefault() trong submit handler của chính trang
 *   đó) — vì khi đó trang đã tự có cách hiển thị trạng thái đang xử lý
 *   của riêng mình, tránh hiện chồng 2 spinner.
 * - Muốn 1 form KHÔNG áp dụng hiệu ứng này: thêm thuộc tính
 *   `data-no-loading` vào thẻ <form>.
 * - Các trang có JS riêng (gọi fetch thủ công) có thể dùng lại API:
 *     window.jcLoading.start()              // hiện thanh loading trên cùng
 *     window.jcLoading.finish()              // ẩn thanh loading
 *     window.jcLoading.buttonStart(btn, "Đang lưu...")  // spinner cho 1 nút
 *     window.jcLoading.buttonReset(btn)      // khôi phục nút về bình thường
 */
(function () {
    "use strict";

    function getBar() {
        var bar = document.getElementById("jc-progress-bar");
        if (!bar) {
            bar = document.createElement("div");
            bar.id = "jc-progress-bar";
            document.documentElement.appendChild(bar);
        }
        return bar;
    }

    function startBar() {
        var bar = getBar();
        bar.classList.remove("jc-done");
        bar.style.width = "0%";
        void bar.offsetWidth;
        bar.classList.add("jc-loading");
        requestAnimationFrame(function () {
            bar.style.width = "70%";
        });
    }

    function finishBar() {
        var bar = document.getElementById("jc-progress-bar");
        if (!bar) return;
        bar.style.width = "100%";
        bar.classList.add("jc-done");
        setTimeout(function () {
            bar.classList.remove("jc-loading", "jc-done");
            bar.style.width = "0%";
        }, 350);
    }

    function setButtonLoading(btn, loadingText) {
        if (!btn || btn.dataset.jcLoading === "1") return;
        btn.dataset.jcLoading = "1";
        btn.disabled = true;
        btn.classList.add("jc-btn-loading");
        if (btn.tagName === "INPUT") {
            btn.dataset.jcOriginalValue = btn.value;
            btn.value = loadingText || "Đang xử lý...";
        } else {
            btn.dataset.jcOriginalHtml = btn.innerHTML;
            btn.innerHTML = '<span class="jc-btn-spinner" aria-hidden="true"></span><span>' +
                (loadingText || "Đang xử lý...") + "</span>";
        }
    }

    function resetButtonLoading(btn) {
        if (!btn || btn.dataset.jcLoading !== "1") return;
        btn.disabled = false;
        btn.classList.remove("jc-btn-loading");
        if (btn.tagName === "INPUT") {
            if (btn.dataset.jcOriginalValue !== undefined) btn.value = btn.dataset.jcOriginalValue;
        } else if (btn.dataset.jcOriginalHtml !== undefined) {
            btn.innerHTML = btn.dataset.jcOriginalHtml;
        }
        delete btn.dataset.jcLoading;
    }

    // ---------- Tự động áp dụng cho MỌI form submit thường (không phải AJAX riêng) ----------
    document.addEventListener("submit", function (e) {
        var form = e.target;
        if (!(form instanceof HTMLFormElement)) return;
        if (form.hasAttribute("data-no-loading")) return;
        if (form.id === "authForm") return; // modal đăng nhập/đăng ký tự xử lý riêng
        if (e.defaultPrevented) return; // trang đã tự chặn để xử lý AJAX riêng -> bỏ qua

        startBar();
        var buttons = form.querySelectorAll('button[type="submit"], input[type="submit"]');
        buttons.forEach(function (btn) { setButtonLoading(btn, btn.getAttribute("data-loading-text")); });

        // An toàn: nếu 8s sau vẫn còn ở trang này (submit bị chặn bởi lỗi JS khác,
        // validate phía client chặn ngầm...) thì tự khôi phục, tránh nút bị kẹt mãi.
        setTimeout(function () {
            buttons.forEach(resetButtonLoading);
            finishBar();
        }, 8000);
    }, false);

    window.jcLoading = {
        start: startBar,
        finish: finishBar,
        buttonStart: setButtonLoading,
        buttonReset: resetButtonLoading
    };
})();
