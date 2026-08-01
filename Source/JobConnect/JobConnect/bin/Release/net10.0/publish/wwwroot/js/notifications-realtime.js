// ═══════════════════════════════════════════════════════════════════════════
// notifications-realtime.js — Dùng CHUNG cho mọi layout (trang công khai,
// Admin, Nhà tuyển dụng, Nhân viên). Yêu cầu mỗi layout có sẵn các phần tử:
//   #jcNotifBadge     — số chưa đọc (badge đỏ)
//   #jcNotifDropdown  — hộp dropdown chứa danh sách thông báo
//   #jcNotifList      — nơi đổ HTML danh sách thông báo (partial _NotificationDropdown)
//   button.jc-notif-trigger với onclick="jcToggleNotifDropdown()"
//
// Cơ chế REAL-TIME: kết nối SignalR tới "/hubs/notifications". Server (xem
// Data/AppDbContext.Realtime.cs) sẽ tự động bắn sự kiện "ReceiveNotification"
// xuống đúng người dùng mỗi khi có Notification mới được lưu vào DB — không
// cần đợi vòng polling 30 giây.
//
// Vẫn giữ polling 30s làm PHƯƠNG ÁN DỰ PHÒNG (fallback) cho trường hợp mất kết
// nối SignalR tạm thời (rớt mạng, proxy chặn WebSocket...).
// ═══════════════════════════════════════════════════════════════════════════
(function () {
    function refreshBadge() {
        fetch('/Notification/UnreadCount')
            .then(function (res) { return res.json(); })
            .then(function (data) {
                var badge = document.getElementById('jcNotifBadge');
                if (!badge) return;
                if (data.count > 0) {
                    badge.style.display = 'flex';
                    badge.textContent = data.count > 99 ? '99+' : data.count;
                } else {
                    badge.style.display = 'none';
                }
            })
            .catch(function () { });
    }

    function bumpBadge() {
        var badge = document.getElementById('jcNotifBadge');
        if (!badge) return;
        var current = parseInt(badge.textContent, 10);
        if (isNaN(current)) current = 0;
        var next = current + 1;
        badge.style.display = 'flex';
        badge.textContent = next > 99 ? '99+' : next;
    }

    function loadRecentIntoList() {
        var list = document.getElementById('jcNotifList');
        if (!list) return Promise.resolve();
        return fetch('/Notification/Recent')
            .then(function (res) { return res.text(); })
            .then(function (html) { list.innerHTML = html; });
    }

    function toggleDropdown() {
        var dropdown = document.getElementById('jcNotifDropdown');
        if (!dropdown) return;
        var isOpening = !dropdown.classList.contains('open');
        dropdown.classList.toggle('open');

        if (isOpening) {
            var list = document.getElementById('jcNotifList');
            if (list) {
                list.innerHTML = '<div style="padding:24px;text-align:center;color:#94a3b8;font-size:0.85rem;">Đang tải...</div>';
            }

            loadRecentIntoList()
                .then(function () {
                    var token = document.querySelector('input[name="__RequestVerificationToken"]');
                    return fetch('/Notification/MarkAllRead', {
                        method: 'POST',
                        headers: token ? { 'RequestVerificationToken': token.value } : {}
                    });
                })
                .then(function () {
                    var badge = document.getElementById('jcNotifBadge');
                    if (badge) badge.style.display = 'none';
                })
                .catch(function () {
                    var list = document.getElementById('jcNotifList');
                    if (list) list.innerHTML = '<div style="padding:24px;text-align:center;color:#ef4444;font-size:0.85rem;">Không tải được thông báo.</div>';
                });
        }
    }
    window.jcToggleNotifDropdown = toggleDropdown;

    document.addEventListener('click', function (e) {
        var dropdown = document.getElementById('jcNotifDropdown');
        var trigger = document.querySelector('.jc-notif-trigger');
        if (!dropdown) return;
        if (trigger && trigger.contains(e.target)) return;
        if (!dropdown.contains(e.target)) dropdown.classList.remove('open');
    });

    // ── Toast góc màn hình khi có thông báo mới tới real-time ──────────────
    function showRealtimeToast(notif) {
        var toast = document.createElement('div');
        toast.className = 'jc-realtime-toast';
        toast.innerHTML =
            '<div class="jc-realtime-toast-icon"><span class="material-symbols-outlined">notifications_active</span></div>' +
            '<div class="jc-realtime-toast-body">' +
                '<div class="jc-realtime-toast-title"></div>' +
                '<div class="jc-realtime-toast-content"></div>' +
            '</div>' +
            '<span class="material-symbols-outlined jc-realtime-toast-close">close</span>';

        toast.querySelector('.jc-realtime-toast-title').textContent = notif.title || 'Thông báo mới';
        toast.querySelector('.jc-realtime-toast-content').textContent = notif.content || '';

        document.body.appendChild(toast);
        requestAnimationFrame(function () { toast.classList.add('show'); });

        var autoHide = setTimeout(hideToast, 6000);

        function hideToast() {
            clearTimeout(autoHide);
            toast.classList.remove('show');
            setTimeout(function () { toast.remove(); }, 250);
        }

        toast.addEventListener('click', function (e) {
            if (e.target.classList.contains('jc-realtime-toast-close')) {
                hideToast();
                return;
            }
            hideToast();
            var dropdown = document.getElementById('jcNotifDropdown');
            if (dropdown) {
                dropdown.classList.add('open');
                loadRecentIntoList().then(function () {
                    var token = document.querySelector('input[name="__RequestVerificationToken"]');
                    fetch('/Notification/MarkAllRead', {
                        method: 'POST',
                        headers: token ? { 'RequestVerificationToken': token.value } : {}
                    }).then(function () {
                        var badge = document.getElementById('jcNotifBadge');
                        if (badge) badge.style.display = 'none';
                    });
                });
            }
        });
    }

    // ── Kết nối SignalR (real-time) ─────────────────────────────────────────
    function initRealtimeConnection() {
        if (typeof signalR === 'undefined') {
            // Thư viện SignalR chưa load được (vd: mất mạng CDN) — vẫn còn
            // polling 30s làm dự phòng nên không chặn phần còn lại của trang.
            return;
        }

        var connection = new signalR.HubConnectionBuilder()
            .withUrl('/hubs/notifications')
            .withAutomaticReconnect([0, 2000, 5000, 10000, 20000])
            .build();

        connection.on('ReceiveNotification', function (notif) {
            bumpBadge();
            showRealtimeToast(notif);

            // Nếu dropdown đang mở sẵn thì cập nhật danh sách luôn cho khớp.
            var dropdown = document.getElementById('jcNotifDropdown');
            if (dropdown && dropdown.classList.contains('open')) {
                loadRecentIntoList();
            }
        });

        connection.start().catch(function (err) {
            console.error('Không kết nối được SignalR (Notification Hub):', err);
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        if (!document.getElementById('jcNotifBadge')) return; // trang không có chuông thông báo (chưa đăng nhập)

        refreshBadge();
        setInterval(refreshBadge, 30000); // fallback polling
        initRealtimeConnection();
    });
})();
