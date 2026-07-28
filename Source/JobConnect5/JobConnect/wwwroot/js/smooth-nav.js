/*
 * JobConnect Smooth Navigation
 * ----------------------------------------------------------------
 * Biến toàn bộ site (Public / Employer / Admin layout) thành kiểu
 * điều hướng "AJAX" (giống pjax/Turbolinks): khi bấm 1 link nội bộ,
 * script sẽ tự fetch trang đích, chỉ thay phần nội dung bên trong
 * [data-jc-content], giữ nguyên header/sidebar/menu, có hiệu ứng
 * mờ dần mượt mà + thanh loading ở trên cùng, thay vì load lại
 * (refresh) toàn bộ trang.
 *
 * - Hỗ trợ nút Back/Forward của trình duyệt (History API).
 * - Tự cập nhật <title>, tiêu đề trang trong dashboard, trạng thái
 *   active của menu.
 * - Tự thực thi lại các <script> nằm trong nội dung mới tải.
 * - Bỏ qua: link ngoại vi (khác domain), link có target="_blank",
 *   link tải file (download), link có data-no-ajax, mailto:, tel:,
 *   link chỉ có "#", hoặc khi giữ phím Ctrl/Shift/Alt/Meta khi bấm.
 */
(function () {
    "use strict";

    var CONTENT_SELECTOR = "[data-jc-content]";
    var SCRIPTS_CONTAINER_ID = "jc-page-scripts";
    var currentController = null;

    // ---------- Thanh loading trên cùng ----------
    var bar = document.createElement("div");
    bar.id = "jc-progress-bar";
    document.addEventListener("DOMContentLoaded", function () {
        if (!document.getElementById("jc-progress-bar")) {
            document.body.appendChild(bar);
        }
    });
    // Nếu DOM đã sẵn sàng (script đặt cuối trang) thì thêm luôn
    if (document.readyState === "interactive" || document.readyState === "complete") {
        if (!document.getElementById("jc-progress-bar")) {
            document.documentElement.appendChild(bar);
        }
    }

    var progressTimer = null;
    function startProgress() {
        clearTimeout(progressTimer);
        bar.classList.remove("jc-done");
        bar.style.width = "0%";
        // ép reflow để transition chạy lại từ 0
        void bar.offsetWidth;
        bar.classList.add("jc-loading");
        requestAnimationFrame(function () {
            bar.style.width = "70%";
        });
        document.documentElement.classList.add("jc-navigating");
    }

    function finishProgress(ok) {
        document.documentElement.classList.remove("jc-navigating");
        bar.style.width = "100%";
        bar.classList.add("jc-done");
        progressTimer = setTimeout(function () {
            bar.classList.remove("jc-loading", "jc-done");
            bar.style.width = "0%";
        }, 350);
    }

    // ---------- Helpers ----------
    function isSameOrigin(url) {
        try {
            var u = new URL(url, window.location.href);
            return u.origin === window.location.origin;
        } catch (e) {
            return false;
        }
    }

    function shouldIntercept(anchor, evt) {
        if (!anchor || !anchor.href) return false;
        if (evt.defaultPrevented) return false;
        if (evt.button !== 0) return false; // chỉ chuột trái
        if (evt.metaKey || evt.ctrlKey || evt.shiftKey || evt.altKey) return false;
        if (anchor.target && anchor.target !== "" && anchor.target !== "_self") return false;
        if (anchor.hasAttribute("download")) return false;
        if (anchor.hasAttribute("data-no-ajax")) return false;
        if (anchor.hasAttribute("onclick")) return false;
        if (anchor.getAttribute("rel") === "external") return false;
        var href = anchor.getAttribute("href");
        if (!href || href.charAt(0) === "#") return false;
        if (href.indexOf("mailto:") === 0 || href.indexOf("tel:") === 0 || href.indexOf("javascript:") === 0) return false;
        if (!isSameOrigin(anchor.href)) return false;

        var targetUrl = new URL(anchor.href, window.location.href);
        var currentUrl = new URL(window.location.href);
        if (targetUrl.pathname === currentUrl.pathname && targetUrl.search === currentUrl.search && targetUrl.hash) {
            return false; // chỉ nhảy anchor trong cùng trang
        }
        return true;
    }

    // Bọc nội dung <script> inline trong 1 IIFE trước khi cho chạy lại.
    // Lý do: các script inline trong view thường khai báo biến top-level bằng
    // const/let (vd "const titleInput = ..."). Vì trang KHÔNG được load lại
    // (chỉ thay [data-jc-content]) nên window/global scope vẫn giữ nguyên giữa
    // các lần điều hướng. Nếu người dùng rời trang rồi quay lại, script sẽ được
    // chạy lại y hệt lần nữa và cố khai báo lại const/let CÙNG TÊN vào global
    // scope đã có sẵn từ lần trước -> "Uncaught SyntaxError: Identifier 'x' has
    // already been declared" -> toàn bộ script bị dừng ngay khi parse, không
    // dòng nào chạy cả (mất hết chức năng JS của trang: Quill không init, form
    // validate/submit không gắn sự kiện...). Đây chính là bug "lúc đầu vẫn hiện
    // ra nhưng quay lại thì lỗi".
    //
    // Bọc trong IIFE giúp const/let chỉ tồn tại trong scope riêng của mỗi lần
    // chạy, không còn đụng độ. Với các "function ten(...)" khai báo top-level
    // (thường được gọi từ onclick="..." trong HTML nên cần có trên window), ta
    // tự động gán lại ra window sau khi IIFE chạy xong để không bị "biến mất".
    function wrapInlineScript(code) {
        var fnNames = [];
        var fnRegex = /(?:^|\n)\s*(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(/g;
        var m;
        while ((m = fnRegex.exec(code)) !== null) {
            fnNames.push(m[1]);
        }
        var exposeLines = fnNames.map(function (n) {
            return 'try { window.' + n + ' = ' + n + '; } catch (e) {}';
        }).join('\n');

        return '(function () {\n' + code + '\n' + exposeLines + '\n})();';
    }

    function executeScripts(container) {
        // Chạy TUẦN TỰ theo đúng thứ tự trong DOM: nếu 1 <script src="..."> (file
        // ngoài, vd quill.js) thì phải đợi tải xong rồi mới chạy script tiếp theo.
        // Trước đây script src được chèn lại rồi chạy bất đồng bộ song song với các
        // <script> inline phía sau, nên code inline (vd khởi tạo Quill) có thể chạy
        // TRƯỚC khi file quill.js tải xong -> lỗi "Quill is not defined" ngẫu nhiên
        // chỉ xảy ra khi chuyển trang bằng link (AJAX nav), không xảy ra khi F5.
        var scripts = Array.prototype.slice.call(container.querySelectorAll("script"));

        function runOne(index) {
            if (index >= scripts.length) return Promise.resolve();
            var oldScript = scripts[index];
            var newScript = document.createElement("script");
            for (var i = 0; i < oldScript.attributes.length; i++) {
                var attr = oldScript.attributes[i];
                newScript.setAttribute(attr.name, attr.value);
            }

            var runNext = function () { return runOne(index + 1); };

            if (oldScript.src) {
                return new Promise(function (resolve) {
                    newScript.addEventListener("load", resolve);
                    newScript.addEventListener("error", resolve);
                    oldScript.parentNode.replaceChild(newScript, oldScript);
                }).then(runNext);
            } else {
                newScript.text = wrapInlineScript(oldScript.textContent);
                oldScript.parentNode.replaceChild(newScript, oldScript);
                return runNext();
            }
        }

        return runOne(0);
    }

    function refreshActiveLinks(pathname) {
        document.querySelectorAll(".jc-navbar-link, .jc-sidebar-link, .sidebar-item").forEach(function (a) {
            var href = a.getAttribute("href");
            if (!href || href.charAt(0) === "#") return;
            var hrefPath;
            try {
                hrefPath = new URL(href, window.location.origin).pathname;
            } catch (e) {
                return;
            }
            var active;
            if (hrefPath === "/") {
                active = pathname === "/";
            } else {
                active = pathname.toLowerCase().indexOf(hrefPath.toLowerCase()) === 0;
            }
            a.classList.toggle("active", active);
        });
    }

    function updateDashboardTitle(newTitleTag) {
        var el = document.getElementById("jcPageTitle");
        if (!el || !newTitleTag) return;
        var raw = newTitleTag.trim();
        var mainPart = raw.split(" – ")[0].split(" - ")[0];
        if (mainPart) el.textContent = mainPart;
    }

    function closeTransientUi() {
        var userDropdown = document.getElementById("jcUserDropdown");
        if (userDropdown) userDropdown.classList.remove("open");
        var notifDropdown = document.getElementById("jcNotifDropdown");
        if (notifDropdown) notifDropdown.classList.remove("open");
    }

    // ---------- Điều hướng chính ----------
    function navigate(url, addToHistory, scrollTop) {
        if (typeof addToHistory === "undefined") addToHistory = true;
        if (typeof scrollTop === "undefined") scrollTop = true;

        var container = document.querySelector(CONTENT_SELECTOR);
        if (!container) {
            window.location.href = url;
            return;
        }

        if (currentController) currentController.abort();
        var controller = ("AbortController" in window) ? new AbortController() : null;
        currentController = controller;

        startProgress();
        closeTransientUi();
        container.classList.add("jc-fade-out");

        fetch(url, {
            headers: { "X-Requested-With": "XMLHttpRequest", "X-Jc-Ajax-Nav": "1" },
            credentials: "same-origin",
            signal: controller ? controller.signal : undefined
        }).then(function (res) {
            var finalUrl = res.url || url;
            if (!res.ok && res.status !== 404) {
                // Lỗi server (500...) -> tải lại kiểu truyền thống cho chắc chắn
                window.location.href = url;
                throw new Error("navigation-fallback");
            }
            return res.text().then(function (html) {
                return { html: html, finalUrl: finalUrl, status: res.status };
            });
        }).then(function (result) {
            var parser = new DOMParser();
            var newDoc = parser.parseFromString(result.html, "text/html");
            var newContent = newDoc.querySelector(CONTENT_SELECTOR);

            if (!newContent) {
                // Trang đích không dùng cùng layout (vd. trang lỗi, trang đăng nhập
                // khác kiểu bố cục) -> chuyển trang bình thường để đảm bảo đúng.
                window.location.href = result.finalUrl;
                return;
            }

            // Trang đích thuộc 1 "họ" layout KHÁC (vd. Public -> Nhà tuyển dụng/Admin/
            // Nhân viên) dù vẫn có [data-jc-content] -> phải tải lại toàn trang, nếu
            // không sẽ bị dính nhầm header/sidebar/CSS của layout cũ (bug đã gặp).
            var currentLayout = document.body.getAttribute("data-jc-layout");
            var newLayout = newDoc.body ? newDoc.body.getAttribute("data-jc-layout") : null;
            if (currentLayout !== newLayout) {
                window.location.href = result.finalUrl;
                return;
            }

            var doSwap = function () {
                document.title = newDoc.title;
                updateDashboardTitle(newDoc.title);
                container.innerHTML = newContent.innerHTML;

                // [FIX] Trang nào cũng có thể khai báo @section Scripts — nhưng layout
                // render section này ở CUỐI <body>, NẰM NGOÀI [data-jc-content]. Trước đây
                // điều hướng AJAX chỉ swap/thực thi lại script bên trong content container,
                // nên toàn bộ script riêng của từng trang (vẽ biểu đồ Chart.js, khởi tạo
                // Quill, gắn sự kiện form...) không bao giờ chạy lại khi vào trang bằng
                // link — chỉ đúng khi F5 tải lại toàn bộ trang. Giờ lấy thêm phần
                // #jc-page-scripts từ trang mới tải về, swap và thực thi lại luôn.
                var oldScriptsContainer = document.getElementById(SCRIPTS_CONTAINER_ID);
                var newScriptsContainer = newDoc.getElementById(SCRIPTS_CONTAINER_ID);
                if (oldScriptsContainer && newScriptsContainer) {
                    oldScriptsContainer.innerHTML = newScriptsContainer.innerHTML;
                }

                executeScripts(container).then(function () {
                    if (oldScriptsContainer) return executeScripts(oldScriptsContainer);
                });

                container.classList.remove("jc-fade-out");

                var newUrl = new URL(result.finalUrl, window.location.href);
                if (addToHistory) {
                    window.history.pushState({ jcAjax: true }, "", newUrl.pathname + newUrl.search + newUrl.hash);
                } else {
                    window.history.replaceState({ jcAjax: true }, "", newUrl.pathname + newUrl.search + newUrl.hash);
                }
                refreshActiveLinks(newUrl.pathname);

                if (scrollTop) window.scrollTo({ top: 0, left: 0, behavior: "auto" });

                document.dispatchEvent(new CustomEvent("jc:navigated", { detail: { url: newUrl.href } }));
                finishProgress(true);
            };

            // Chờ hiệu ứng mờ ra hoàn tất rồi mới thay nội dung, cho mượt mà
            setTimeout(doSwap, 120);
        }).catch(function (err) {
            if (err && err.name === "AbortError") return;
            if (err && err.message === "navigation-fallback") return;
            // Lỗi mạng khác -> fallback sang điều hướng thường
            window.location.href = url;
        });
    }

    // ---------- Bắt sự kiện click toàn site ----------
    document.addEventListener("click", function (e) {
        var anchor = e.target.closest ? e.target.closest("a[href]") : null;
        if (!shouldIntercept(anchor, e)) return;
        e.preventDefault();
        navigate(anchor.href, true, true);
    }, true);

    // ---------- Back / Forward ----------
    window.addEventListener("popstate", function () {
        navigate(window.location.href, false, false);
    });

    // Đảm bảo lần load đầu tiên có state hợp lệ để back hoạt động đúng
    if (!window.history.state || !window.history.state.jcAjax) {
        window.history.replaceState({ jcAjax: true }, "", window.location.href);
    }

    // API cho các trang muốn tự điều hướng bằng JS (vd. sau khi submit form)
    window.jcNavigate = navigate;
})();
