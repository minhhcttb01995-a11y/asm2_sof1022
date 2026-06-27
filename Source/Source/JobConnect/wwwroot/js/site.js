// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

/* ============================================================
   JobConnect – site.js
   Các tiện ích JavaScript dùng chung toàn trang
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {

    /* ----------------------------------------------------------
       1. TỰ ẨN FLASH MESSAGES sau 4 giây
       ---------------------------------------------------------- */
    const flashes = document.querySelectorAll('[data-flash]');
    flashes.forEach(el => {
        setTimeout(() => {
            el.style.transition = 'opacity 0.5s ease, max-height 0.5s ease';
            el.style.opacity = '0';
            el.style.maxHeight = '0';
            el.style.overflow = 'hidden';
            el.style.paddingTop = '0';
            el.style.paddingBottom = '0';
            setTimeout(() => el.remove(), 500);
        }, 4000);
    });

    /* Áp dụng cho flash hiện tại (dùng class thay vì data-attribute) */
    document.querySelectorAll('.bg-green-50, .bg-red-50').forEach(el => {
        if (el.tagName === 'DIV' && el.closest('body') === document.body) {
            setTimeout(() => {
                el.style.transition = 'opacity 0.5s ease, padding 0.5s ease';
                el.style.opacity = '0';
                el.style.paddingTop = '0';
                el.style.paddingBottom = '0';
                setTimeout(() => el.remove(), 500);
            }, 4000);
        }
    });

    /* ----------------------------------------------------------
       2. XÁC NHẬN trước khi thực hiện hành động nguy hiểm
          Thêm data-confirm="Nội dung xác nhận" vào button/form
       ---------------------------------------------------------- */
    document.querySelectorAll('[data-confirm]').forEach(el => {
        el.addEventListener('click', e => {
            const msg = el.dataset.confirm || 'Bạn có chắc chắn muốn thực hiện hành động này?';
            if (!confirm(msg)) e.preventDefault();
        });
    });

    /* ----------------------------------------------------------
       3. MOBILE MENU toggle
          Thêm id="mobileMenuBtn" vào nút hamburger
          Thêm id="mobileMenu"    vào nav mobile
       ---------------------------------------------------------- */
    const menuBtn = document.getElementById('mobileMenuBtn');
    const mobileMenu = document.getElementById('mobileMenu');
    if (menuBtn && mobileMenu) {
        menuBtn.addEventListener('click', () => {
            const isHidden = mobileMenu.classList.contains('hidden');
            mobileMenu.classList.toggle('hidden', !isHidden);
            menuBtn.setAttribute('aria-expanded', String(isHidden));
        });
        /* Đóng menu khi click ra ngoài */
        document.addEventListener('click', e => {
            if (!menuBtn.contains(e.target) && !mobileMenu.contains(e.target)) {
                mobileMenu.classList.add('hidden');
                menuBtn.setAttribute('aria-expanded', 'false');
            }
        });
    }

    /* ----------------------------------------------------------
       4. DROPDOWN USER (avatar menu)
          Thêm id="userMenuBtn" vào nút avatar
          Thêm id="userMenuDropdown" vào panel dropdown
       ---------------------------------------------------------- */
    const userBtn = document.getElementById('userMenuBtn');
    const userDrop = document.getElementById('userMenuDropdown');
    if (userBtn && userDrop) {
        userBtn.addEventListener('click', e => {
            e.stopPropagation();
            userDrop.classList.toggle('hidden');
        });
        document.addEventListener('click', () => userDrop.classList.add('hidden'));
    }

    /* ----------------------------------------------------------
       5. SMOOTH SCROLL cho anchor links nội trang
       ---------------------------------------------------------- */
    document.querySelectorAll('a[href^="#"]').forEach(a => {
        a.addEventListener('click', e => {
            const target = document.querySelector(a.getAttribute('href'));
            if (target) {
                e.preventDefault();
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });

    /* ----------------------------------------------------------
       6. FORMAT SỐ tự động (VND)
          Áp dụng cho input[data-format="currency"]
       ---------------------------------------------------------- */
    document.querySelectorAll('input[data-format="currency"]').forEach(input => {
        input.addEventListener('blur', () => {
            const raw = input.value.replace(/\D/g, '');
            if (raw) input.setAttribute('data-raw', raw);
        });
    });

    /* ----------------------------------------------------------
       7. PREVIEW ảnh trước khi upload
          Thêm data-preview="imgId" vào input[type=file]
       ---------------------------------------------------------- */
    document.querySelectorAll('input[type="file"][data-preview]').forEach(input => {
        input.addEventListener('change', () => {
            const file = input.files?.[0];
            if (!file) return;
            const previewId = input.dataset.preview;
            const img = document.getElementById(previewId);
            if (img) {
                const reader = new FileReader();
                reader.onload = e => { img.src = e.target.result; };
                reader.readAsDataURL(file);
            }
        });
    });

    /* ----------------------------------------------------------
       8. COPY TO CLIPBOARD
          Thêm data-copy="text" vào button
       ---------------------------------------------------------- */
    document.querySelectorAll('[data-copy]').forEach(btn => {
        btn.addEventListener('click', async () => {
            try {
                await navigator.clipboard.writeText(btn.dataset.copy);
                const orig = btn.textContent;
                btn.textContent = 'Đã sao chép!';
                setTimeout(() => { btn.textContent = orig; }, 2000);
            } catch {
                /* fallback: không hỗ trợ clipboard API */
            }
        });
    });

    /* ----------------------------------------------------------
       9. BACK TO TOP button
          Tự động hiện khi scroll xuống > 300px
       ---------------------------------------------------------- */
    const backTop = document.getElementById('backToTop');
    if (backTop) {
        window.addEventListener('scroll', () => {
            backTop.classList.toggle('opacity-0', window.scrollY < 300);
            backTop.classList.toggle('pointer-events-none', window.scrollY < 300);
        });
        backTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
    }

    /* ----------------------------------------------------------
       10. INPUT CHARACTER COUNTER
           Thêm data-counter="maxLength" vào textarea/input
       ---------------------------------------------------------- */
    document.querySelectorAll('[data-counter]').forEach(input => {
        const max = parseInt(input.dataset.counter, 10);
        const counter = document.createElement('p');
        counter.className = 'text-xs text-secondary text-right mt-1';
        counter.textContent = `0 / ${max}`;
        input.insertAdjacentElement('afterend', counter);
        input.addEventListener('input', () => {
            const len = input.value.length;
            counter.textContent = `${len} / ${max}`;
            counter.className = `text-xs text-right mt-1 ${len > max ? 'text-error' : 'text-secondary'}`;
        });
    });

});

/* ============================================================
   HELPERS toàn cục
   ============================================================ */

/** Định dạng số tiền VND */
function formatVND(amount) {
    return new Intl.NumberFormat('vi-VN', {
        style: 'currency', currency: 'VND', maximumFractionDigits: 0
    }).format(amount);
}

/** Debounce – giới hạn tần suất gọi hàm */
function debounce(fn, delay = 300) {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), delay);
    };
}

/** Hiển thị toast notification tạm thời */
function showToast(message, type = 'success') {
    const colors = {
        success: 'bg-green-50 border-green-200 text-green-800',
        error: 'bg-red-50 border-red-200 text-red-800',
        info: 'bg-blue-50 border-blue-200 text-blue-800',
    };
    const toast = document.createElement('div');
    toast.className = `fixed bottom-6 right-6 z-[9999] px-5 py-3 rounded-xl border shadow-lg text-sm font-medium
                     transition-all duration-300 ${colors[type] ?? colors.info}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(10px)';
        setTimeout(() => toast.remove(), 300);
    }, 3500);
}